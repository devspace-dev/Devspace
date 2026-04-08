import 'dart:math' as math;

import 'package:flutter/material.dart';

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
    final radius = size * 0.38;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF07111F),
            Color(0xFF0B1B31),
            Color(0xFF12365C),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF7DD3FC).withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: const Color(0xFF0891B2).withValues(alpha: 0.22),
                  blurRadius: size * 0.22,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(
          painter: _DevSpaceLogoPainter(),
        ),
      ),
    );
  }
}

class _DevSpaceLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width * 0.52, size.height * 0.5);

    final glossPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x40FFFFFF),
          Color(0x08FFFFFF),
          Color(0x00000000),
        ],
        stops: [0, 0.36, 1],
      ).createShader(rect);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.02,
        size.width * 0.7,
        size.height * 0.52,
      ),
      glossPaint,
    );

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.072
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF7DD3FC),
          Color(0xFF22D3EE),
          Color(0xFFF97316),
        ],
      ).createShader(rect);

    final orbitRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.56,
      height: size.height * 0.68,
    );
    canvas.drawArc(
      orbitRect,
      -math.pi * 0.7,
      math.pi * 1.4,
      false,
      orbitPaint,
    );

    final slashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.092
      ..color = const Color(0xFFF8FAFC);
    canvas.drawLine(
      Offset(size.width * 0.41, size.height * 0.34),
      Offset(size.width * 0.58, size.height * 0.66),
      slashPaint,
    );

    final chevronPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.width * 0.058
      ..color = const Color(0xFFE2E8F0);

    final left = Path()
      ..moveTo(size.width * 0.31, size.height * 0.38)
      ..lineTo(size.width * 0.23, size.height * 0.5)
      ..lineTo(size.width * 0.31, size.height * 0.62);
    canvas.drawPath(left, chevronPaint);

    final right = Path()
      ..moveTo(size.width * 0.69, size.height * 0.38)
      ..lineTo(size.width * 0.77, size.height * 0.5)
      ..lineTo(size.width * 0.69, size.height * 0.62);
    canvas.drawPath(right, chevronPaint);

    final nodePaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFDAA61),
          Color(0xFFF97316),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.72, size.height * 0.31),
          radius: size.width * 0.09,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.31),
      size.width * 0.062,
      nodePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
