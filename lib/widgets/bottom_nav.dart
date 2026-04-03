import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
      padding: const EdgeInsets.only(bottom: 16),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: GlassContainer(
            color: AppColors.bg2For(context),
            opacity: 0.85,
            blur: 30.0,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColors.borderFor(context).withValues(alpha: 0.5),
              width: 0.8,
            ),
            child: SizedBox(
              height: 72,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.house_outlined,
                    activeIcon: Icons.house_rounded,
                    label: 'Home',
                    index: 0,
                    current: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.person_search_outlined,
                    activeIcon: Icons.person_search_rounded,
                    label: 'Devs',
                    index: 1,
                    current: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.bubble_chart_outlined,
                    activeIcon: Icons.bubble_chart_rounded,
                    label: 'Q&A',
                    index: 2,
                    current: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.rocket_launch_outlined,
                    activeIcon: Icons.rocket_launch_rounded,
                    label: 'Opps',
                    index: 3,
                    current: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.account_circle_outlined,
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
    final color = active ? AppColors.primary : AppColors.text3For(context);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!active) HapticFeedback.mediumImpact();
          onTap(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutQuad,
              padding: EdgeInsets.all(active ? 8 : 0),
              decoration: BoxDecoration(
                color: active ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                active ? activeIcon : icon,
                size: 26,
                color: color,
              ),
            ),
            if (!active) const SizedBox(height: 4),
            if (!active)
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
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
