import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../providers/messages_provider.dart';
import '../providers/auth_provider.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';
import '../widgets/user_avatar.dart';
import '../services/storage_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'profile_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final ConversationModel conversation;
  final UserModel otherUser;

  const ChatDetailScreen({
    super.key,
    required this.conversation,
    required this.otherUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _lastMarkedIncomingMessageId;

  late final RealtimeChannel _channel;
  bool _isOtherUserTyping = false;
  Timer? _typingTimer;
  bool _iAmTyping = false;

  @override
  void initState() {
    super.initState();
    _initPresence();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final me = context.read<AuthProvider>().currentUser;
      context
          .read<MessagesProvider>()
          .markConversationRead(widget.conversation.id, me.id);
    });
  }

  void _initPresence() {
    final me = context.read<AuthProvider>().currentUser;
    _channel =
        Supabase.instance.client.channel('chat:${widget.conversation.id}');

    _channel.onPresenceSync((payload) {
      final states = _channel.presenceState();
      bool typing = false;

      for (final state in states) {
        for (final presence in state.presences) {
          final p = presence.payload;
          if (p['user_id'] == widget.otherUser.id && p['is_typing'] == true) {
            typing = true;
            break;
          }
        }
        if (typing) break;
      }

      if (mounted) {
        setState(() => _isOtherUserTyping = typing);
      }
    }).subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _channel.track({'user_id': me.id, 'is_typing': false});
      }
    });
  }

  void _onTextChanged(String value) {
    if (!_iAmTyping && value.isNotEmpty) {
      _setTyping(true);
    } else if (_iAmTyping && value.isEmpty) {
      _setTyping(false);
    }

    _typingTimer?.cancel();
    if (value.isNotEmpty) {
      _typingTimer = Timer(const Duration(seconds: 2), () => _setTyping(false));
    }
  }

  void _setTyping(bool typing) {
    if (_iAmTyping == typing) return;
    _iAmTyping = typing;
    final me = context.read<AuthProvider>().currentUser;
    _channel.track({'user_id': me.id, 'is_typing': typing});
  }

  @override
  void dispose() {
    _setTyping(false);
    _channel.unsubscribe();
    _typingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final me = context.read<AuthProvider>().currentUser;
    final provider = context.read<MessagesProvider>();
    provider.clearConversationError(widget.conversation.id);

    _setTyping(false);
    _controller.clear();

    final success = await provider.send(
      widget.conversation.id,
      me.id,
      text,
    );
    if (!mounted) return;

    if (success) {
      _scrollToBottom();
      return;
    }

    final error = provider.sendError(widget.conversation.id);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _maybeMarkMessagesRead(
    List<MessageModel> messages,
    String currentUserId,
  ) {
    String? latestUnreadIncomingMessageId;
    for (final message in messages.reversed) {
      if (message.senderId != currentUserId && !message.isRead) {
        latestUnreadIncomingMessageId = message.id;
        break;
      }
    }

    if (latestUnreadIncomingMessageId == null ||
        latestUnreadIncomingMessageId == _lastMarkedIncomingMessageId) {
      return;
    }

    _lastMarkedIncomingMessageId = latestUnreadIncomingMessageId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<MessagesProvider>()
          .markConversationRead(widget.conversation.id, currentUserId);
    });
  }



  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.bg2For(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OptionItem(
              icon: Icons.image_rounded,
              label: 'Gallery',
              color: Colors.purple,
              onTap: () async {
                Navigator.pop(context);
                final file =
                    await StorageService.instance.pickImage(fromCamera: false);
                if (!mounted) return;
                if (file != null) {
                  final me = context.read<AuthProvider>().currentUser;
                  final provider = context.read<MessagesProvider>();
                  provider.clearConversationError(widget.conversation.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Uploading image...')));
                  try {
                    final url = await StorageService.instance
                        .uploadChatImage(widget.conversation.id, file);
                    final success = await provider.send(
                        widget.conversation.id, me.id, '[IMAGE]$url');
                    if (!success && mounted) {
                      final error = provider.sendError(widget.conversation.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error ?? 'Failed to send image.')));
                    }
                  } catch (e) {
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to send image: $e')));
                  }
                }
              },
            ),
            _OptionItem(
              icon: Icons.camera_alt_rounded,
              label: 'Camera',
              color: Colors.red,
              onTap: () async {
                Navigator.pop(context);
                final file =
                    await StorageService.instance.pickImage(fromCamera: true);
                if (!mounted) return;
                if (file != null) {
                  final me = context.read<AuthProvider>().currentUser;
                  final provider = context.read<MessagesProvider>();
                  provider.clearConversationError(widget.conversation.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Uploading image...')));
                  try {
                    final url = await StorageService.instance
                        .uploadChatImage(widget.conversation.id, file);
                    final success = await provider.send(
                        widget.conversation.id, me.id, '[IMAGE]$url');
                    if (!success && mounted) {
                      final error = provider.sendError(widget.conversation.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error ?? 'Failed to send image.')));
                    }
                  } catch (e) {
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to send image: $e')));
                  }
                }
              },
            ),
            _OptionItem(
              icon: Icons.description_rounded,
              label: 'Document',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Document sending not available yet.')));
              },
            ),
            _OptionItem(
              icon: Icons.location_on_rounded,
              label: 'Location',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Location sending not available yet.')));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        backgroundColor: AppColors.bgFor(context),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textFor(context), size: 20),
        ),
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(userId: widget.otherUser.id),
                ),
              ),
              child: UserAvatar(user: widget.otherUser, size: 38),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(userId: widget.otherUser.id),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUser.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textFor(context),
                      ),
                    ),
                    if (_isOtherUserTyping)
                      Text(
                        'typing...',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Text(
                        'Active now',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.text3For(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: const [SizedBox(width: 4)],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: context
                  .read<MessagesProvider>()
                  .messagesStream(widget.conversation.id),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _buildError(context, snap.error.toString());
                }

                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator.adaptive());
                }

                final messages = snap.data!;
                _maybeMarkMessagesRead(messages, me.id);
                _scrollToBottom();

                if (messages.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Latest messages at the bottom
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == me.id;

                    // Grouping logic
                    final bool showDateHeader = index == 0 ||
                        messages[index].createdAt.day !=
                            messages[index - 1].createdAt.day;

                    return Column(
                      children: [
                        if (showDateHeader) _buildDateHeader(msg.createdAt),
                        _MessageBubble(
                          message: msg,
                          isMe: isMe,
                          otherUser: widget.otherUser,
                        )
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.1, end: 0),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (_isOtherUserTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: const _TypingIndicator().animate().fadeIn(),
            ),
          _buildInput(context),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.bg3For(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDateHeader(date),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.text3For(context),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateHeader(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year)
      return 'Today';
    if (dt.day == now.subtract(const Duration(days: 1)).day) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(dt);
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.text3For(context)),
            const SizedBox(height: 16),
            Text(
              'Failed to load messages',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textFor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.text3For(context),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {}); // Trigger rebuild to retry stream
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UserAvatar(user: widget.otherUser, size: 80),
          const SizedBox(height: 16),
          Text(
            widget.otherUser.name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textFor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your conversation with ${widget.otherUser.name.split(' ')[0]}',
            style: TextStyle(color: AppColors.text3For(context)),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _buildInput(BuildContext context) {
    final provider = context.watch<MessagesProvider>();
    final isSending = provider.isSending(widget.conversation.id);

    return Container(
      padding: EdgeInsets.fromLTRB(
          8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: AppColors.bgFor(context),
        border: Border(
            top: BorderSide(
                color: AppColors.borderFor(context).withValues(alpha: 0.5),
                width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: IconButton(
              onPressed: _showOptions,
              icon: Icon(Icons.add_circle_outline_rounded,
                  color: AppColors.primary, size: 28),
              splashRadius: 24,
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.bg2For(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: AppColors.borderFor(context).withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _controller,
                onChanged: _onTextChanged,
                enabled: !isSending,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, color: AppColors.textFor(context)),
                maxLines: 5,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(color: AppColors.text3For(context), fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: GestureDetector(
              onTap: isSending
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      _sendMessage();
                    },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.premiumGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _OptionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final UserModel otherUser;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.otherUser,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(message.createdAt);
    final isImage = message.content.startsWith('[IMAGE]');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(userId: otherUser.id),
                ),
              ),
              child: UserAvatar(user: otherUser, size: 28),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: isImage
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe ? AppColors.premiumGradient : null,
                color: isMe ? null : AppColors.bg2For(context),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isImage)
                    _buildImageContent(context)
                  else
                    Text(
                      message.content,
                      style: GoogleFonts.plusJakartaSans(
                        color: isMe ? Colors.white : AppColors.textFor(context),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? Colors.white.withOpacity(0.7)
                              : AppColors.text3For(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 14,
                          color: message.isRead
                              ? Colors.cyanAccent
                              : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    final imageUrl = message.content.substring(7);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        maxWidthDiskCache: 800,
        placeholder: (context, url) => Container(
          width: 200,
          height: 200,
          color: AppColors.bg3For(context),
          child: const Center(child: CircularProgressIndicator.adaptive()),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg3For(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.2;
              final value = (sin((_controller.value * 2 * pi) - delay) + 1) / 2;
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3 + (value * 0.7)),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
