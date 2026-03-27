import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../theme/app_colors.dart';
import 'user_avatar.dart';
import 'aura_pill.dart';
import 'aura_bar.dart';

class ProfileCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const ProfileCard({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final usersP   = context.watch<UsersProvider>();
    final liveUser = usersP.getUserById(user.id) ?? user;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(user: liveUser, size: 48, showStory: false),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    liveUser.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppColors.text,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AuraPill(aura: liveUser.aura, small: true),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${liveUser.handle} · ${liveUser.academicLabel.isEmpty ? liveUser.role : liveUser.academicLabel}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.text3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FollowButton(user: liveUser),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(liveUser.bio,
                      style: const TextStyle(fontSize: 13, color: AppColors.text2, height: 1.4)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(liveUser.building,
                            style: const TextStyle(
                              fontSize: 11, color: AppColors.text4),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: liveUser.stack.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bg3,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.border,
                        ),
                      ),
                      child: Text(s,
                          style: const TextStyle(
                            fontSize: 11, color: AppColors.text2, fontWeight: FontWeight.w600)),
                    )).toList(),
                  ),
                  const SizedBox(height: 14),
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

class _FollowButton extends StatelessWidget {
  final UserModel user;
  const _FollowButton({required this.user});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().currentUser.id;
    final usersProvider = context.watch<UsersProvider>();
    final isUpdating = usersProvider.isFollowUpdating(user.id);
    final isCurrentUser = currentUserId == user.id;

    if (isCurrentUser) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: isUpdating
          ? null
          : () async {
              await context
                  .read<UsersProvider>()
                  .toggleFollow(currentUserId, user.id);
              if (!context.mounted) return;

              final error =
                  context.read<UsersProvider>().followError(user.id);
              if (error == null) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error)),
              );
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: user.isFollowing ? Colors.transparent : AppColors.primary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: user.isFollowing ? AppColors.border : AppColors.primary,
          ),
        ),
        child: Text(
          isUpdating
              ? '...'
              : (user.isFollowing ? 'Following' : 'Follow'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: user.isFollowing ? AppColors.text2 : Colors.white,
          ),
        ),
      ),
    );
  }
}
