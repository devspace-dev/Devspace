import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/challenge_question.dart';

class ChallengeService {
  final _supabase = Supabase.instance.client;

  Future<List<ChallengeQuestion>> getWeeklyQuestions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // 1. Fetch user row
      Map<String, dynamic>? userRow;
      try {
        userRow = await _supabase
            .from('users')
            .select('is_premium, career_goal')
            .eq('id', user.id)
            .maybeSingle();
      } catch (_) {
        try {
          userRow = await _supabase
              .from('users')
              .select('is_premium')
              .eq('id', user.id)
              .maybeSingle();
        } catch (_) {}
      }

      final bool isPremium = userRow?['is_premium'] ?? false;
      final String? userGoal = userRow?['career_goal'];

      final int currentWeekNumber =
          DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays ~/ 7 + 1;

      if (isPremium && userGoal != null) {
        // 2. Query premium_questions
        var response = await _supabase
            .from('premium_questions')
            .select()
            .eq('career_goal', userGoal)
            .eq('week', currentWeekNumber)
            .limit(5);

        if (response.isEmpty) {
          // 3. Fetch latest 5 for that career_goal if no results for this week
          response = await _supabase
              .from('premium_questions')
              .select()
              .eq('career_goal', userGoal)
              .order('week', ascending: false)
              .limit(5);
        }

        return response.map((q) => ChallengeQuestion.fromMap(q)).toList();
      } else {
        // 4. Query free_questions
        final response = await _supabase
            .from('free_questions')
            .select()
            .eq('week', currentWeekNumber)
            .limit(5);

        return response.map((q) => ChallengeQuestion.fromMap(q)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching weekly questions: $e');
      return [];
    }
  }
}
