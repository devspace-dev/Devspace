import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/practice_questions.dart';
import 'auth_provider.dart';

class PracticeProvider extends ChangeNotifier {
  static const String _completedKey = 'practice_completed_ids';
  static const String _syncedKey = 'practice_synced_ids';

  final Set<String> _completedQuestionIds = {};
  final Set<String> _syncedQuestionIds = {};
  int _selectedSectionIndex = 0;
  bool _isLoading = true;

  PracticeProvider() {
    _loadProgress();
  }

  Set<String> get completedQuestionIds => Set.unmodifiable(_completedQuestionIds);
  Set<String> get syncedQuestionIds => Set.unmodifiable(_syncedQuestionIds);
  int get selectedSectionIndex => _selectedSectionIndex;
  bool get isLoading => _isLoading;

  int get totalCompletedCount => _completedQuestionIds.length;

  int getAuraForQuestion(String questionId) {
    try {
      final question = practiceQuestionsData.firstWhere(
        (q) => q.id == questionId,
        orElse: () => practiceQuestionsData.first,
      );
      final levelInfo = PracticeLevelData.levels.firstWhere(
        (l) => l['index'] == question.levelIndex,
        orElse: () => PracticeLevelData.levels.first,
      );
      return (levelInfo['auraPerQuestion'] as int? ?? 10);
    } catch (_) {
      return 10;
    }
  }

  int get totalAuraEarned {
    int aura = 0;
    for (final id in _completedQuestionIds) {
      aura += getAuraForQuestion(id);
    }
    return aura;
  }

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
    } catch (e) {
      debugPrint('Error saving practice progress: $e');
    }
  }

  /// Syncs any completed practice questions that haven't been credited to user's main Aura yet.
  Future<void> syncUnsyncedQuestions(AuthProvider? authProvider) async {
    if (authProvider == null || authProvider.currentUserOrNull == null) return;

    int totalToSync = 0;
    final List<String> newSynced = [];

    for (final id in _completedQuestionIds) {
      if (!_syncedQuestionIds.contains(id)) {
        totalToSync += getAuraForQuestion(id);
        newSynced.add(id);
      }
    }

    if (totalToSync > 0) {
      _syncedQuestionIds.addAll(newSynced);
      authProvider.addAura(totalToSync);
      await _saveProgress();
      notifyListeners();
    }
  }

  void setSelectedSection(int index) {
    if (index >= 0 && index < 4) {
      _selectedSectionIndex = index;
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

  Future<bool> completeQuestion(String questionId, {AuthProvider? authProvider}) async {
    final bool isNewCompletion = !_completedQuestionIds.contains(questionId);
    if (isNewCompletion) {
      _completedQuestionIds.add(questionId);

      final auraReward = getAuraForQuestion(questionId);
      if (authProvider != null && authProvider.currentUserOrNull != null) {
        _syncedQuestionIds.add(questionId);
        authProvider.addAura(auraReward);
      }

      await _saveProgress();
      notifyListeners();
    } else if (!_syncedQuestionIds.contains(questionId) &&
        authProvider != null &&
        authProvider.currentUserOrNull != null) {
      // Catch unsynced existing completion
      final auraReward = getAuraForQuestion(questionId);
      _syncedQuestionIds.add(questionId);
      authProvider.addAura(auraReward);
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
    await _saveProgress();
    notifyListeners();
  }
}

