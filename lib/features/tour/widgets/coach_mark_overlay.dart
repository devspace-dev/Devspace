import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/ds_button.dart';
import '../../../core/widgets/ds_card.dart';
import '../../../core/widgets/glitch.dart';
import 'typewriter_text.dart';

/// Fullscreen overlay that dims the background with a rounded spotlight cutout
/// around [targetRect] and positions a tooltip bubble on the side with room.
class CoachMarkOverlay extends StatelessWidget {
  final Rect? targetRect;
  final String title;
  final String body;
  final GlitchMood mood;
  final String primaryButtonLabel;
  final VoidCallback onPrimaryPressed;
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondaryPressed;
  final VoidCallback? onDismiss;
  final VoidCallback? onTargetTap;

  const CoachMarkOverlay({
    super.key,
    required this.targetRect,
    required this.title,
    required this.body,
    this.mood = GlitchMood.idle,
    this.primaryButtonLabel = 'Next',
    required this.onPrimaryPressed,
    this.secondaryButtonLabel,
    this.onSecondaryPressed,
    this.onDismiss,
    this.onTargetTap,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final padding = mediaQuery.padding;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onDismiss?.call();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Semi-transparent scrim with spotlight hole
          GestureDetector(
            onTapUp: (details) {
              if (targetRect != null && targetRect!.contains(details.localPosition)) {
                if (onTargetTap != null) {
                  onTargetTap!();
                  return;
                }
              }
              onDismiss?.call();
            },
            behavior: HitTestBehavior.translucent,
            child: CustomPaint(
              size: screenSize,
              painter: _SpotlightPainter(
                targetRect: targetRect,
                scrimColor: Ds.ink.withValues(alpha: 0.85),
              ),
            ),
          ),

          // 2. Positioned Tooltip Bubble
          _buildPositionedTooltip(context, screenSize, padding),
        ],
      ),
    );
  }

  Widget _buildPositionedTooltip(
    BuildContext context,
    Size screenSize,
    EdgeInsets safePadding,
  ) {
    // If targetRect is null (fallback mode), center on screen
    if (targetRect == null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _buildTooltipCard(context, double.infinity),
        ),
      );
    }

    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // Tooltip width constrained to fit 360dp phones up to tablets
    final double maxCardWidth = math.min(screenWidth - 32, 400.0);

    // Determine vertical placement: place above or below depending on available space
    final double spaceAbove = targetRect!.top - safePadding.top;
    final double spaceBelow = screenHeight - safePadding.bottom - targetRect!.bottom;

    final bool placeBelow = spaceBelow >= 220 || spaceBelow >= spaceAbove;

    // Horizontal clamping inside safe margins
    final double targetCenterX = targetRect!.center.dx;
    final double left = (targetCenterX - (maxCardWidth / 2))
        .clamp(16.0, screenWidth - maxCardWidth - 16.0);

    final double? top = placeBelow
        ? (targetRect!.bottom + 12).clamp(safePadding.top + 8, screenHeight - 260)
        : null;

    final double? bottom = !placeBelow
        ? (screenHeight - targetRect!.top + 12)
            .clamp(safePadding.bottom + 8, screenHeight - 120)
        : null;

    return Positioned(
      left: left,
      width: maxCardWidth,
      top: top,
      bottom: bottom,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: math.max(
            180.0,
            screenHeight - (top ?? safePadding.top) - safePadding.bottom - 16,
          ),
        ),
        child: SingleChildScrollView(
          child: _buildTooltipCard(context, maxCardWidth),
        ),
      ),
    );
  }

  Widget _buildTooltipCard(BuildContext context, double width) {
    return DsCard(
      padding: const EdgeInsets.all(16),
      borderColor: Ds.aura,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Glitch Mascot + Title Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Glitch(size: 42, mood: mood),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: DsText.label.copyWith(color: Ds.aura),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    TypewriterText(
                      text: body,
                      style: DsText.bodySm.copyWith(
                        color: Ds.bone,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (secondaryButtonLabel != null)
                  TextButton(
                    onPressed: onSecondaryPressed,
                    child: Text(
                      secondaryButtonLabel!,
                      style: DsText.caption.copyWith(color: Ds.muted),
                    ),
                  ),
                DsButton(
                  label: primaryButtonLabel,
                  height: MediaQuery.textScalerOf(context).scale(40).clamp(40.0, 56.0),
                  kind: DsButtonKind.aura,
                  onPressed: onPrimaryPressed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter that renders a dark scrim with a smooth rounded rectangular cutout.
class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final Color scrimColor;

  _SpotlightPainter({
    required this.targetRect,
    required this.scrimColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (targetRect == null) {
      canvas.drawPath(backgroundPath, Paint()..color = scrimColor);
      return;
    }

    // Expand the target rect slightly for breathing room
    final holeRect = targetRect!.inflate(6);
    final holePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(holeRect, const Radius.circular(12)),
      );

    // Subtract the hole from the background scrim
    final combinedPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );

    canvas.drawPath(combinedPath, Paint()..color = scrimColor);

    // Draw high-contrast glowing border around the cutout
    final borderPaint = Paint()
      ..color = Ds.aura
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(holeRect, const Radius.circular(12)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.scrimColor != scrimColor;
  }
}
