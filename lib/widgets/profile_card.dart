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
  final Widget? trailing;

  const ProfileCard({super.key, required this.user, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final usersP = context.watch<UsersProvider>();
    final liveUser = usersP.getUserById(user.id) ?? user;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.borderFor(context).withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            UserAvatar(user: liveUser, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          liveUser.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textFor(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _AuraBadge(aura: liveUser.aura),
                    ],
                  ),
                  Text(
                    '@${liveUser.handle} • ${liveUser.role}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text3For(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else ...[
              const SizedBox(width: 8),
              _MessageButton(user: liveUser),
              const SizedBox(width: 4),
              _FollowButton(user: liveUser),
            ],
          ],
        ),
      ),
    );
  }
}

class _AuraBadge extends StatelessWidget {
  final int aura;
  const _AuraBadge({required this.aura});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${aura}A',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 28),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        isFollowing ? 'Following' : 'Follow',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
