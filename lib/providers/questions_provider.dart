import 'dart:async';

import 'package:flutter/material.dart';

import '../models/question_model.dart';
import '../models/question_reply_model.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class QuestionActionResult {
  final bool success;
  final String? error;

  const QuestionActionResult({
    required this.success,
    this.error,
  });
}

class QuestionsProvider extends ChangeNotifier {
  QuestionsProvider({List<QuestionModel>? initialQuestions}) {
    if (initialQuestions != null) {
      _questions = List.from(initialQuestions);
    }
  }

  List<QuestionModel> _questions = [];
  final Map<String, List<QuestionReplyModel>> _repliesByQuestion = {};
  final Map<String, bool> _replyLoading = {};
  final Map<String, bool> _replySubmitting = {};
  final Map<String, String?> _replyErrors = {};
  final Map<String, bool> _voteUpdating = {};
  final Map<String, String?> _voteErrors = {};
  final Map<String, bool> _solveUpdating = {};
  final Map<String, String?> _solveErrors = {};
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String _currentFilter = 'latest';
  static const int _pageSize = 20;

  List<QuestionModel> get questions => List.unmodifiable(_questions);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String get currentFilter => _currentFilter;

  void setFilter(String filter) {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    _questions = []; // Clear for visual feedback
    _hasMore = true;
    notifyListeners();
    fetchQuestions();
  }

  bool isReplyLoading(String questionId) => _replyLoading[questionId] ?? false;
  bool isReplySubmitting(String questionId) =>
      _replySubmitting[questionId] ?? false;
  String? replyError(String questionId) => _replyErrors[questionId];
  bool isVoteUpdating(String questionId) => _voteUpdating[questionId] ?? false;
  String? voteError(String questionId) => _voteErrors[questionId];
  bool isSolveUpdating(String questionId) =>
      _solveUpdating[questionId] ?? false;
  String? solveError(String questionId) => _solveErrors[questionId];

  QuestionModel? getQuestionById(String questionId) {
    try {
      return _questions.firstWhere((question) => question.id == questionId);
    } catch (_) {
      return null;
    }
  }

  List<QuestionReplyModel> repliesForQuestion(String questionId) {
    return List.unmodifiable(_repliesByQuestion[questionId] ?? const []);
  }

  Future<void> fetchQuestions() async {
    _isLoading = true;
    _error = null;
    _hasMore = true;
    notifyListeners();

    try {
      final page = await SupabaseService.instance.getQuestions(
        filter: _currentFilter,
        limit: _pageSize,
        offset: 0,
      );
      
      _questions = await _hydrateQuestions(page);
      _hasMore = page.length >= _pageSize;
      _error = null;
    } catch (e) {
      _error = 'Failed to load questions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshQuestions() => fetchQuestions();

  Future<void> loadMoreQuestions() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _error = null;
    notifyListeners();

    try {
      final page = await SupabaseService.instance.getQuestions(
        filter: _currentFilter,
        limit: _pageSize,
        offset: _questions.length,
      );

      if (page.isEmpty) {
        _hasMore = false;
        return;
      }

      final hydratedPage = await _hydrateQuestions(page);
      final existingIds = _questions.map((q) => q.id).toSet();
      _questions = [
        ..._questions,
        ...hydratedPage.where((q) => !existingIds.contains(q.id)),
      ];
      _hasMore = page.length >= _pageSize;
      _error = null;
    } catch (e) {
      _error = 'Failed to load more questions: $e';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<List<QuestionModel>> _hydrateQuestions(List<QuestionModel> questions) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) {
      return questions;
    }

    try {
      final upvotedIds = await SupabaseService.instance
          .getUpvotedQuestionIds(currentUser.id);
      return questions
          .map((question) => _mergeHydratedQuestion(question, upvotedIds))
          .toList();
    } catch (_) {
      return questions;
    }
  }

  Future<QuestionActionResult> addQuestion({
    required String userId,
    required String title,
    required String body,
    required List<String> tags,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedBody = body.trim();
    final normalizedTags = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();

    if (trimmedTitle.isEmpty) {
      return const QuestionActionResult(
        success: false,
        error: 'Title is required.',
      );
    }
    if (trimmedBody.isEmpty) {
      return const QuestionActionResult(
        success: false,
        error: 'Details are required.',
      );
    }

    try {
      await SupabaseService.instance.createQuestion(
        userId: userId,
        title: trimmedTitle,
        body: trimmedBody,
        tags: normalizedTags,
      );
      await refreshQuestions();
      return const QuestionActionResult(success: true);
    } catch (e) {
      return QuestionActionResult(
        success: false,
        error: 'Failed to post question: $e',
      );
    }
  }

  Future<void> fetchReplies(String questionId, {bool force = false}) async {
    if (_replyLoading[questionId] == true) return;
    if (!force && _repliesByQuestion.containsKey(questionId)) return;

    _replyLoading[questionId] = true;
    _replyErrors[questionId] = null;
    notifyListeners();

    try {
      final replies =
          await SupabaseService.instance.getRepliesForQuestion(questionId);
      _repliesByQuestion[questionId] = replies;
    } catch (e) {
      _replyErrors[questionId] = 'Failed to load replies: $e';
    } finally {
      _replyLoading[questionId] = false;
      notifyListeners();
    }
  }

  Future<QuestionActionResult> addReply({
    required String questionId,
    required String userId,
    required String content,
    String? parentReplyId,
    String? replyingToUserId,
  }) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      _replyErrors[questionId] = 'Reply cannot be empty.';
      notifyListeners();
      return const QuestionActionResult(success: false, error: 'Reply cannot be empty.');
    }

    _replySubmitting[questionId] = true;
    _replyErrors[questionId] = null;
    notifyListeners();

    try {
      await SupabaseService.instance.addQuestionReply(
        questionId: questionId,
        userId: userId,
        content: trimmedContent,
        parentReplyId: parentReplyId,
        replyingToUserId: replyingToUserId,
      );

      final replies =
          await SupabaseService.instance.getRepliesForQuestion(questionId);
      _repliesByQuestion[questionId] = replies;
      _questions = _questions.map((question) {
        if (question.id != questionId) return question;
        return question.copyWith(repliesCount: replies.length);
      }).toList();
      _replyErrors[questionId] = null;
      return const QuestionActionResult(success: true);
    } catch (e) {
      final error = 'Failed to post reply: $e';
      _replyErrors[questionId] = error;
      return QuestionActionResult(success: false, error: error);
    } finally {
      _replySubmitting[questionId] = false;
      notifyListeners();
    }
  }

  Future<QuestionActionResult> toggleUpvote({
    required String questionId,
    required String userId,
  }) async {
    if (_voteUpdating[questionId] == true) {
      return const QuestionActionResult(success: false);
    }

    final questionIndex =
        _questions.indexWhere((question) => question.id == questionId);
    if (questionIndex == -1) {
      return const QuestionActionResult(
        success: false,
        error: 'Question not found.',
      );
    }

    final question = _questions[questionIndex];
    final nextIsUpvoted = !question.isUpvoted;
    final nextUpvotes = nextIsUpvoted
        ? question.upvotesCount + 1
        : (question.upvotesCount > 0 ? question.upvotesCount - 1 : 0);

    _questions[questionIndex] = question.copyWith(
      isUpvoted: nextIsUpvoted,
      upvotesCount: nextUpvotes,
    );
    _voteUpdating[questionId] = true;
    _voteErrors[questionId] = null;
    notifyListeners();

    try {
      if (nextIsUpvoted) {
        await SupabaseService.instance.upvoteQuestion(questionId, userId);
      } else {
        await SupabaseService.instance.removeQuestionUpvote(questionId, userId);
      }
      await _refreshQuestionVoteState(questionId, userId);
      return const QuestionActionResult(success: true);
    } catch (e) {
      _questions[questionIndex] = question;
      final error = 'Failed to update upvote: $e';
      _voteErrors[questionId] = error;
      return QuestionActionResult(success: false, error: error);
    } finally {
      _voteUpdating[questionId] = false;
      notifyListeners();
    }
  }

  Future<QuestionActionResult> markSolvedReply({
    required String questionId,
    required String replyId,
  }) async {
    if (_solveUpdating[questionId] == true) {
      return const QuestionActionResult(success: false);
    }

    final question = getQuestionById(questionId);
    if (question == null) {
      return const QuestionActionResult(
        success: false,
        error: 'Question not found.',
      );
    }
    if (question.isSolved) {
      return const QuestionActionResult(
        success: false,
        error: 'This question is already solved.',
      );
    }

    _solveUpdating[questionId] = true;
    _solveErrors[questionId] = null;
    notifyListeners();

    try {
      await SupabaseService.instance.markSolvedReply(
        questionId: questionId,
        replyId: replyId,
      );
      final refreshedQuestion =
          await SupabaseService.instance.getQuestionById(questionId);
      if (refreshedQuestion != null) {
        final currentUser = AuthService.instance.currentUser;
        _questions = _questions.map((item) {
          if (item.id != questionId) return item;
          return refreshedQuestion.copyWith(
            isUpvoted: currentUser == null
                ? refreshedQuestion.isUpvoted
                : item.isUpvoted,
          );
        }).toList();
      }
      _solveErrors[questionId] = null;
      try {
        await SupabaseService.instance.syncMyBadges();
      } catch (_) {}
      return const QuestionActionResult(success: true);
    } catch (e) {
      final error = 'Failed to mark solved reply: $e';
      _solveErrors[questionId] = error;
      return QuestionActionResult(success: false, error: error);
    } finally {
      _solveUpdating[questionId] = false;
      notifyListeners();
    }
  }

  QuestionModel _mergeHydratedQuestion(
    QuestionModel hydratedQuestion,
    Set<String> upvotedIds,
  ) {
    final existingQuestion = getQuestionById(hydratedQuestion.id);
    if (existingQuestion == null) {
      return hydratedQuestion.copyWith(
        isUpvoted: upvotedIds.contains(hydratedQuestion.id),
      );
    }

    if (_voteUpdating[hydratedQuestion.id] == true) {
      return hydratedQuestion.copyWith(
        isUpvoted: existingQuestion.isUpvoted,
        upvotesCount: existingQuestion.upvotesCount,
      );
    }

    if (_solveUpdating[hydratedQuestion.id] == true) {
      return hydratedQuestion.copyWith(
        isUpvoted: upvotedIds.contains(hydratedQuestion.id),
        solvedReplyId: existingQuestion.solvedReplyId,
      );
    }

    return hydratedQuestion.copyWith(
      isUpvoted: upvotedIds.contains(hydratedQuestion.id),
    );
  }

  Future<void> _refreshQuestionVoteState(String questionId, String userId) async {
    final refreshedQuestion =
        await SupabaseService.instance.getQuestionById(questionId);
    if (refreshedQuestion == null) return;

    final upvotedIds =
        await SupabaseService.instance.getUpvotedQuestionIds(userId);
    _questions = _questions.map((question) {
      if (question.id != questionId) return question;
      return refreshedQuestion.copyWith(
        isUpvoted: upvotedIds.contains(questionId),
      );
    }).toList();
    _voteErrors[questionId] = null;
  }
}
