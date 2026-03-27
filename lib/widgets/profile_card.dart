import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../theme/app_colors.dart';
import 'user_avatar.dart';
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(user: liveUser, size: 56, showRing: true),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        liveUser.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: AppColors.text,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${liveUser.handle}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.text3,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _FollowButton(user: liveUser),
              ],
            ),
            const SizedBox(height: 16),
            if (liveUser.bio.isNotEmpty) ...[
              Text(
                liveUser.bio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14, 
                  color: AppColors.text2, 
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaPill(label: liveUser.role, color: AppColors.orange),
                if (liveUser.academicLabel.isNotEmpty)
                  _MetaPill(label: liveUser.academicLabel, color: AppColors.secondary),
                _MetaPill(label: '⚡ ${liveUser.aura}', color: AppColors.yellow),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bg3,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: AuraBar(aura: liveUser.aura),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11, 
          color: color, 
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: user.isFollowing ? Colors.transparent : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: user.isFollowing ? AppColors.border : AppColors.primary,
            width: 2,
          ),
        ),
        child: Text(
          isUpdating
              ? '...'
              : (user.isFollowing ? 'Following' : 'Follow'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: user.isFollowing ? AppColors.text2 : Colors.white,
          ),
        ),
      ),
    );
  }
}
