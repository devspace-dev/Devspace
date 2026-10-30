import 'package:flutter/material.dart';
import '../theme/colors.dart';

class SegmentBar extends StatelessWidget {
  const SegmentBar({
    super.key,
    required this.total,
    required this.current,
    this.height = 10,
    this.gap = 4,
    this.radius = 3,
    this.filledColor = Ds.mint,
    this.emptyColor = Ds.border,
  });

  final int total;
  final int current;
  final double height;
  final double gap;
  final double radius;
  final Color filledColor;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();

    return Row(
      children: List.generate(total, (index) {
        final isFilled = index < current;
        return Expanded(
          child: Container(
            height: height,
            margin: EdgeInsets.only(right: index == total - 1 ? 0 : gap),
            decoration: BoxDecoration(
              color: isFilled ? filledColor : emptyColor,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );
      }),
    );
  }
}
