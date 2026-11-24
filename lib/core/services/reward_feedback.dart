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
  subtle,
  levelUp,
}

typedef RewardFeedbackKind = RewardKind;

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
      case RewardKind.levelUp:
        await HapticFeedback.heavyImpact();
        break;

      case RewardKind.subtle:
        await HapticFeedback.selectionClick();
        break;
    }
  }

  /// Resets cached state for unit testing.
  static void resetForTest({bool? enabled}) {
    _cachedEnabled = enabled;
  }

  /// Plays light impact if haptics are enabled (for button clicks, likes, card taps).
  static Future<void> light() async {
    if (!isHapticsEnabledSync) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Plays medium impact if haptics are enabled (for quiz wrong answers, primary actions).
  static Future<void> medium() async {
    if (!isHapticsEnabledSync) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Plays heavy impact if haptics are enabled (for milestone celebrations, aura rewards).
  static Future<void> heavy() async {
    if (!isHapticsEnabledSync) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Plays selection click if haptics are enabled (for tab switching, quiz option selects).
  static Future<void> selection() async {
    if (!isHapticsEnabledSync) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Plays success celebration feedback (medium + light double-pulse).
  static Future<void> success() async {
    if (!isHapticsEnabledSync) return;
    try {
      await HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!isHapticsEnabledSync) return;
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }
}
