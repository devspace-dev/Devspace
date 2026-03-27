import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color color;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.6,
    this.color = Colors.black,
    this.borderRadius,
    this.border,
    this.padding,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(28);
    
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color.withValues(alpha: opacity),
            borderRadius: radius,
            border: border,
            gradient: gradient,
            boxShadow: [
              if (opacity > 0.1)
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
