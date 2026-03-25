import '../models/badge_model.dart';

String formatAura(int aura) {
  if (aura >= 1000) return '${(aura / 1000).toStringAsFixed(1)}k';
  return aura.toString();
}

String auraProgressLabel(int aura) {
  final next = getNextBadge(aura);
  if (next == null) return 'Max level!';
  final remaining = next.min - aura;
  return '$remaining pts to ${next.icon} ${next.name}';
}
