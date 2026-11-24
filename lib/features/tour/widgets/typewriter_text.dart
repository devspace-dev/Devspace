import 'package:flutter/material.dart';

/// Animated typewriter text widget that reveals text at ~25ms per character.
/// - Uses Flutter's [AnimationController] ticker for frame-precise rendering without timer drift.
/// - Tapping anywhere on the text immediately completes the full reveal.
/// - When system reduce-motion is active (`MediaQuery.disableAnimationsOf(context)`), reveals instantly.
/// - Screen readers (Semantics) receive the full text immediately, not character by character.
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDuration;
  final VoidCallback? onComplete;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.charDuration = const Duration(milliseconds: 25),
    this.onComplete,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _charAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    final totalMs = widget.text.isEmpty
        ? 1
        : widget.charDuration.inMilliseconds * widget.text.length;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs.clamp(1, 100000)),
    );

    _charAnimation = StepTween(
      begin: 0,
      end: widget.text.length,
    ).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion || widget.text.isEmpty) {
      _controller.value = 1.0;
    } else if (!_controller.isAnimating && !_controller.isCompleted) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.dispose();
      _initAnimation();
      final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (reduceMotion || widget.text.isEmpty) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _completeInstantly() {
    if (!_controller.isCompleted) {
      _controller.forward(from: 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      label: widget.text, // Screen reader receives the full text immediately
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _completeInstantly,
        child: AnimatedBuilder(
          animation: _charAnimation,
          builder: (context, _) {
            final count = _charAnimation.value.clamp(0, widget.text.length);
            final visibleText = widget.text.substring(0, count);

            return Text(
              visibleText,
              style: widget.style,
            );
          },
        ),
      ),
    );
  }
}
