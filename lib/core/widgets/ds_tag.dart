import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text.dart';

class _TagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(6, 0)
    ..lineTo(s.width, 0)
    ..lineTo(s.width - 6, s.height)
    ..lineTo(0, s.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

class DsTag extends StatelessWidget {
  const DsTag(
    this.text, {
    super.key,
    this.bg = Ds.border,
    this.fg = Ds.bone,
  });

  final String text;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) => ClipPath(
        clipper: _TagClipper(),
        child: Container(
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Text(
            text.toUpperCase(),
            style: DsText.caption.copyWith(
              color: fg,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
}
