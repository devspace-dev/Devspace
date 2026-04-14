import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'skeleton_loaders.dart';

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
    final isPremium = user.aura >= 500; // Flame tier and above
    final borderColor = showStory ? badge.color : AppColors.borderFor(context);
    final borderWidth = (showStory || showRing) ? (isPremium ? 2.5 : 1.5) : 0.0;

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bg3For(context),
        boxShadow: isPremium && (showStory || showRing)
            ? [
                BoxShadow(
                  color: badge.color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipOval(
              child: user.isImageAvatar
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
                            fontWeight: FontWeight.w800,
                            color: user.color,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          if (user.isFounder)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_rounded,
                  size: size * 0.3,
                  color: Colors.black,
                ),
              ),
            ),
        ],
      ),
    );

    if (borderWidth > 0) {
      avatar = Container(
        padding: EdgeInsets.all(isPremium ? 2.5 : 1.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: avatar,
      );
    }

    if (isPremium && (showStory || showRing)) {
      return avatar
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(
            duration: 2000.ms,
            color: badge.color.withValues(alpha: 0.2),
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
    return CachedNetworkImage(
      imageUrl: StorageService.instance.resolvePublicUrl(avatar),
      fit: BoxFit.cover,
      width: size,
      height: size,
      placeholder: (context, url) => SkeletonLoader(width: size, height: size, borderRadius: size / 2),
      errorWidget: (_, __, ___) => _fallback(),
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
