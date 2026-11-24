import 'package:flutter/material.dart';
import '../../../core/services/reward_feedback.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import 'shake_animation.dart';

enum OptionState { idle, selected, correct, wrong }

class QuizOptionRow extends StatefulWidget {
  final String letter;
  final String text;
  final OptionState state;
  final VoidCallback? onTap;

  const QuizOptionRow({
    super.key,
    required this.letter,
    required this.text,
    required this.state,
    this.onTap,
  });

  @override
  State<QuizOptionRow> createState() => _QuizOptionRowState();
}

class _QuizOptionRowState extends State<QuizOptionRow> {
  bool _down = false;

  (Color, Color, Color, Color, Color) get _colors => switch (widget.state) {
        OptionState.idle => (
            Ds.surface,
            Ds.border,
            const Color(0xFF1E2030),
            Ds.bone,
            Ds.border,
          ),
        OptionState.selected => (
            Ds.surface,
            Ds.aura,
            Ds.auraEdge,
            Ds.bone,
            Ds.aura,
          ),
        OptionState.correct => (
            Ds.mintPanel,
            Ds.mint,
            Ds.mintEdge,
            Ds.mint,
            Ds.mint,
          ),
        OptionState.wrong => (
            const Color(0xFF2B1418),
            Ds.hot,
            const Color(0xFFB33E4D),
            Ds.hot,
            Ds.hot,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (fill, border, edge, textColor, chipBg) = _colors;
    final enabled = widget.onTap != null;
    final edgeW = _down ? 2.0 : 5.0;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.state == OptionState.selected || widget.state == OptionState.correct,
      label: '${widget.letter}: ${widget.text}',
      child: ShakeAnimation(
        shake: widget.state == OptionState.wrong,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: () => setState(() => _down = false),
          onTapUp: enabled ? (_) => setState(() => _down = false) : null,
          onTap: enabled
              ? () {
                  RewardFeedback.selection();
                  widget.onTap!();
                }
              : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            margin: EdgeInsets.only(top: 5 - edgeW, bottom: 8),
            decoration: BoxDecoration(
              color: edge,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              margin: EdgeInsets.only(bottom: edgeW - 2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: border, width: 2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Letter Chip (28x28, radius 6)
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: widget.state == OptionState.correct
                          ? Ds.mint
                          : (widget.state == OptionState.wrong ? Ds.hot : chipBg),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.letter,
                      style: DsText.caption.copyWith(
                        color: widget.state == OptionState.correct || widget.state == OptionState.wrong
                            ? Ds.ink
                            : Ds.bone,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Option Text
                  Expanded(
                    child: Text(
                      widget.text,
                      style: DsText.body.copyWith(
                        color: widget.state == OptionState.wrong ? Ds.hot : textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // State Indicator Icon
                  if (widget.state == OptionState.correct)
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(Icons.check_circle_rounded, color: Ds.mint, size: 22),
                    )
                  else if (widget.state == OptionState.wrong)
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(Icons.cancel_rounded, color: Ds.hot, size: 22),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
