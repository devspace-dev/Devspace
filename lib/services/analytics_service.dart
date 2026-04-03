import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
    } catch (e) {
      debugPrint('Analytics logAppOpen failed: $e');
    }
  }

  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Analytics logLogin failed: $e');
    }
  }

  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('Analytics logSignUp failed: $e');
    }
  }

  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logEvent(
        name: 'screen_view',
        parameters: {
          'firebase_screen': screenName,
          'firebase_screen_class': screenName,
        },
      );
    } catch (e) {
      debugPrint('Analytics logScreenView failed: $e');
    }
  }

  Future<void> logPostCreated(String postId, String type) async {
    try {
      await _analytics.logEvent(
        name: 'post_created',
        parameters: {
          'post_id': postId,
          'post_type': type,
        },
      );
    } catch (e) {
      debugPrint('Analytics logPostCreated failed: $e');
    }
  }

  Future<void> logPostLiked(String postId) async {
    try {
      await _analytics.logEvent(
        name: 'post_liked',
        parameters: {
          'post_id': postId,
        },
      );
    } catch (e) {
      debugPrint('Analytics logPostLiked failed: $e');
    }
  }

  Future<void> setUserIdentifier(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint('Analytics setUserIdentifier failed: $e');
    }
  }

  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics logEvent failed: $e');
    }
  }
}
