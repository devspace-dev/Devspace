import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

class PracticeProvider extends ChangeNotifier {
  static const String _completedKey = 'practice_completed_ids';
  static const String _syncedKey = 'practice_synced_ids';
  static const String _forfeitedAuraKey = 'practice_forfeited_aura_ids';

  final Set<String> _completedQuestionIds = {};
  final Set<String> _syncedQuestionIds = {};
  // Questions completed after at least one wrong attempt: aura for these is
  // permanently forfeited, even though the question itself still counts as
  // solved and unlocks the next one.
  final Set<String> _forfeitedAuraQuestionIds = {};
  int _selectedSectionIndex = 0;
  String _selectedTechStack = 'All';
  bool _isLoading = true;

  PracticeProvider() {
    _loadProgress();
  }

  Set<String> get completedQuestionIds => Set.unmodifiable(_completedQuestionIds);
  Set<String> get syncedQuestionIds => Set.unmodifiable(_syncedQuestionIds);
  int get selectedSectionIndex => _selectedSectionIndex;
  String get selectedTechStack => _selectedTechStack;
  bool get isLoading => _isLoading;

  int get totalCompletedCount => _completedQuestionIds.length;

  int getAuraForQuestion(String questionId) {
    if (questionId.startsWith('noob_')) return 5;  // Easy Level: +5 points
    if (questionId.startsWith('easy_')) return 10; // Medium Level: +10 points
    if (questionId.startsWith('med_')) return 15;  // Hard Level: +15 points
    if (questionId.startsWith('hard_')) return 20; // Ultra Level: +20 points
    return 5;
  }

  int get totalAuraEarned {
    int aura = 0;
    for (final id in _completedQuestionIds) {
      if (_forfeitedAuraQuestionIds.contains(id)) continue;
      aura += getAuraForQuestion(id);
    }
    return aura;
  }

  /// True once a question has been answered incorrectly at least once —
  /// aura for it is forfeited even after it's eventually solved.
  bool isAuraForfeited(String questionId) =>
      _forfeitedAuraQuestionIds.contains(questionId);

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCompleted = prefs.getStringList(_completedKey);
      if (savedCompleted != null) {
        _completedQuestionIds.addAll(savedCompleted);
      }
      final savedSynced = prefs.getStringList(_syncedKey);
      if (savedSynced != null) {
        _syncedQuestionIds.addAll(savedSynced);
      }
      final savedForfeited = prefs.getStringList(_forfeitedAuraKey);
      if (savedForfeited != null) {
        _forfeitedAuraQuestionIds.addAll(savedForfeited);
      }
    } catch (e) {
      debugPrint('Error loading practice progress: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_completedKey, _completedQuestionIds.toList());
      await prefs.setStringList(_syncedKey, _syncedQuestionIds.toList());
      await prefs.setStringList(_forfeitedAuraKey, _forfeitedAuraQuestionIds.toList());
    } catch (e) {
      debugPrint('Error saving practice progress: $e');
    }
  }

  /// Syncs any completed practice questions that haven't been credited to
  /// the user's server-side Aura yet (e.g. completed while offline). Calls
  /// the same server RPC completeQuestion uses, so the leaderboard actually
  /// reflects it — a purely local aura bump here would be lost the next
  /// time the user's real aura is fetched from the server.
  Future<void> syncUnsyncedQuestions(AuthProvider? authProvider) async {
    if (authProvider == null || authProvider.currentUserOrNull == null) return;

    final unsynced = _completedQuestionIds
        .where((id) => !_syncedQuestionIds.contains(id))
        .toList();
    if (unsynced.isEmpty) return;

    int? lastServerAura;
    for (final id in unsynced) {
      final auraReward =
          _forfeitedAuraQuestionIds.contains(id) ? 0 : getAuraForQuestion(id);
      final result = await SupabaseService.instance
          .submitPracticeCompletion(id, auraReward: auraReward);
      if (result == null) continue; // retry on the next sync pass
      _syncedQuestionIds.add(id);
      if (result['aura'] != null) {
        lastServerAura = (result['aura'] as num).toInt();
      }
    }

    if (lastServerAura != null) {
      authProvider.updateLocalAura(lastServerAura);
    }
    await _saveProgress();
    notifyListeners();
  }

  void setSelectedSection(int index) {
    if (index >= 0 && index < 4) {
      _selectedSectionIndex = index;
      notifyListeners();
    }
  }

  void setSelectedTechStack(String techStack) {
    if (_selectedTechStack != techStack) {
      _selectedTechStack = techStack;
      notifyListeners();
    }
  }

  bool isQuestionCompleted(String id) {
    return _completedQuestionIds.contains(id);
  }

  bool isSectionUnlocked(int levelIndex) {
    if (levelIndex == 0) return true; // Noob is always unlocked
    // Level X is unlocked if previous level's 20th question is completed
    final prevLevelLastQId = '${_getLevelPrefix(levelIndex - 1)}_20';
    return _completedQuestionIds.contains(prevLevelLastQId);
  }

  bool isQuestionUnlocked(int levelIndex, int questionNumber) {
    // Check if the section itself is unlocked
    if (!isSectionUnlocked(levelIndex)) return false;

    // First question of an unlocked level is always unlocked
    if (questionNumber == 1) return true;

    // Otherwise, previous question in the same level must be completed
    final prevQId = '${_getLevelPrefix(levelIndex)}_${questionNumber - 1}';
    return _completedQuestionIds.contains(prevQId);
  }

  String _getLevelPrefix(int levelIndex) {
    switch (levelIndex) {
      case 0:
        return 'noob';
      case 1:
        return 'easy';
      case 2:
        return 'med';
      case 3:
        return 'hard';
      default:
        return 'noob';
    }
  }

  /// Marks [questionId] solved. [awardAura] should be false when the user
  /// got it wrong at least once before answering correctly — the question
  /// still counts as completed (and unlocks the next one), but aura for it
  /// is forfeited for good: one chance at the points, unlimited chances at
  /// the question itself.
  Future<bool> completeQuestion(
    String questionId, {
    AuthProvider? authProvider,
    bool awardAura = true,
  }) async {
    final bool isNewCompletion = !_completedQuestionIds.contains(questionId);

    if (isNewCompletion && !awardAura) {
      _forfeitedAuraQuestionIds.add(questionId);
    }
    final bool isForfeited = _forfeitedAuraQuestionIds.contains(questionId);
    final int auraReward = isForfeited ? 0 : getAuraForQuestion(questionId);

    if (isNewCompletion) {
      _completedQuestionIds.add(questionId);
      await _saveProgress();

      if (authProvider != null && authProvider.currentUserOrNull != null) {
        _syncedQuestionIds.add(questionId);
        final result = await SupabaseService.instance
            .submitPracticeCompletion(questionId, auraReward: auraReward);
        if (result != null && result['aura'] != null) {
          final int serverAura = (result['aura'] as num).toInt();
          authProvider.updateLocalAura(serverAura);
        }
      }
      notifyListeners();
    } else if (!_syncedQuestionIds.contains(questionId) &&
        authProvider != null &&
        authProvider.currentUserOrNull != null) {
      _syncedQuestionIds.add(questionId);
      final result = await SupabaseService.instance
          .submitPracticeCompletion(questionId, auraReward: auraReward);
      if (result != null && result['aura'] != null) {
        final int serverAura = (result['aura'] as num).toInt();
        authProvider.updateLocalAura(serverAura);
      }
      await _saveProgress();
      notifyListeners();
    }
    return isNewCompletion;
  }

  int getCompletedCountForSection(int levelIndex) {
    final prefix = _getLevelPrefix(levelIndex);
    return _completedQuestionIds.where((id) => id.startsWith('${prefix}_')).length;
  }

  Future<void> resetProgress() async {
    _completedQuestionIds.clear();
    _syncedQuestionIds.clear();
    _forfeitedAuraQuestionIds.clear();
    await _saveProgress();
    notifyListeners();
  }
}

