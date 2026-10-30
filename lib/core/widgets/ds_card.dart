import 'package:flutter/material.dart';
import '../theme/colors.dart';

class DsCard extends StatelessWidget {
  const DsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.leftBar,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? leftBar; // tier color for lobby cards
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (leftBar != null) {
      body = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 8,
              color: leftBar,
            ),
            Expanded(
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ],
        ),
      );
    } else {
      body = Padding(
        padding: padding,
        child: child,
      );
    }

    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Ds.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor ?? Ds.border,
          width: 2,
        ),
      ),
      child: body,
    );

    if (onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}
