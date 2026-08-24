import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_service.dart';

class MonthlyAuraService {
  MonthlyAuraService._internal();
  static final MonthlyAuraService instance = MonthlyAuraService._internal();

  static const String _keyLastResetMonth = 'devspace_last_aura_reset_month';

  String get currentMonthKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String get currentSeasonName {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final monthName = months[now.month - 1];
    return '$monthName ${now.year} Season';
  }

  int get daysRemainingInMonth {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    return lastDayOfMonth.day - now.day;
  }

  Future<bool> checkAndResetMonthlyAuraIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastResetMonth = prefs.getString(_keyLastResetMonth);
      final activeMonthKey = currentMonthKey;

      if (lastResetMonth == null) {
        await prefs.setString(_keyLastResetMonth, activeMonthKey);
        return false;
      }

      if (lastResetMonth != activeMonthKey) {
        debugPrint(
          '🗓️ Month boundary detected! Previous: $lastResetMonth -> Current: $activeMonthKey. Resetting Aura...',
        );
        await forceResetMonthlyAura();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking monthly aura reset: $e');
      return false;
    }
  }

  Future<void> forceResetMonthlyAura() async {
    try {
      await SupabaseService.instance.resetAllUsersMonthlyAura();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastResetMonth, currentMonthKey);

      debugPrint('✅ Monthly Aura Reset completed successfully.');
    } catch (e) {
      debugPrint('Failed to execute monthly aura reset: $e');
      rethrow;
    }
  }
}
