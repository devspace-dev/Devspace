import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/users_provider.dart';
import '../screens/chat_detail_screen.dart';
import '../theme/app_colors.dart';
import 'aura_bar.dart';
import 'user_avatar.dart';

class ProfileCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const ProfileCard({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final usersP = context.watch<UsersProvider>();
    final liveUser = usersP.getUserById(user.id) ?? user;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.borderFor(context),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(user: liveUser, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              liveUser.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.textFor(context),
                              ),
                            ),
                            Text(
                              '@${liveUser.handle} • ${liveUser.role}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.text3For(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _MessageButton(user: liveUser),
                      const SizedBox(width: 8),
                      _FollowButton(user: liveUser),
                    ],
                  ),
                  if (liveUser.bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      liveUser.bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.text2For(context),
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  AuraBar(aura: liveUser.aura),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageButton extends StatelessWidget {
  final UserModel user;

  const _MessageButton({required this.user});

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().currentUserOrNull;
    if (me == null || me.id == user.id) return const SizedBox.shrink();

    return IconButton(
      onPressed: () async {
        final provider = context.read<MessagesProvider>();
        try {
          final conv = await provider.startConversation(me.id, user.id);
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ChatDetailScreen(conversation: conv, otherUser: user),
            ),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      },
      icon: const Icon(Icons.mail_outline_rounded, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.bg2For(context),
        padding: EdgeInsets.zero,
        minimumSize: const Size(32, 32),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final UserModel user;

  const _FollowButton({required this.user});

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().currentUser;
    if (me.id == user.id) return const SizedBox.shrink();

    final isFollowing = user.isFollowing;

    return ElevatedButton(
      onPressed: () => context.read<UsersProvider>().toggleFollow(me.id, user.id),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isFollowing ? AppColors.bg2For(context) : AppColors.textFor(context),
        foregroundColor:
            isFollowing ? AppColors.textFor(context) : AppColors.bgFor(context),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(0, 32),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        isFollowing ? 'Following' : 'Follow',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}
