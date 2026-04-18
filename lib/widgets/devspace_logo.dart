import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DevSpaceLogo extends StatelessWidget {
  final double size;
  final bool elevated;

  const DevSpaceLogo({
    super.key,
    this.size = 72,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Image.asset(
          'assets/images/app_icon.png',
          width: size * 0.9,
          height: size * 0.9,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.rocket_launch_rounded,
            color: const Color(0xFF00D1FF),
            size: size * 0.8,
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
