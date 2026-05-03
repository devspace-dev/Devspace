class EventAccessModel {
  final String id;
  final String title;
  final String description;
  final int requiredAura;
  final String link;
  final String type;
  final bool unlocked;
  final bool locked;
  final String? bannerUrl;
  final String? date;
  final String? endDate;
  final String? location;
  final String? organizer;

  const EventAccessModel({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredAura,
    required this.link,
    required this.type,
    required this.unlocked,
    required this.locked,
    this.bannerUrl,
    this.date,
    this.endDate,
    this.location,
    this.organizer,
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
      bannerUrl: json['banner_url']?.toString(),
      date: json['date']?.toString(),
      endDate: json['end_date']?.toString(),
      location: json['location']?.toString(),
      organizer: json['organizer']?.toString(),
    );
  }
}
