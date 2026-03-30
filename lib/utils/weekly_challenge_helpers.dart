String weeklyChallengeFocus(dynamic me) {
  final stack = (me?.stack is List && (me.stack as List).isNotEmpty)
      ? (me.stack as List).first.toString()
      : '';
  final role = weeklyChallengeSafeValue(me?.role);
  final building = weeklyChallengeSafeValue(me?.building);

  if (stack.isNotEmpty) return '$stack growth';
  if (role.isNotEmpty) return '$role prep';
  if (building.isNotEmpty) return building;
  return 'career growth';
}

String weeklyChallengeSafeValue(dynamic value, {String fallback = ''}) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'not set') {
    return fallback;
  }
  return text;
}
