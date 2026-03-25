import 'package:flutter/material.dart';
import 'dart:convert';

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
        : (showRing ? user.color : user.color.withValues(alpha: 0.3));
    final borderWidth = showStory ? 2.5 : (showRing ? 2.0 : 1.5);

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: user.color.withValues(alpha: 0.15),
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
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w900,
                  color: user.color,
                  letterSpacing: -0.5,
                ),
              ),
            ),
    );

    if (showStory) {
      return Container(
        width: size + 10,
        height: size + 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: badge.color.withValues(alpha: 0.5),
            width: 2.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.5),
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
    if (avatar.startsWith('http')) {
      return Image.network(
        avatar,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return FutureBuilder<String?>(
      future: StorageService.instance.getImageBase64(avatar),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            base64Decode(snapshot.data!),
            fit: BoxFit.cover,
            width: size,
            height: size,
          );
        }
        return _fallback();
      },
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      color: color.withValues(alpha: 0.18),
      child: Icon(
        Icons.person_rounded,
        color: color,
        size: size * 0.46,
      ),
    );
  }
}
