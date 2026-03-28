import 'package:flutter/material.dart';

import '../models/aura_summary_model.dart';
import '../models/daily_challenge_model.dart';
import '../models/event_access_model.dart';
import '../services/auth_service.dart';
import '../services/backend_api_service.dart';

class EngagementProvider extends ChangeNotifier {
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

  Future<void> fetchOverview({bool forceChallengeRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        BackendApiService.instance.getAuraSummary(),
        BackendApiService.instance.getEligibleEvents(),
        BackendApiService.instance.getDailyChallenge(),
      ]);

      _auraSummary = results[0] as AuraSummaryModel;
      _events = results[1] as List<EventAccessModel>;
      _dailyChallenge = results[2] as DailyChallengeModel;
      _error = null;
      await AuthService.instance.refreshCurrentUser();
    } catch (e) {
      _error = 'Failed to load challenge and aura data: $e';
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
      await BackendApiService.instance.completeDailyChallenge(
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
}
