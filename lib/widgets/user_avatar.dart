import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/badge_model.dart';
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
    final borderColor = showStory ? badge.color : (showRing ? user.color : user.color.withOpacity(0.3));
    final borderWidth = showStory ? 2.5 : (showRing ? 2.0 : 1.5);

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: user.color.withOpacity(0.15),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Center(
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
          border: Border.all(color: badge.color.withOpacity(0.5), width: 2.5),
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
