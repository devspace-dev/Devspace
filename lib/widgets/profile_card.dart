import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
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
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(user: user, size: 50, showStory: true),
            const SizedBox(width: 12),
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
                                Text(user.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15, color: AppColors.text)),
                                const SizedBox(width: 6),
                                AuraPill(aura: user.aura, small: true),
                              ],
                            ),
                            Text('@${user.handle} · ${user.year}',
                                style: const TextStyle(
                                  fontSize: 12, color: AppColors.text3)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FollowButton(user: liveUser),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(user.bio,
                      style: const TextStyle(fontSize: 13, color: AppColors.text2)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('🛠 ', style: TextStyle(fontSize: 11)),
                      Expanded(
                        child: Text(user.building,
                            style: const TextStyle(
                              fontSize: 11, color: AppColors.text4),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: user.stack.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                      ),
                      child: Text(s,
                          style: const TextStyle(
                            fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    )).toList(),
                  ),
                  const SizedBox(height: 10),
                  AuraBar(aura: user.aura),
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
    return GestureDetector(
      onTap: () => context.read<UsersProvider>().toggleFollow(user.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: user.isFollowing
              ? Colors.transparent
              : AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: user.isFollowing
                ? AppColors.border2
                : AppColors.primary.withOpacity(0.4),
          ),
        ),
        child: Text(
          user.isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: user.isFollowing ? AppColors.text4 : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
