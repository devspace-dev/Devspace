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
    return GlassContainer(
      color: AppColors.bg,
      opacity: 0.8,
      blur: 15.0,
      border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
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
        onTap: () {
          if (!active) HapticFeedback.selectionClick();
          onTap(index);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: active ? 1.0 : 0.95,
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  active ? activeIcon : icon,
                  key: ValueKey(active),
                  size: 24,
                  color: active ? AppColors.primary : AppColors.text3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  color: active ? AppColors.primary : AppColors.text3,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
