class EventAccessModel {
  final String id;
  final String title;
  final String description;
  final int requiredAura;
  final String link;
  final String type;
  final bool unlocked;
  final bool locked;

  const EventAccessModel({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredAura,
    required this.link,
    required this.type,
    required this.unlocked,
    required this.locked,
  });

  factory EventAccessModel.fromJson(Map<String, dynamic> json) {
    return EventAccessModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      requiredAura:
          ((json['required_aura'] ?? json['requiredAura'] ?? 0) as num).toInt(),
      link: (json['link'] ?? '').toString(),
      type: (json['type'] ?? 'event').toString(),
      unlocked: json['unlocked'] as bool? ?? false,
      locked: json['locked'] as bool? ?? true,
    );
  }
}
