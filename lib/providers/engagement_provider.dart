import 'package:flutter/material.dart';

import '../models/aura_summary_model.dart';
import '../models/daily_challenge_model.dart';
import '../models/event_access_model.dart';
import '../services/auth_service.dart';
import '../services/backend_api_service.dart';

typedef AuraSummaryLoader = Future<AuraSummaryModel> Function();
typedef EligibleEventsLoader = Future<List<EventAccessModel>> Function();
typedef DailyChallengeLoader = Future<DailyChallengeModel?> Function();
typedef DailyChallengeSubmitter = Future<Map<String, dynamic>> Function({
  required String submissionText,
  required String submissionLink,
});
typedef UserRefreshCallback = Future<void> Function();

class EngagementProvider extends ChangeNotifier {
  EngagementProvider({
    AuraSummaryLoader? auraSummaryLoader,
    EligibleEventsLoader? eligibleEventsLoader,
    DailyChallengeLoader? dailyChallengeLoader,
    DailyChallengeSubmitter? dailyChallengeSubmitter,
    UserRefreshCallback? refreshCurrentUser,
  })  : _auraSummaryLoader = auraSummaryLoader ?? _defaultAuraSummaryLoader,
        _eligibleEventsLoader =
            eligibleEventsLoader ?? _defaultEligibleEventsLoader,
        _dailyChallengeLoader =
            dailyChallengeLoader ?? _defaultDailyChallengeLoader,
        _dailyChallengeSubmitter =
            dailyChallengeSubmitter ?? _defaultDailyChallengeSubmitter,
        _refreshCurrentUser =
            refreshCurrentUser ?? _defaultRefreshCurrentUser;

  final AuraSummaryLoader _auraSummaryLoader;
  final EligibleEventsLoader _eligibleEventsLoader;
  final DailyChallengeLoader _dailyChallengeLoader;
  final DailyChallengeSubmitter _dailyChallengeSubmitter;
  final UserRefreshCallback _refreshCurrentUser;
  AuraSummaryModel? _auraSummary;
  DailyChallengeModel? _dailyChallenge;
  List<EventAccessModel> _events = [];
  bool _isLoading = false;
  bool _isSubmittingChallenge = false;
  String? _error;

  AuraSummaryModel? get auraSummary => _auraSummary;
  DailyChallengeModel? get dailyChallenge => _dailyChallenge;
  List<EventAccessModel> get events => List.unmodifiable(_events);
  bool get isLoading => _isLoading;
  bool get isSubmittingChallenge => _isSubmittingChallenge;
  String? get error => _error;
  List<EventAccessModel> get unlockedEvents =>
      _events.where((event) => event.unlocked).toList();
  List<EventAccessModel> get lockedEvents =>
      _events.where((event) => event.locked).toList();

  static Future<AuraSummaryModel> _defaultAuraSummaryLoader() {
    return BackendApiService.instance.getAuraSummary();
  }

  static Future<List<EventAccessModel>> _defaultEligibleEventsLoader() {
    return BackendApiService.instance.getEligibleEvents();
  }

  static Future<DailyChallengeModel?> _defaultDailyChallengeLoader() {
    return BackendApiService.instance.getDailyChallenge();
  }

  static Future<Map<String, dynamic>> _defaultDailyChallengeSubmitter({
    required String submissionText,
    required String submissionLink,
  }) {
    return BackendApiService.instance.completeDailyChallenge(
      submissionText: submissionText,
      submissionLink: submissionLink,
    );
  }

  static Future<void> _defaultRefreshCurrentUser() {
    return AuthService.instance.refreshCurrentUser();
  }

  Future<void> fetchOverview({bool forceChallengeRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    AuraSummaryModel? nextSummary = _auraSummary;
    List<EventAccessModel> nextEvents = _events;
    DailyChallengeModel? nextChallenge = _dailyChallenge;
    String? nextError;

    try {
      nextSummary = await _auraSummaryLoader();
    } catch (e) {
      nextError = 'Failed to load aura data: $e';
    }

    try {
      nextEvents = await _eligibleEventsLoader();
    } catch (_) {
      nextEvents = _events;
    }

    try {
      nextChallenge = await _dailyChallengeLoader();
    } catch (_) {
      nextChallenge = _dailyChallenge;
    }

    try {
      _auraSummary = nextSummary;
      _events = nextEvents;
      _dailyChallenge = nextChallenge;
      _error = nextSummary == null ? nextError : null;
      await _refreshCurrentUser();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitDailyChallenge({
    required String submissionText,
    required String submissionLink,
  }) async {
    if (_isSubmittingChallenge) return false;

    final hasSubmission =
        submissionText.trim().isNotEmpty || submissionLink.trim().isNotEmpty;
    if (!hasSubmission) {
      _error = 'Add your solution text or a link before submitting.';
      notifyListeners();
      return false;
    }

    _isSubmittingChallenge = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _dailyChallengeSubmitter(
        submissionText: submissionText,
        submissionLink: submissionLink,
      );

      final completed = result['completed'] as bool?;
      final isCorrect = result['isCorrect'] as bool?;

      if (completed == false || isCorrect == false) {
        _error = 'Incorrect answer. Try again.';
        notifyListeners();
        return false;
      }

      await fetchOverview(forceChallengeRefresh: true);
      return true;
    } catch (e) {
      _error = 'Failed to submit challenge: $e';
      return false;
    } finally {
      _isSubmittingChallenge = false;
      notifyListeners();
    }
  }
}
