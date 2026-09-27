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
      case 'practice_question':
      case 'qa_solution':
      case 'answer_accepted':
      case 'solve_question':
        return 'Solved Q&A / Practice Question';
      case 'complete_daily_mission':
      case 'complete_daily_challenge':
      case 'daily_challenge':
      case 'mission_solved':
      case 'challenge_solved':
        return 'Solved Daily Mission (+20)';
      case 'attempt_daily_mission':
      case 'daily_mission_attempt':
      case 'mission_attempted':
      case 'challenge_attempted':
        return 'Attempted Daily Mission (+5)';
      case 'arena_duel':
        return 'Arena Combat Victory';
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
