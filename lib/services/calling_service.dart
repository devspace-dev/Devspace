import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

enum CallStatus { idle, ringing, inCall }

class CallingService {
  CallingService._internal();
  static final CallingService instance = CallingService._internal();

  RealtimeChannel? _channel;
  String? _currentUserId;
  
  final _callEventsController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get callEvents => _callEventsController.stream;

  void init(String userId) {
    if (_currentUserId == userId && _channel != null) return;
    
    _currentUserId = userId;
    _channel = Supabase.instance.client.channel('calling:$userId');

    _channel!.onBroadcast(
      event: 'call_offer',
      callback: (payload) {
        _callEventsController.add({
          'type': 'offer',
          'data': payload,
        });
      },
    ).onBroadcast(
      event: 'call_answer',
      callback: (payload) {
        _callEventsController.add({
          'type': 'answer',
          'data': payload,
        });
      },
    ).onBroadcast(
      event: 'call_hangup',
      callback: (payload) {
        _callEventsController.add({
          'type': 'hangup',
          'data': payload,
        });
      },
    ).subscribe();
  }

  void dispose() {
    _channel?.unsubscribe();
    _currentUserId = null;
  }

  Future<void> sendCallOffer({
    required String toUserId,
    required String fromUserId,
    required String channelId,
    required bool isVideo,
    required Map<String, dynamic> callerData,
  }) async {
    final channel = Supabase.instance.client.channel('calling:$toUserId');
    
    Completer<void> completer = Completer<void>();
    
    channel.subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        try {
          await channel.sendBroadcastMessage(
            event: 'call_offer',
            payload: {
              'from': fromUserId,
              'channelId': channelId,
              'isVideo': isVideo,
              'callerData': callerData,
            },
          );
          completer.complete();
        } catch (e) {
          completer.completeError(e);
        }
      } else if (error != null) {
        completer.completeError(error);
      }
    });

    return completer.future;
  }

  Future<void> sendCallAnswer({
    required String toUserId,
    required bool accepted,
  }) async {
    final channel = Supabase.instance.client.channel('calling:$toUserId');
    
    Completer<void> completer = Completer<void>();

    channel.subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        try {
          await channel.sendBroadcastMessage(
            event: 'call_answer',
            payload: {
              'accepted': accepted,
              'from': _currentUserId,
            },
          );
          completer.complete();
        } catch (e) {
          completer.completeError(e);
        }
      } else if (error != null) {
        completer.completeError(error);
      }
    });

    return completer.future;
  }

  Future<void> sendHangup(String toUserId) async {
    final channel = Supabase.instance.client.channel('calling:$toUserId');
    channel.subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await channel.sendBroadcastMessage(
          event: 'call_hangup',
          payload: {
            'from': _currentUserId,
          },
        );
      }
    });
  }
}
