import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../models/badge_model.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final UserModel user;
  final double size;
  final bool showRing;
  final bool showStory;

  const UserAvatar({
    super.key,
    required this.user,
    this.size = 44,
    this.showRing = false,
    this.showStory = false,
  });

  @override
  Widget build(BuildContext context) {
    final badge = getBadge(user.aura);
    final borderColor = showStory
        ? badge.color
        : (showRing ? AppColors.border2 : AppColors.border);
    final borderWidth = showStory ? 2.0 : 1.0;

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bg3,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: user.hasImageAvatar
          ? ClipOval(
              child: _AvatarImage(
                avatar: user.avatar,
                size: size,
                color: user.color,
              ),
            )
          : Center(
              child: Text(
                user.avatar,
                style: TextStyle(
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.w700,
                  color: user.color,
                  letterSpacing: -0.2,
                ),
              ),
            ),
    );

    if (showStory) {
      return Container(
        width: size + 8,
        height: size + 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: badge.color.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bg,
            ),
            child: avatar,
          ),
        ),
      );
    }

    return avatar;
  }
}

class _AvatarImage extends StatelessWidget {
  final String avatar;
  final double size;
  final Color color;

  const _AvatarImage({
    required this.avatar,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      StorageService.instance.resolvePublicUrl(avatar),
      fit: BoxFit.cover,
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      color: color.withValues(alpha: 0.1),
      child: Icon(
        Icons.person_rounded,
        color: color,
        size: size * 0.46,
      ),
    );
  }
}
