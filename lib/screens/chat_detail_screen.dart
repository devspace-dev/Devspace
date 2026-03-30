import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/messages_provider.dart';
import '../providers/auth_provider.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';
import '../widgets/user_avatar.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final me = context.read<AuthProvider>().currentUser;
      context
          .read<MessagesProvider>()
          .markConversationRead(widget.conversation.id, me.id);
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final me = context.read<AuthProvider>().currentUser;
    final provider = context.read<MessagesProvider>();
    provider.clearConversationError(widget.conversation.id);
    final success = await provider.send(
      widget.conversation.id,
      me.id,
      text,
    );
    if (!mounted) return;

    if (success) {
      _controller.clear();
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

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().currentUser;
    final provider = context.watch<MessagesProvider>();
    final isSending = provider.isSending(widget.conversation.id);

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(user: widget.otherUser, size: 36),
            const SizedBox(width: 12),
            Text(widget.otherUser.name),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: context.read<MessagesProvider>().messagesStream(widget.conversation.id),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Failed to load messages: ${snap.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.text2For(context)),
                      ),
                    ),
                  );
                }

                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator.adaptive());
                }

                final messages = snap.data!;
                _maybeMarkMessagesRead(messages, me.id);
                _scrollToBottom();
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Say hi!',
                      style: TextStyle(color: AppColors.text3For(context)),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == me.id;

                    return _MessageBubble(message: msg, isMe: isMe);
                  },
                );
              },
              ),
            ),
          _buildInput(isSending),
        ],
      ),
    );
  }

  Widget _buildInput(bool isSending) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        border: Border(top: BorderSide(color: AppColors.borderFor(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !isSending,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          if (isSending)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send_rounded, color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.bg3For(context),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 18),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : AppColors.textFor(context),
          ),
        ),
      ),
    );
  }
}
