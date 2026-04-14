import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
    final outerRadius = BorderRadius.circular(size * 0.28);
    final innerRadius = BorderRadius.circular(size * 0.2);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        borderRadius: outerRadius,
        color: const Color(0xFF0F0F12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: size * 0.15,
                  offset: Offset(0, size * 0.05),
                ),
              ]
            : null,
      ),
      child: Image.asset(
        'assets/images/app_icon.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
