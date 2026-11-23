import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/ds_button.dart';
import '../../../core/widgets/ds_card.dart';
import '../../../core/widgets/ds_tag.dart';
import '../../../core/widgets/glitch.dart';
import 'typewriter_text.dart';

/// Fullscreen overlay that dims the background with a rounded spotlight cutout
/// around [targetRect] and positions a tooltip bubble on the side with room.
class CoachMarkOverlay extends StatefulWidget {
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
  final String? stepPill;

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
    this.stepPill,
  });

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay> {
  final GlobalKey _stackKey = GlobalKey();

  Rect? _calculateLocalTargetRect() {
    if (widget.targetRect == null) return null;
    final context = _stackKey.currentContext;
    if (context == null || !context.mounted) return widget.targetRect;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize || !renderBox.attached) {
      return widget.targetRect;
    }

    final globalTopLeft = widget.targetRect!.topLeft;
    final globalBottomRight = widget.targetRect!.bottomRight;
    final localTopLeft = renderBox.globalToLocal(globalTopLeft);
    final localBottomRight = renderBox.globalToLocal(globalBottomRight);

    return Rect.fromPoints(localTopLeft, localBottomRight);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final padding = mediaQuery.padding;
    final localTargetRect = _calculateLocalTargetRect();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onDismiss?.call();
      },
      child: Stack(
        key: _stackKey,
        fit: StackFit.expand,
        children: [
          // 1. Semi-transparent scrim with spotlight hole
          GestureDetector(
            onTapUp: (details) {
              final local = details.localPosition;
              if (localTargetRect != null &&
                  localTargetRect.inflate(10).contains(local)) {
                if (widget.onTargetTap != null) {
                  widget.onTargetTap!();
                  return;
                }
              }
              // Prevent accidental background dismiss
            },
            behavior: HitTestBehavior.translucent,
            child: RepaintBoundary(
              child: CustomPaint(
                size: screenSize,
                painter: _SpotlightPainter(
                  targetRect: localTargetRect,
                  scrimColor: Ds.ink.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),

          // 2. Positioned Tooltip Bubble
          _buildPositionedTooltip(context, screenSize, padding, localTargetRect),
        ],
      ),
    );
  }

  Widget _buildPositionedTooltip(
    BuildContext context,
    Size screenSize,
    EdgeInsets safePadding,
    Rect? localRect,
  ) {
    if (localRect == null) {
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
    final double maxCardWidth = math.min(screenWidth - 32, 380.0);

    // Determine vertical placement: place above or below depending on available space
    final double spaceAbove = localRect.top - safePadding.top;
    final double spaceBelow = screenHeight - safePadding.bottom - localRect.bottom;

    final bool placeBelow = spaceBelow >= 240 && spaceBelow >= spaceAbove;

    // Horizontal clamping inside safe margins
    final double targetCenterX = localRect.center.dx;
    final double left = (targetCenterX - (maxCardWidth / 2))
        .clamp(16.0, screenWidth - maxCardWidth - 16.0);

    final double? top = placeBelow
        ? (localRect.bottom + 14).clamp(safePadding.top + 8, screenHeight - 240)
        : null;

    final double? bottom = !placeBelow
        ? (screenHeight - localRect.top + 14)
            .clamp(safePadding.bottom + 8, screenHeight - safePadding.top - 180)
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
            screenHeight - (top ?? safePadding.top) - (bottom ?? safePadding.bottom) - 32,
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
          // Header: Glitch Mascot + Step Tag + Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Glitch(size: 40, mood: widget.mood),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.stepPill != null && widget.stepPill!.isNotEmpty) ...[
                      DsTag(widget.stepPill!, bg: Ds.ink, fg: Ds.aura),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      widget.title.toUpperCase(),
                      style: DsText.h3.copyWith(fontSize: 16, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Body: Typewriter text effect
          TypewriterText(
            text: widget.body,
            style: DsText.bodySm.copyWith(
              color: Ds.bone,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Footer Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.secondaryButtonLabel != null)
                TextButton(
                  onPressed: widget.onSecondaryPressed,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: const Size(48, 40),
                  ),
                  child: Text(
                    widget.secondaryButtonLabel!,
                    style: DsText.caption.copyWith(
                      color: Ds.muted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              DsButton(
                label: widget.primaryButtonLabel,
                height: 42,
                kind: DsButtonKind.aura,
                onPressed: widget.onPrimaryPressed,
              ),
            ],
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
    final holeRect = targetRect!.inflate(8);
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
      ..strokeWidth = 2.5;

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
