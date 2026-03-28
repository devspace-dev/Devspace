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
          if (provider.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.message_outlined, size: 64, color: AppColors.text3For(context)),
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

          return ListView.separated(
            itemCount: provider.conversations.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 72,
              color: AppColors.borderFor(context),
            ),
            itemBuilder: (context, index) {
              final conv = provider.conversations[index];
              final otherId = conv.participants.firstWhere((id) => id != me.id);
              
              return FutureBuilder<UserModel?>(
                future: context.read<UsersProvider>().getUser(otherId),
                builder: (context, snap) {
                  final other = snap.data;
                  if (other == null) return const SizedBox.shrink();

                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(conversation: conv, otherUser: other),
                        ),
                      );
                    },
                    leading: UserAvatar(user: other, size: 48),
                    title: Text(
                      other.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textFor(context),
                      ),
                    ),
                    subtitle: Text(
                      conv.lastMessage ?? 'Start a conversation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.text3For(context),
                      ),
                    ),
                    trailing: conv.lastMessageAt != null 
                      ? Text(
                          _formatTime(conv.lastMessageAt!),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.text3For(context),
                          ),
                        )
                      : null,
                  );
                },
              );
            },
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
