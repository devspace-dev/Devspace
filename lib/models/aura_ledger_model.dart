import 'package:intl/intl.dart';

class AuraLedgerModel {
  final String id;
  final String userId;
  final String action;
  final int points;
  final String? referenceType;
  final String? referenceId;
  final String? actorId;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  AuraLedgerModel({
    required this.id,
    required this.userId,
    required this.action,
    required this.points,
    this.referenceType,
    this.referenceId,
    this.actorId,
    required this.createdAt,
    this.metadata = const {},
  });

  factory AuraLedgerModel.fromJson(Map<String, dynamic> json) {
    return AuraLedgerModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      points: json['points'] is int ? json['points'] : (int.tryParse(json['points']?.toString() ?? '0') ?? 0),
      referenceType: json['reference_type']?.toString(),
      referenceId: json['reference_id']?.toString(),
      actorId: json['actor_id']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']).toLocal() 
          : DateTime.now(),
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata'] as Map) : const {},
    );
  }

  String get formattedDate => DateFormat('MMM d, h:mm a').format(createdAt);

  String get description {
    switch (action) {
      case 'daily_challenge':
        return 'Solved Daily Mission';
      case 'daily_mission_attempt':
        return 'Attempted Daily Mission';
      case 'create_post':
        return 'Created a Post';
      case 'add_comment':
        return 'Commented on a Post';
      case 'post_like':
        return 'Received a Like';
      case 'question_upvote':
        return 'Question was Upvoted';
      case 'solve_question':
        return 'Solved a Question';
      case 'onboarding':
        return 'Welcome Bonus';
      default:
        return action.replaceAll('_', ' ').capitalize();
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
