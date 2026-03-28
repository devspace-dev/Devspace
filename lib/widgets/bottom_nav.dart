import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';

class DevSpaceBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const DevSpaceBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassContainer(
            color: AppColors.bg2,
            opacity: 0.8,
            blur: 25.0,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 0.5),
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.house_rounded,
                    activeIcon: Icons.house_rounded,
                    label: 'Home',
                    index: 0,
                    current: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.person_search_rounded,
                    activeIcon: Icons.person_search_rounded,
                    label: 'Devs',
                    index: 1,
                    current: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.bubble_chart_rounded,
                    activeIcon: Icons.bubble_chart_rounded,
                    label: 'Q&A',
                    index: 2,
                    current: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.rocket_launch_rounded,
                    activeIcon: Icons.rocket_launch_rounded,
                    label: 'Opps',
                    index: 3,
                    current: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.account_circle_rounded,
                    activeIcon: Icons.account_circle_rounded,
                    label: 'Me',
                    index: 4,
                    current: currentIndex,
                    onTap: onTap,
                  ),
                ],
              ),
            ),
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

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    final color = active ? AppColors.primary : AppColors.text3;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!active) HapticFeedback.selectionClick();
          onTap(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
