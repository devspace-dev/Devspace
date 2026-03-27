import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: GlassContainer(
        color: AppColors.bg2,
        opacity: 0.9,
        blur: 20.0,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border, width: 2),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded,
                    activeIcon: Icons.home_rounded,
                    label: 'Home', index: 0, current: currentIndex, onTap: onTap),
                _NavItem(icon: Icons.people_outline_rounded,
                    activeIcon: Icons.people_rounded,
                    label: 'Devs', index: 1, current: currentIndex, onTap: onTap),
                _NavItem(icon: Icons.help_outline_rounded,
                    activeIcon: Icons.help_rounded,
                    label: 'Q&A', index: 2, current: currentIndex, onTap: onTap),
                _NavItem(icon: Icons.auto_awesome_rounded,
                    activeIcon: Icons.auto_awesome_rounded,
                    label: 'Aura', index: 3, current: currentIndex, onTap: onTap),
                _NavItem(icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Me', index: 4, current: currentIndex, onTap: onTap),
              ],
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
    required this.icon, required this.activeIcon,
    required this.label, required this.index,
    required this.current, required this.onTap,
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              padding: EdgeInsets.symmetric(
                horizontal: active ? 16 : 8,
                vertical: active ? 8 : 4,
              ),
              decoration: BoxDecoration(
                color: active ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                active ? activeIcon : icon,
                size: 24,
                color: color,
              ),
            ).animate(target: active ? 1 : 0).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.15, 1.15),
              duration: 400.ms,
              curve: Curves.elasticOut,
            ),
            if (active)
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 0.4,
                ),
              ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.5, end: 0),
          ],
        ),
      ),
    );
  }
}
