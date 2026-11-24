import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum GlitchMood { idle, win, lose, hype }

class Glitch extends StatelessWidget {
  const Glitch({super.key, this.size = 64, this.mood = GlitchMood.idle});
  final double size;
  final GlitchMood mood;

  static const _ink = '#0D0E14';
  static const _bone = '#F5F0E6';
  static const _hot = '#FF5A6E';

  static String _spiral(int cx) =>
      '<circle cx="$cx" cy="50" r="9" fill="$_bone"/>'
      '<path d="M$cx 50a1.5 1.5 0 1 1 1.5 1.5a3 3 0 1 1-3-3a4.5 4.5 0 1 1 4.5 4.5" stroke="$_ink" stroke-width="2" fill="none"/>';

  static String _face(GlitchMood m) => switch (m) {
    GlitchMood.idle =>
      '<circle cx="38" cy="50" r="9" fill="$_bone"/><circle cx="62" cy="50" r="9" fill="$_bone"/>'
      '<circle cx="40" cy="52" r="4" fill="$_ink"/><circle cx="64" cy="52" r="4" fill="$_ink"/>'
      '<path d="M42 67Q50 73 58 67" stroke="$_ink" stroke-width="3" fill="none" stroke-linecap="round"/>',
    GlitchMood.win =>
      '<path d="M30 53Q38 42 46 53M54 53Q62 42 70 53" stroke="$_ink" stroke-width="4" fill="none" stroke-linecap="round"/>'
      '<path d="M37 62Q50 82 63 62Z" fill="$_ink"/>',
    GlitchMood.lose =>
      '${_spiral(38)}${_spiral(62)}'
      '<path d="M40 71Q45 64 50 68Q55 72 60 66" stroke="$_ink" stroke-width="3" fill="none" stroke-linecap="round"/>',
    GlitchMood.hype =>
      '<circle cx="38" cy="50" r="10" fill="$_bone"/><circle cx="62" cy="50" r="10" fill="$_bone"/>'
      '<circle cx="38" cy="48" r="5" fill="$_ink"/><circle cx="62" cy="48" r="5" fill="$_ink"/>'
      '<ellipse cx="50" cy="69" rx="6" ry="7" fill="$_ink"/>',
  };

  static String svg(GlitchMood m) {
    final ghost = (m == GlitchMood.lose || m == GlitchMood.hype)
        ? '<ellipse cx="46" cy="60" rx="38" ry="33" fill="#3FE0FF" opacity=".7"/>'
          '<ellipse cx="54" cy="60" rx="38" ry="33" fill="#FF3DCB" opacity=".7"/>'
        : '';
    return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
<path d="M38 26Q34 14 28 10" stroke="$_bone" stroke-width="3" fill="none" stroke-linecap="round"/>
<circle cx="28" cy="10" r="4" fill="$_bone"/>
<path d="M62 26L66 17L60 12L68 7" stroke="$_bone" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
<rect x="66" y="1" width="8" height="8" fill="$_bone"/>
$ghost
<ellipse cx="50" cy="60" rx="38" ry="33" fill="$_hot"/>
<text x="50" y="92" text-anchor="middle" font-family="monospace" font-size="16" font-weight="700" fill="$_ink">{ }</text>
${_face(m)}
<path d="M14 56A36 36 0 0 1 86 56" stroke="$_ink" stroke-width="5" fill="none"/>
<rect x="8" y="50" width="10" height="18" rx="4" fill="$_ink"/>
<rect x="82" y="50" width="10" height="18" rx="4" fill="$_ink"/>
<circle cx="13" cy="59" r="2" fill="$_bone"/><circle cx="87" cy="59" r="2" fill="$_bone"/>
</svg>''';
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: SvgPicture.string(svg(mood), width: size, height: size),
      );
}
