import 'package:flutter/material.dart';

import '../models/aura_summary_model.dart';
import '../models/daily_challenge_model.dart';
import '../models/event_access_model.dart';
import '../services/auth_service.dart';
import '../services/backend_api_service.dart';

typedef AuraSummaryLoader = Future<AuraSummaryModel> Function();
typedef EligibleEventsLoader = Future<List<EventAccessModel>> Function();
typedef DailyChallengeLoader = Future<DailyChallengeModel?> Function();
typedef WeeklyFreeChallengeLoader = Future<List<DailyChallengeModel>> Function({String? techStack});
typedef DailyChallengeSubmitter = Future<Map<String, dynamic>> Function({
  required String submissionText,
  required String submissionLink,
});
typedef WeeklyFreeChallengeSubmitter = Future<Map<String, dynamic>> Function({
  required String submissionText,
  required String submissionLink,
});
typedef UserRefreshCallback = Future<void> Function();

class _OverviewLoadResult<T> {
  final T? data;
  final Object? error;

  const _OverviewLoadResult._({this.data, this.error});

  bool get hasError => error != null;

  static Future<_OverviewLoadResult<T>> guard<T>(
    Future<T> Function() task,
  ) async {
    try {
      return _OverviewLoadResult._(data: await task());
    } catch (error) {
      return _OverviewLoadResult._(error: error);
    }
  }
}

class EngagementProvider extends ChangeNotifier {
  EngagementProvider({
    AuraSummaryLoader? auraSummaryLoader,
    EligibleEventsLoader? eligibleEventsLoader,
    DailyChallengeLoader? dailyChallengeLoader,
    WeeklyFreeChallengeLoader? weeklyFreeChallengeLoader,
    DailyChallengeSubmitter? dailyChallengeSubmitter,
    WeeklyFreeChallengeSubmitter? weeklyFreeChallengeSubmitter,
    UserRefreshCallback? refreshCurrentUser,
  })  : _auraSummaryLoader = auraSummaryLoader ?? _defaultAuraSummaryLoader,
        _eligibleEventsLoader =
            eligibleEventsLoader ?? _defaultEligibleEventsLoader,
        _dailyChallengeLoader =
            dailyChallengeLoader ?? _defaultDailyChallengeLoader,
        _weeklyFreeChallengeLoader =
            weeklyFreeChallengeLoader ?? _defaultWeeklyFreeChallengeLoader,
        _dailyChallengeSubmitter =
            dailyChallengeSubmitter ?? _defaultDailyChallengeSubmitter,
        _weeklyFreeChallengeSubmitter =
            weeklyFreeChallengeSubmitter ?? _defaultWeeklyFreeChallengeSubmitter,
        _refreshCurrentUser =
            refreshCurrentUser ?? _defaultRefreshCurrentUser;

  final AuraSummaryLoader _auraSummaryLoader;
  final EligibleEventsLoader _eligibleEventsLoader;
  final DailyChallengeLoader _dailyChallengeLoader;
  final WeeklyFreeChallengeLoader _weeklyFreeChallengeLoader;
  final DailyChallengeSubmitter _dailyChallengeSubmitter;
  final WeeklyFreeChallengeSubmitter _weeklyFreeChallengeSubmitter;
  final UserRefreshCallback _refreshCurrentUser;
  AuraSummaryModel? _auraSummary;
  DailyChallengeModel? _dailyChallenge;
  List<DailyChallengeModel> _weeklyFreeChallenges = [];
  List<EventAccessModel> _events = [];
  bool _isWeeklyChallengeEnrolled = false;
  bool _isLoading = false;
  bool _isSubmittingChallenge = false;
  bool _isEnrollingWeekly = false;
  String? _error;

  AuraSummaryModel? get auraSummary => _auraSummary;
  DailyChallengeModel? get dailyChallenge => _dailyChallenge;
  List<DailyChallengeModel> get weeklyFreeChallenges => List.unmodifiable(_weeklyFreeChallenges);
  DailyChallengeModel? get weeklyFreeChallenge => _weeklyFreeChallenges.isNotEmpty ? _weeklyFreeChallenges.first : null;
  List<EventAccessModel> get events => List.unmodifiable(_events);
  bool get isWeeklyChallengeEnrolled => _isWeeklyChallengeEnrolled;
  bool get isLoading => _isLoading;
  bool get isSubmittingChallenge => _isSubmittingChallenge;
  bool get isEnrollingWeekly => _isEnrollingWeekly;
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

  static Future<List<DailyChallengeModel>> _defaultWeeklyFreeChallengeLoader({String? techStack}) {
    return BackendApiService.instance.getWeeklyFreeChallenge(techStack: techStack);
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

  static Future<Map<String, dynamic>> _defaultWeeklyFreeChallengeSubmitter({
    required String submissionText,
    required String submissionLink,
  }) {
    return BackendApiService.instance.submitWeeklyFreeChallenge(
      submissionText: submissionText,
      submissionLink: submissionLink,
    );
  }

  static Future<void> _defaultRefreshCurrentUser() {
    return AuthService.instance.refreshCurrentUser();
  }

  Future<void> fetchOverview({bool forceChallengeRefresh = false, String? techStack}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final results = await Future.wait([
      _OverviewLoadResult.guard(_auraSummaryLoader),
      _OverviewLoadResult.guard(_eligibleEventsLoader),
      _OverviewLoadResult.guard(_dailyChallengeLoader),
      _OverviewLoadResult.guard(
        () => _weeklyFreeChallengeLoader(techStack: techStack),
      ),
    ]);

    final auraResult = results[0] as _OverviewLoadResult<AuraSummaryModel>;
    final eventsResult =
        results[1] as _OverviewLoadResult<List<EventAccessModel>>;
    final challengeResult =
        results[2] as _OverviewLoadResult<DailyChallengeModel?>;
    final weeklyResult =
        results[3] as _OverviewLoadResult<List<DailyChallengeModel>>;

    final failures = <Object>[];

    if (auraResult.data != null) {
      _auraSummary = auraResult.data;
    } else if (auraResult.hasError) {
      failures.add(auraResult.error!);
    }

    if (eventsResult.data != null) {
      _events = eventsResult.data!;
    } else if (eventsResult.hasError) {
      failures.add(eventsResult.error!);
    }

    if (!challengeResult.hasError) {
      _dailyChallenge = challengeResult.data;
    } else {
      failures.add(challengeResult.error!);
    }

    if (weeklyResult.data != null) {
      _weeklyFreeChallenges = weeklyResult.data!;
    } else if (weeklyResult.hasError) {
      failures.add(weeklyResult.error!);
    }

    for (final failure in failures) {
      debugPrint('Error loading engagement data: $failure');
    }

    final hasAnyOverviewData = _auraSummary != null ||
        _dailyChallenge != null ||
        _events.isNotEmpty ||
        _weeklyFreeChallenges.isNotEmpty;

    _error = failures.isEmpty
        ? null
        : hasAnyOverviewData
            ? 'Some engagement sections could not refresh. Pull to retry.'
            : 'Failed to refresh engagement data. Please try again.';

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitDailyChallenge({
    required String submissionText,
    required String submissionLink,
  }) async {
    if (_isSubmittingChallenge) return false;

    if (submissionText.trim().isEmpty) {
      _error = 'Select one answer before submitting.';
      notifyListeners();
      return false;
    }

    _isSubmittingChallenge = true;
    _error = null;
    notifyListeners();

    try {
      await _dailyChallengeSubmitter(
        submissionText: submissionText,
        submissionLink: submissionLink,
      );

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

  Future<bool> submitWeeklyFreeChallenge({
    required String submissionText,
    required String submissionLink,
  }) async {
    if (_isSubmittingChallenge) return false;

    if (submissionText.trim().isEmpty) {
      _error = 'Select one answer before submitting.';
      notifyListeners();
      return false;
    }

    _isSubmittingChallenge = true;
    _error = null;
    notifyListeners();

    try {
      await _weeklyFreeChallengeSubmitter(
        submissionText: submissionText,
        submissionLink: submissionLink,
      );

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

  Future<bool> enrollInWeeklyChallenge() async {
    if (_isEnrollingWeekly || _isWeeklyChallengeEnrolled) return false;

    _isEnrollingWeekly = true;
    _error = null;
    notifyListeners();

    try {
      // Mocking enrollment for now
      await Future.delayed(const Duration(seconds: 1));
      _isWeeklyChallengeEnrolled = true;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to enroll: $e';
      return false;
    } finally {
      _isEnrollingWeekly = false;
      notifyListeners();
    }
  }
}
