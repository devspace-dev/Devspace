import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/practice_questions.dart';

class PracticeProvider extends ChangeNotifier {
  static const String _completedKey = 'practice_completed_ids';

  final Set<String> _completedQuestionIds = {};
  int _selectedSectionIndex = 0;
  bool _isLoading = true;

  PracticeProvider() {
    _loadProgress();
  }

  Set<String> get completedQuestionIds => Set.unmodifiable(_completedQuestionIds);
  int get selectedSectionIndex => _selectedSectionIndex;
  bool get isLoading => _isLoading;

  int get totalCompletedCount => _completedQuestionIds.length;

  int get totalAuraEarned {
    int aura = 0;
    for (final id in _completedQuestionIds) {
      final question = practiceQuestionsData.firstWhere(
        (q) => q.id == id,
        orElse: () => practiceQuestionsData.first,
      );
      if (_completedQuestionIds.contains(question.id)) {
        final levelInfo = PracticeLevelData.levels.firstWhere(
          (l) => l['index'] == question.levelIndex,
          orElse: () => PracticeLevelData.levels.first,
        );
        aura += (levelInfo['auraPerQuestion'] as int? ?? 10);
      }
    }
    return aura;
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList(_completedKey);
      if (savedList != null) {
        _completedQuestionIds.addAll(savedList);
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
    } catch (e) {
      debugPrint('Error saving practice progress: $e');
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

  Future<bool> completeQuestion(String questionId) async {
    final bool isNewCompletion = !_completedQuestionIds.contains(questionId);
    if (isNewCompletion) {
      _completedQuestionIds.add(questionId);
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
    await _saveProgress();
    notifyListeners();
  }
}
