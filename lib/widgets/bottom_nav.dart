import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';

class DevSpaceBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadNotifications;
  final int unreadMessages;

  const DevSpaceBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadNotifications = 0,
    this.unreadMessages = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        border: Border(
          top: BorderSide(
            color: AppColors.borderFor(context).withValues(alpha: 0.8),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.house_outlined,
                activeIcon: Icons.house_rounded,
                label: 'Home',
                index: 0,
                current: currentIndex,
                onTap: onTap,
                badgeCount: unreadNotifications,
              ),
              _NavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                label: 'Explore',
                index: 1,
                current: currentIndex,
                onTap: onTap,
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onTap(2);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.emoji_events_outlined,
                activeIcon: Icons.emoji_events_rounded,
                label: 'Arena',
                index: 3,
                current: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.account_circle_outlined,
                activeIcon: Icons.account_circle_rounded,
                label: 'Profile',
                index: 4,
                current: currentIndex,
                onTap: onTap,
                badgeCount: unreadMessages,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;
  final int badgeCount;
  final String? imageAsset;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
    this.badgeCount = 0,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    final iconColor = active ? AppColors.primary : AppColors.text3For(context);
    final labelColor = active ? AppColors.primary : AppColors.text3For(context);

    return Expanded(
      child: InkWell(
        onTap: () {
          if (!active) {
            HapticFeedback.lightImpact();
          }
          onTap(index);
        },
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                backgroundColor: AppColors.primary,
                isLabelVisible: badgeCount > 0,
                label: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: imageAsset != null
                    ? Image.asset(
                        imageAsset!,
                        width: 24,
                        height: 24,
                        color: active ? null : AppColors.text3For(context),
                        colorBlendMode: active ? null : BlendMode.srcIn,
                      )
                    : Icon(
                        active ? activeIcon : icon,
                        size: 24,
                        color: iconColor,
                      ),
              ).animate(key: ValueKey(active), target: active ? 1 : 0)
               .scale(begin: const Offset(1, 1), end: const Offset(1.25, 1.25), duration: 200.ms, curve: Curves.easeOutBack)
               .then()
               .scale(begin: const Offset(1.25, 1.25), end: const Offset(1.15, 1.15), duration: 150.ms, curve: Curves.easeIn),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: labelColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
