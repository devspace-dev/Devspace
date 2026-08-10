String formatAura(int aura) {
  if (aura >= 1000) return '${(aura / 1000).toStringAsFixed(1)}k';
  return aura.toString();
}

String auraProgressLabel(int aura) {
  return '$aura Aura';
}
