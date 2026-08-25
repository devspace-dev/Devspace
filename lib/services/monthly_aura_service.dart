import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_service.dart';

class MonthlyAuraService {
  MonthlyAuraService._internal();
  static final MonthlyAuraService instance = MonthlyAuraService._internal();

  static const String _keyLastResetMonth = 'devspace_last_aura_reset_month';

  /// Returns the current month key string in 'YYYY-MM' format (e.g. '2026-08')
  String get currentMonthKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Returns readable month season name (e.g., "August 2026 Season")
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

  /// Calculates number of days remaining until the end of the current month
  int get daysRemainingInMonth {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    return lastDayOfMonth.day - now.day;
  }

  /// Checks if a new month has started and resets all users' Aura if needed.
  /// Returns [true] if a monthly reset was performed.
  Future<bool> checkAndResetMonthlyAuraIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastResetMonth = prefs.getString(_keyLastResetMonth);
      final activeMonthKey = currentMonthKey;

      if (lastResetMonth == null) {
        // First initialization - store current month
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
}

