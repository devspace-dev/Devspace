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
    final borderColor = showStory ? badge.color : AppColors.border;
    final borderWidth = (showStory || showRing) ? 1.5 : 0.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bg3,
        border: borderWidth > 0 ? Border.all(color: borderColor, width: borderWidth) : null,
      ),
      child: ClipOval(
        child: user.hasImageAvatar
            ? _AvatarImage(
                avatar: user.avatar,
                size: size,
                color: user.color,
              )
            : Container(
                color: user.color.withValues(alpha: 0.1),
                child: Center(
                  child: Text(
                    user.avatar,
                    style: TextStyle(
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.w600,
                      color: user.color,
                    ),
                  ),
                ),
              ),
      ),
    );
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
        size: size * 0.5,
      ),
    );
  }
}
