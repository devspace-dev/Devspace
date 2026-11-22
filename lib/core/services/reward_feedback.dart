import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RewardKind {
  practice,
  combatWin,
  dailyMissionSolved,
  dailyMissionAttempt,
  badgeEarned,
  questCompleted,
  firstAura,
}

/// Central reward haptics helper that maps confirmed server rewards to physical feedback.
/// Respects the user's "Haptics" toggle stored in SharedPreferences.
class RewardFeedback {
  RewardFeedback._();

  static const String _prefKey = 'haptics_enabled';
  static bool? _cachedEnabled;

  /// Returns true if haptics are enabled (default: true).
  static Future<bool> isHapticsEnabled() async {
    if (_cachedEnabled != null) return _cachedEnabled!;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedEnabled = prefs.getBool(_prefKey) ?? true;
      return _cachedEnabled!;
    } catch (_) {
      return true;
    }
  }

  /// Synchronous fast-check for active UI components.
  static bool get isHapticsEnabledSync => _cachedEnabled ?? true;

  /// Updates the user's haptic preference.
  static Future<void> setHapticsEnabled(bool enabled) async {
    _cachedEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enabled);
    } catch (_) {}
  }

  /// Triggers physical haptic feedback based on the confirmed reward kind.
  /// Must only be called AFTER server confirmation.
  static Future<void> play(RewardKind kind) async {
    final enabled = await isHapticsEnabled();
    if (!enabled) return;

    switch (kind) {
      case RewardKind.practice:
      case RewardKind.combatWin:
      case RewardKind.dailyMissionSolved:
        await HapticFeedback.mediumImpact();
        break;

      case RewardKind.dailyMissionAttempt:
      case RewardKind.questCompleted:
        await HapticFeedback.lightImpact();
        break;

      case RewardKind.badgeEarned:
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 120));
        await HapticFeedback.lightImpact();
        break;

      case RewardKind.firstAura:
        await HapticFeedback.heavyImpact();
        break;
    }
  }

  /// Resets cached state for unit testing.
  static void resetForTest({bool? enabled}) {
    _cachedEnabled = enabled;
  }
}
