import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/text.dart';

enum DsButtonKind { aura, mint, bone }

class DsButton extends StatefulWidget {
  const DsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = DsButtonKind.aura,
    this.height = 52,
    this.icon,
    this.uppercase = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final DsButtonKind kind;
  final double height;
  final Widget? icon;
  final bool uppercase;
  final bool loading;

  @override
  State<DsButton> createState() => _DsButtonState();
}

class _DsButtonState extends State<DsButton> {
  bool _down = false;

  (Color, Color, Color) get _c => switch (widget.kind) {
    DsButtonKind.aura => (Ds.aura, Ds.auraEdge, Ds.onAura),
    DsButtonKind.mint => (Ds.mint, Ds.mintEdge, Ds.ink),
    DsButtonKind.bone => (Ds.bone, const Color(0xFFB9B2A3), Ds.ink),
  };

  @override
  Widget build(BuildContext context) {
    final (fill, edge, fg) = _c;
    final enabled = widget.onPressed != null && !widget.loading;
    final edgeW = _down ? 2.0 : 5.0;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          height: widget.height,
          width: double.infinity,
          margin: EdgeInsets.only(top: 5 - edgeW), // keeps total height stable
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? fill : Ds.border,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              bottom: BorderSide(
                color: enabled ? edge : const Color(0xFF1E2030),
                width: edgeW,
              ),
            ),
          ),
          child: widget.loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: fg,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      widget.icon!,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.uppercase
                          ? widget.label.toUpperCase()
                          : widget.label,
                      style: DsText.button.copyWith(
                        color: enabled ? fg : Ds.muted,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
