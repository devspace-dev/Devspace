import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DevSpaceLogo extends StatelessWidget {
  final double size;
  final bool elevated;
  final Color? color;

  const DevSpaceLogo({
    super.key,
    this.size = 72,
    this.elevated = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targetColor = color ?? (isDark ? Colors.white : const Color(0xFFFF5E00));
    final filter = ColorFilter.matrix([
      targetColor.r, 0, 0, 0, 0,
      targetColor.g, 0, 0, 0, 0,
      targetColor.b, 0, 0, 0, 0,
      1.0, 0, 0, 0, 0,
    ]);

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: ColorFiltered(
          colorFilter: filter,
          child: Image.asset(
            'assets/images/app_icon.png',
            width: size * 0.9,
            height: size * 0.9,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.rocket_launch_rounded,
              color: targetColor,
              size: size * 0.8,
            ),
          ),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .scale(
           duration: 2000.ms,
           begin: const Offset(1, 1),
           end: const Offset(1.05, 1.05),
           curve: Curves.easeInOutSine,
         )
         .shimmer(
           duration: 3000.ms,
           color: Colors.white.withValues(alpha: 0.1),
         ),
      ),
    );
  }
}
