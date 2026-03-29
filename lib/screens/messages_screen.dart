import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/messages_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';
import '../widgets/user_avatar.dart';
import 'chat_detail_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: Consumer<MessagesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (provider.error != null && provider.conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 60,
                      color: AppColors.text3For(context),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.text2For(context)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.init(me.id, force: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.message_outlined,
                      size: 64, color: AppColors.text3For(context)),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text2For(context),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (provider.error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    provider.error!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text2For(context),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  itemCount: provider.conversations.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    indent: 72,
                    color: AppColors.borderFor(context),
                  ),
                  itemBuilder: (context, index) {
                    final conv = provider.conversations[index];
                    final otherId = conv.participants
                        .where((id) => id != me.id)
                        .cast<String?>()
                        .firstWhere((id) => id != null, orElse: () => null);

                    if (otherId == null) {
                      return const SizedBox.shrink();
                    }

                    return FutureBuilder<UserModel?>(
                      future: context.read<UsersProvider>().getUser(otherId),
                      builder: (context, snap) {
                        final other = snap.data;
                        if (other == null) {
                          return ListTile(
                            title: Text(
                              'Conversation unavailable',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textFor(context),
                              ),
                            ),
                            subtitle: Text(
                              'This member could not be loaded right now.',
                              style: TextStyle(
                                color: AppColors.text3For(context),
                              ),
                            ),
                          );
                        }

                        final hasUnread = conv.unreadCount > 0;
                        return ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailScreen(
                                  conversation: conv,
                                  otherUser: other,
                                ),
                              ),
                            );
                          },
                          leading: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              UserAvatar(user: other, size: 48),
                              if (hasUnread)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${conv.unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            other.name,
                            style: TextStyle(
                              fontWeight:
                                  hasUnread ? FontWeight.w800 : FontWeight.w700,
                              color: AppColors.textFor(context),
                            ),
                          ),
                          subtitle: Text(
                            conv.lastMessage ?? 'Start a conversation',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: hasUnread
                                  ? AppColors.textFor(context)
                                  : AppColors.text3For(context),
                              fontWeight:
                                  hasUnread ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          trailing: conv.lastMessageAt != null
                              ? Text(
                                  _formatTime(conv.lastMessageAt!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hasUnread
                                        ? AppColors.primary
                                        : AppColors.text3For(context),
                                    fontWeight: hasUnread
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
