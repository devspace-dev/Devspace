import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/user_model.dart';
import '../theme/app_colors.dart';
import '../utils/agora_config.dart';
import '../services/calling_service.dart';

class CallScreen extends StatefulWidget {
  final String channelId;
  final UserModel otherUser;
  final bool isVideo;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.channelId,
    required this.otherUser,
    required this.isVideo,
    this.isIncoming = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _muted = false;
  bool _switchCamera = false;
  bool _isConnecting = true;
  bool _isRinging = false;
  bool _hasAnswered = false;
  StreamSubscription? _callEventsSub;

  @override
  void initState() {
    super.initState();
    _isRinging = widget.isIncoming;
    _hasAnswered = !widget.isIncoming;
    
    if (!widget.isIncoming) {
      initAgora();
    }
    _listenToCallEvents();
  }

  void _listenToCallEvents() {
    _callEventsSub = CallingService.instance.callEvents.listen((event) {
      if (event['type'] == 'answer' && !widget.isIncoming) {
        if (event['data']['accepted'] == true) {
          setState(() {
            _hasAnswered = true;
          });
        } else {
          _endCall();
        }
      } else if (event['type'] == 'hangup') {
        _endCall();
      }
    });
  }

  Future<void> initAgora() async {
    // retrieve permissions
    await [Permission.microphone, Permission.camera].request();

    //create the engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: AgoraConfig.appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          if (mounted) {
            setState(() {
              _localUserJoined = true;
              _isConnecting = false;
            });
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          if (mounted) {
            setState(() {
              _remoteUid = remoteUid;
              _isRinging = false;
            });
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          if (mounted) {
            setState(() {
              _remoteUid = null;
            });
            _endCall();
          }
        },
      ),
    );

    if (widget.isVideo) {
      await _engine.enableVideo();
      await _engine.startPreview();
    } else {
      await _engine.disableVideo();
    }

    await _engine.joinChannel(
      token: '',
      channelId: widget.channelId,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  void _acceptCall() {
    setState(() {
      _isRinging = false;
      _hasAnswered = true;
    });
    CallingService.instance.sendCallAnswer(
      toUserId: widget.otherUser.id,
      accepted: true,
    );
    initAgora();
  }

  void _rejectCall() {
    CallingService.instance.sendCallAnswer(
      toUserId: widget.otherUser.id,
      accepted: false,
    );
    _endCall();
  }

  void _endCall() {
    CallingService.instance.sendHangup(widget.otherUser.id);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _callEventsSub?.cancel();
    _dispose();
    super.dispose();
  }

  Future<void> _dispose() async {
    try {
      await _engine.leaveChannel();
      await _engine.release();
    } catch (e) {
      debugPrint("Error disposing Agora: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _remoteVideo(),
          ),
          if (_localUserJoined && widget.isVideo && _hasAnswered)
            Positioned(
              right: 20,
              top: 60,
              child: SizedBox(
                width: 120,
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),
          _buildOverlay(),
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    if (_remoteUid != null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 100),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            backgroundImage: widget.otherUser.avatar.isNotEmpty &&
                    widget.otherUser.avatar.startsWith('http')
                ? NetworkImage(widget.otherUser.avatar)
                : null,
            child: widget.otherUser.avatar.isEmpty ||
                    !widget.otherUser.avatar.startsWith('http')
                ? Text(
                    widget.otherUser.name.isNotEmpty
                        ? widget.otherUser.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 40, color: Colors.white))
                : null,
          ),
          const SizedBox(height: 24),
          Text(
            widget.otherUser.name,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isRinging 
                ? (widget.isVideo ? 'Incoming Video Call...' : 'Incoming Voice Call...')
                : (_isConnecting ? 'Connecting...' : 'Calling...'),
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null && widget.isVideo) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelId),
        ),
      );
    } else if (_remoteUid != null && !widget.isVideo) {
      return Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              backgroundImage: widget.otherUser.avatar.isNotEmpty &&
                      widget.otherUser.avatar.startsWith('http')
                  ? NetworkImage(widget.otherUser.avatar)
                  : null,
              child: widget.otherUser.avatar.isEmpty ||
                      !widget.otherUser.avatar.startsWith('http')
                  ? Text(
                      widget.otherUser.name.isNotEmpty
                          ? widget.otherUser.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 60, color: Colors.white))
                  : null,
            ),
            const SizedBox(height: 32),
            Text(
              'On Voice Call',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(color: Colors.black);
    }
  }

  Widget _buildToolbar() {
    if (_isRinging) {
      return Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RawMaterialButton(
                  onPressed: _rejectCall,
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.redAccent,
                  padding: const EdgeInsets.all(15.0),
                  child: const Icon(Icons.call_end, color: Colors.white, size: 35.0),
                ),
                const SizedBox(height: 8),
                Text('Decline', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12)),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RawMaterialButton(
                  onPressed: _acceptCall,
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.greenAccent,
                  padding: const EdgeInsets.all(15.0),
                  child: const Icon(Icons.call, color: Colors.white, size: 35.0),
                ),
                const SizedBox(height: 8),
                Text('Accept', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12)),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: () {
              setState(() {
                _muted = !_muted;
              });
              _engine.muteLocalAudioStream(_muted);
            },
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: _muted ? AppColors.primary : Colors.white24,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              _muted ? Icons.mic_off : Icons.mic,
              color: Colors.white,
              size: 28.0,
            ),
          ),
          const SizedBox(width: 20),
          RawMaterialButton(
            onPressed: _endCall,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
          ),
          const SizedBox(width: 20),
          if (widget.isVideo)
            RawMaterialButton(
              onPressed: () {
                _engine.switchCamera();
                setState(() {
                  _switchCamera = !_switchCamera;
                });
              },
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.white24,
              padding: const EdgeInsets.all(12.0),
              child: const Icon(
                Icons.switch_camera,
                color: Colors.white,
                size: 28.0,
              ),
            ),
        ],
      ),
    );
  }
}
