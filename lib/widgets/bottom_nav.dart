import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _NavItem(icon: Icons.home_rounded,
                  activeIcon: Icons.home_rounded,
                  label: 'Home', index: 0, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.people_outline_rounded,
                  activeIcon: Icons.people_rounded,
                  label: 'People', index: 1, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.help_outline_rounded,
                  activeIcon: Icons.help_rounded,
                  label: 'Q&A', index: 2, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.star_outline_rounded,
                  activeIcon: Icons.star_rounded,
                  label: 'Aura', index: 3, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile', index: 4, current: currentIndex, onTap: onTap),
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

  const _NavItem({
    required this.icon, required this.activeIcon,
    required this.label, required this.index,
    required this.current, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 23,
              color: active ? AppColors.primary : AppColors.text3,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? AppColors.primary : AppColors.text3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
