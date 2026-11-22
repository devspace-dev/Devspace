import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/reward_feedback.dart';
import '../../../services/analytics_service.dart';
import '../models/tour_step.dart';

/// Central state machine orchestrating the Duolingo-style first-run tour.
class TourController extends ChangeNotifier {
  static TourController? _instance;
  static TourController get instance => _instance ??= TourController();

  TourStatus _status = TourStatus.notStarted;
  TourStep? _currentStep;
  final Set<TourStep> _completedSteps = {};
  bool _isPaused = false;
  bool _isNewUser = true;
  String? _userId;

  // External dependency getters for state-aware skipping
  bool Function()? hasActiveRoadmapGetter;
  int Function()? practiceCompletionsCountGetter;
  int Function()? postsCountGetter;
  bool Function()? hasEventsTabGetter;
  Future<void> Function(String roadmapId)? roadmapSelector;
  void Function(String route)? routeNavigator;

  // Testing overrides
  SharedPreferences? testPrefs;

  TourStatus get status => _status;
  TourStep? get currentStep => _currentStep;
  Set<TourStep> get completedSteps => Set.unmodifiable(_completedSteps);
  bool get isPaused => _isPaused;
  bool get isNewUser => _isNewUser;
  bool get isTourActive =>
      _status == TourStatus.inProgress && _currentStep != null && !_isPaused;

  /// Initializes tour state from SharedPreferences for [userId].
  Future<void> initForUser({
    required String userId,
    required bool isNewRegistration,
  }) async {
    _userId = userId;
    _isNewUser = isNewRegistration;

    try {
      final prefs = testPrefs ?? await SharedPreferences.getInstance();
      final statusStr = prefs.getString('tour_v1_${userId}_status');
      _status = TourStatus.fromString(statusStr);

      final stepStr = prefs.getString('tour_v1_${userId}_step');
      if (stepStr != null) {
        _currentStep = TourStep.values.firstWhere(
          (s) => s.name == stepStr,
          orElse: () => isNewRegistration ? TourStep.s1Welcome : TourStep.s1Welcome,
        );
      }

      final completedList = prefs.getStringList('tour_v1_${userId}_completed') ?? [];
      _completedSteps.clear();
      for (final s in completedList) {
        try {
          _completedSteps.add(TourStep.values.byName(s));
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('TourController init error: $e');
      _status = TourStatus.notStarted;
    }

    notifyListeners();
  }

  /// Starts the tour for the active user if not already completed or skipped.
  Future<void> checkAndStartTour() async {
    if (_status == TourStatus.completed || _status == TourStatus.skipped) {
      return;
    }

    _status = TourStatus.inProgress;
    _isPaused = false;
    _currentStep = _isNewUser ? TourStep.s1Welcome : TourStep.s1Welcome;

    _logAnalytics('tour_started', {
      'user_type': _isNewUser ? 'new' : 'existing',
    });

    _evaluateCurrentStepSkipping();
    notifyListeners();
    await _saveState();
  }

  /// Replays the tour from S1, resetting skipping rules.
  Future<void> replayTour() async {
    _status = TourStatus.inProgress;
    _isPaused = false;
    _completedSteps.clear();
    _currentStep = TourStep.s1Welcome;

    _logAnalytics('tour_started', {'replay': true});

    await _saveState();
    notifyListeners();
  }

  /// Advances to the next tour step in the appropriate sequence.
  Future<void> nextStep() async {
    if (_currentStep == null) return;

    _completedSteps.add(_currentStep!);
    final next = _determineNextStep(_currentStep!);

    if (next != null) {
      _currentStep = next;
      _logAnalytics('tour_step_viewed', {'step': next.name});
      _evaluateCurrentStepSkipping();
      _navigateForCurrentStep();
    } else {
      await completeTour();
      return;
    }

    notifyListeners();
    await _saveState();
  }

  /// Skips the entire tour.
  Future<void> skipTour() async {
    final prevStep = _currentStep;
    _status = TourStatus.skipped;
    _currentStep = null;
    _isPaused = false;

    _logAnalytics('tour_step_skipped', {
      'step_at_skip': prevStep?.name ?? 'unknown',
    });

    notifyListeners();
    await _saveState();
  }

  /// Marks the current step as skipped and advances to the next step (e.g. Android back button).
  Future<void> dismissCurrentStep() async {
    if (_currentStep == null) return;
    await nextStep();
  }

  /// Pauses the tour overlay (e.g. app backgrounded or modal opened).
  void pauseTour() {
    if (!_isPaused && isTourActive) {
      _isPaused = true;
      notifyListeners();
    }
  }

  /// Resumes the tour overlay if paused.
  void resumeTour() {
    if (_isPaused && _status == TourStatus.inProgress && _currentStep != null) {
      _isPaused = false;
      notifyListeners();
    }
  }

  /// Marks the tour as completed.
  Future<void> completeTour() async {
    _status = TourStatus.completed;
    _currentStep = null;
    _isPaused = false;

    _logAnalytics('tour_completed', {
      'completed_count': _completedSteps.length,
    });

    notifyListeners();
    await _saveState();
  }

  /// Handles user goal selection during S2.
  Future<void> selectGoal(String roadmapId) async {
    if (roadmapSelector != null) {
      try {
        await roadmapSelector!(roadmapId);
      } catch (e) {
        debugPrint('TourController selectGoal error: $e');
      }
    }
    await nextStep();
  }

  /// Called after a practice question submission is confirmed by the server RPC.
  /// Fires reward haptics and triggers the S7 celebration modal.
  void handlePracticeCompletionConfirmed() {
    if (_status == TourStatus.inProgress) {
      RewardFeedback.play(RewardKind.practice);
      _logAnalytics('first_aura_earned', {'amount': 5});
      _currentStep = TourStep.s7RewardModal;
      notifyListeners();
      _saveState();
    }
  }

  void _navigateForCurrentStep() {
    if (_currentStep == null || routeNavigator == null) return;
    switch (_currentStep!) {
      case TourStep.s3Play:
      case TourStep.s3bPlayExisting:
        routeNavigator!('/play');
        break;
      case TourStep.s4Community:
      case TourStep.s5Events:
        routeNavigator!('/community');
        break;
      case TourStep.s6Ranks:
        routeNavigator!('/ranks');
        break;
      default:
        break;
    }
  }

  TourStep? _determineNextStep(TourStep step) {
    if (_isNewUser) {
      switch (step) {
        case TourStep.s1Welcome:
          return TourStep.s2Goal;
        case TourStep.s2Goal:
          return TourStep.s3Play;
        case TourStep.s3Play:
        case TourStep.s3bPlayExisting:
        case TourStep.s7RewardModal:
          return TourStep.s4Community;
        case TourStep.s4Community:
          return TourStep.s5Events;
        case TourStep.s5Events:
          return TourStep.s6Ranks;
        case TourStep.s6Ranks:
          return null;
      }
    } else {
      // Shorter existing user tour: S1 (Upgrade) -> S3b (Play) -> S4 -> S5 -> S6
      switch (step) {
        case TourStep.s1Welcome:
          return TourStep.s3bPlayExisting;
        case TourStep.s3bPlayExisting:
        case TourStep.s3Play:
        case TourStep.s7RewardModal:
          return TourStep.s4Community;
        case TourStep.s4Community:
          return TourStep.s5Events;
        case TourStep.s5Events:
          return TourStep.s6Ranks;
        case TourStep.s2Goal:
        case TourStep.s6Ranks:
          return null;
      }
    }
  }

  void _evaluateCurrentStepSkipping() {
    if (_currentStep == null) return;

    bool shouldSkip = false;

    switch (_currentStep!) {
      case TourStep.s2Goal:
        // Skip if user already has an active roadmap
        if (hasActiveRoadmapGetter?.call() == true) {
          shouldSkip = true;
        }
        break;

      case TourStep.s3Play:
      case TourStep.s3bPlayExisting:
        // Skip if user already has completed at least 1 practice question
        if ((practiceCompletionsCountGetter?.call() ?? 0) >= 1) {
          shouldSkip = true;
        }
        break;

      case TourStep.s4Community:
        // Skip if user already has at least 1 post
        if ((postsCountGetter?.call() ?? 0) >= 1) {
          shouldSkip = true;
        }
        break;

      case TourStep.s5Events:
        // Skip if there is no Events tab
        if (hasEventsTabGetter?.call() == false) {
          shouldSkip = true;
        }
        break;

      default:
        break;
    }

    if (shouldSkip) {
      debugPrint('TourController: Silently skipping ${_currentStep!.name} (already satisfied/missing)');
      _completedSteps.add(_currentStep!);
      final next = _determineNextStep(_currentStep!);
      _currentStep = next;
      if (next != null) {
        _evaluateCurrentStepSkipping();
      } else {
        completeTour();
      }
    }
  }

  Future<void> _saveState() async {
    if (_userId == null) return;
    try {
      final prefs = testPrefs ?? await SharedPreferences.getInstance();
      await prefs.setString('tour_v1_${_userId}_status', _status.toDbString());
      if (_currentStep != null) {
        await prefs.setString('tour_v1_${_userId}_step', _currentStep!.name);
      } else {
        await prefs.remove('tour_v1_${_userId}_step');
      }
      await prefs.setStringList(
        'tour_v1_${_userId}_completed',
        _completedSteps.map((s) => s.name).toList(),
      );
    } catch (e) {
      debugPrint('TourController _saveState error: $e');
    }
  }

  void _logAnalytics(String event, Map<String, Object>? params) {
    try {
      AnalyticsService.instance.logEvent(event, params);
    } catch (_) {}
  }

  @visibleForTesting
  void resetForTest() {
    _status = TourStatus.notStarted;
    _currentStep = null;
    _completedSteps.clear();
    _isPaused = false;
    _isNewUser = true;
    _userId = null;
    hasActiveRoadmapGetter = null;
    practiceCompletionsCountGetter = null;
    postsCountGetter = null;
    hasEventsTabGetter = null;
    roadmapSelector = null;
    routeNavigator = null;
    testPrefs = null;
  }
}
