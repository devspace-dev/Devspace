import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/question_reply_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/questions_provider.dart';
import '../providers/users_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/question_card.dart';
import '../widgets/user_avatar.dart';

class QuestionDetailScreen extends StatefulWidget {
  final String questionId;

  const QuestionDetailScreen({
    super.key,
    required this.questionId,
  });

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  final TextEditingController _replyCtrl = TextEditingController();
  final TextEditingController _threadReplyCtrl = TextEditingController();
  String? _activeReplyComposerForId;
  String? _replyThreadParentId;
  String? _replyingToUserId;
  String? _replyingToHandle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final qp = context.read<QuestionsProvider>();
      final up = context.read<UsersProvider>();

      qp.fetchReplies(widget.questionId).then((_) {
        if (mounted) {
          final replies = qp.repliesForQuestion(widget.questionId);
          final userIds = replies.map((r) => r.userId).toList();
          up.fetchAndCacheUsers(userIds);
        }
      });

    });
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    _threadReplyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final questionsP = context.read<QuestionsProvider>();
    final authP = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await questionsP.addReply(
      questionId: widget.questionId,
      userId: authP.currentUser.id,
      content: _replyCtrl.text,
    );

    if (!mounted) return;

    if (!result.success) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.error ?? 'Failed to post reply.')),
      );
      return;
    }

    _replyCtrl.clear();
    messenger.showSnackBar(
      const SnackBar(content: Text('Reply posted.')),
    );

    final replies = questionsP.repliesForQuestion(widget.questionId);
    final userIds = replies.map((r) => r.userId).toList();
    context.read<UsersProvider>().fetchAndCacheUsers(userIds);
  }

  Future<void> _submitThreadReply() async {
    final parentReplyId = _replyThreadParentId;
    final replyingToUserId = _replyingToUserId;
    if (parentReplyId == null || replyingToUserId == null) return;

    final questionsP = context.read<QuestionsProvider>();
    final authP = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await questionsP.addReply(
      questionId: widget.questionId,
      userId: authP.currentUser.id,
      content: _threadReplyCtrl.text,
      parentReplyId: parentReplyId,
      replyingToUserId: replyingToUserId,
    );

    if (!mounted) return;

    if (!result.success) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.error ?? 'Failed to post reply.')),
      );
      return;
    }

    _clearInlineReplyComposer();
    messenger.showSnackBar(
      const SnackBar(content: Text('Reply posted.')),
    );

    final replies = questionsP.repliesForQuestion(widget.questionId);
    final userIds = replies.map((r) => r.userId).toList();
    context.read<UsersProvider>().fetchAndCacheUsers(userIds);
  }

  void _startReplyComposer({
    required QuestionReplyModel targetReply,
    required QuestionReplyModel parentReply,
    required UserModel? targetAuthor,
  }) {
    setState(() {
      _activeReplyComposerForId = targetReply.id;
      _replyThreadParentId = parentReply.id;
      _replyingToUserId = targetReply.userId;
      _replyingToHandle = targetAuthor?.handle ?? 'member';
      _threadReplyCtrl.clear();
    });
  }

  void _clearInlineReplyComposer() {
    setState(() {
      _activeReplyComposerForId = null;
      _replyThreadParentId = null;
      _replyingToUserId = null;
      _replyingToHandle = null;
      _threadReplyCtrl.clear();
    });
  }

  Future<void> _markSolved(QuestionReplyModel reply) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await context.read<QuestionsProvider>().markSolvedReply(
          questionId: widget.questionId,
          replyId: reply.id,
        );

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'Marked as solved.'
              : (result.error ?? 'Failed to mark solved reply.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionsP = context.watch<QuestionsProvider>();
    final usersP = context.watch<UsersProvider>();
    final currentUser = context.read<AuthProvider>().currentUser;
    final question = questionsP.getQuestionById(widget.questionId);

    if (question == null && questionsP.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgFor(context),
        body: AppLoadingState(
          title: 'Loading question',
          message: 'Pulling in the full thread and replies.',
        ),
      );
    }

    if (question == null) {
      return Scaffold(
        backgroundColor: AppColors.bgFor(context),
        appBar: AppBar(title: const Text('Question')),
        body: AppEmptyState(
          icon: Icons.help_outline_rounded,
          title: 'Question unavailable',
          message:
              'This question could not be found. It may have been removed or your data is out of date.',
          actionLabel: 'Refresh',
          onAction: () {
            questionsP.refreshQuestions();
          },
        ),
      );
    }

    final author = usersP.getUserById(question.userId);
    final allReplies = questionsP.repliesForQuestion(widget.questionId);
    final repliesById = {
      for (final reply in allReplies) reply.id: reply,
    };
    final topLevelReplies = _sortedTopLevelReplies(
      allReplies,
      question.solvedReplyId,
      repliesById,
    );
    final childRepliesByParent = _childRepliesByParent(allReplies, repliesById);
    final canMarkSolved =
        currentUser.id == question.userId && !question.isSolved;

    if (_activeReplyComposerForId != null &&
        !repliesById.containsKey(_activeReplyComposerForId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _clearInlineReplyComposer();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: AppBar(
        title: const Text('Question'),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.bg2For(context),
        onRefresh: () async {
          await questionsP.refreshQuestions();
          await questionsP.fetchReplies(widget.questionId, force: true);
        },
        child: ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 88,
          ),
          children: [
            QuestionCard(
              question: question,
              author: author,
              isDetail: true,
              isUpvoteUpdating: questionsP.isVoteUpdating(question.id),
              onUpvote: () async {
                final questionsProvider = context.read<QuestionsProvider>();
                final messenger = ScaffoldMessenger.of(context);
                final result = await questionsProvider.toggleUpvote(
                  questionId: question.id,
                  userId: currentUser.id,
                );
                if (!mounted || result.success || result.error == null) return;
                messenger.showSnackBar(
                  SnackBar(content: Text(result.error!)),
                );
              },
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.borderFor(context)),
                  bottom: BorderSide(color: AppColors.borderFor(context)),
                ),
                color: AppColors.bg2For(context),
              ),
              child: Row(
                children: [
                  Text(
                    '${allReplies.length} ${allReplies.length == 1 ? 'reply' : 'replies'}',
                    style: TextStyle(
                      color: AppColors.textFor(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (question.isSolved)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.solved.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.solved.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Text(
                        'Solved thread',
                        style: TextStyle(
                          color: AppColors.solved,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (questionsP.isReplyLoading(widget.questionId) &&
                topLevelReplies.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: AppLoadingState(
                  title: 'Loading replies',
                  message: 'Pulling in the latest help from the community.',
                ),
              )
            else if (questionsP.replyError(widget.questionId) != null &&
                topLevelReplies.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: AppErrorState(
                  title: 'Replies unavailable',
                  message: questionsP.replyError(widget.questionId)!,
                  actionLabel: 'Retry',
                  onAction: () {
                    questionsP.fetchReplies(widget.questionId, force: true);
                  },
                ),
              )
            else if (topLevelReplies.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: AppEmptyState(
                  icon: Icons.forum_outlined,
                  title: 'No replies yet',
                  message:
                      'Be the first to help with an answer, suggestion, or debugging direction.',
                ),
              )
            else
              ...topLevelReplies.expand((reply) {
                final replyAuthor = _replyAuthor(
                  usersP: usersP,
                  currentUser: currentUser,
                  userId: reply.userId,
                );
                final childReplies = childRepliesByParent[reply.id] ?? const [];
                final tiles = <Widget>[
                  _QuestionReplyTile(
                    reply: reply,
                    author: replyAuthor,
                    isSolved: reply.id == question.solvedReplyId,
                    canMarkSolved: canMarkSolved,
                    isMarkingSolved: questionsP.isSolveUpdating(question.id),
                    onMarkSolved: () => _markSolved(reply),
                    onReply: () => _startReplyComposer(
                          targetReply: reply,
                          parentReply: reply,
                          targetAuthor: replyAuthor,
                        ),
                  ),
                ];

                if (_activeReplyComposerForId == reply.id) {
                  tiles.add(
                    _InlineReplyComposer(
                      controller: _threadReplyCtrl,
                      replyingToHandle: _replyingToHandle ?? 'member',
                      submitting:
                          questionsP.isReplySubmitting(widget.questionId),
                      onCancel: _clearInlineReplyComposer,
                      onSubmit: _submitThreadReply,
                    ),
                  );
                }

                for (final childReply in childReplies) {
                  final childAuthor = _replyAuthor(
                    usersP: usersP,
                    currentUser: currentUser,
                    userId: childReply.userId,
                  );
                  final replyingToUser = childReply.replyingToUserId == null
                      ? null
                      : _replyAuthor(
                          usersP: usersP,
                          currentUser: currentUser,
                          userId: childReply.replyingToUserId!,
                        );

                  tiles.add(
                    Padding(
                      padding: const EdgeInsets.only(left: 52),
                      child: _QuestionReplyTile(
                        reply: childReply,
                        author: childAuthor,
                        replyingToHandle: replyingToUser?.handle,
                        onReply: () => _startReplyComposer(
                              targetReply: childReply,
                              parentReply: reply,
                              targetAuthor: childAuthor,
                            ),
                      ),
                    ),
                  );

                  if (_activeReplyComposerForId == childReply.id) {
                    tiles.add(
                      Padding(
                        padding: const EdgeInsets.only(left: 52),
                        child: _InlineReplyComposer(
                          controller: _threadReplyCtrl,
                          replyingToHandle: _replyingToHandle ?? 'member',
                          submitting:
                              questionsP.isReplySubmitting(widget.questionId),
                          onCancel: _clearInlineReplyComposer,
                          onSubmit: _submitThreadReply,
                        ),
                      ),
                    );
                  }
                }

                return tiles;
              }),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.bg2For(context),
            border: Border(top: BorderSide(color: AppColors.borderFor(context))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _replyCtrl,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(color: AppColors.textFor(context)),
                  decoration: const InputDecoration(
                    hintText:
                        'Reply with what worked, what you tried, or what to fix next...',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: questionsP.isReplySubmitting(widget.questionId)
                    ? null
                    : _submitReply,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(56, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: questionsP.isReplySubmitting(widget.questionId)
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<QuestionReplyModel> _sortedTopLevelReplies(
    List<QuestionReplyModel> replies,
    String? solvedReplyId,
    Map<String, QuestionReplyModel> repliesById,
  ) {
    final sorted = replies.where((reply) {
      if (reply.isTopLevel) return true;
      return !repliesById.containsKey(reply.parentReplyId);
    }).toList();

    sorted.sort((a, b) {
      if (solvedReplyId != null && solvedReplyId.isNotEmpty) {
        if (a.id == solvedReplyId) return -1;
        if (b.id == solvedReplyId) return 1;
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    return sorted;
  }

  Map<String, List<QuestionReplyModel>> _childRepliesByParent(
    List<QuestionReplyModel> replies,
    Map<String, QuestionReplyModel> repliesById,
  ) {
    final grouped = <String, List<QuestionReplyModel>>{};
    for (final reply in replies) {
      final parentReplyId = reply.parentReplyId;
      if (parentReplyId == null || parentReplyId.isEmpty) continue;
      if (!repliesById.containsKey(parentReplyId)) continue;
      grouped.putIfAbsent(parentReplyId, () => []).add(reply);
    }

    for (final threadReplies in grouped.values) {
      threadReplies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    return grouped;
  }

  UserModel? _replyAuthor({
    required UsersProvider usersP,
    required UserModel currentUser,
    required String userId,
  }) {
    final user = usersP.getUserById(userId);
    if (user != null) return user;
    if (currentUser.id == userId) return currentUser;
    return null;
  }
}

class _QuestionReplyTile extends StatelessWidget {
  final QuestionReplyModel reply;
  final UserModel? author;
  final bool isSolved;
  final bool canMarkSolved;
  final bool isMarkingSolved;
  final String? replyingToHandle;
  final VoidCallback? onMarkSolved;
  final VoidCallback? onReply;

  const _QuestionReplyTile({
    required this.reply,
    required this.author,
    this.isSolved = false,
    this.canMarkSolved = false,
    this.isMarkingSolved = false,
    this.replyingToHandle,
    this.onMarkSolved,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.borderFor(context);
    final surfaceColor = AppColors.bg3For(context);
    final titleColor = AppColors.textFor(context);
    final metaColor = AppColors.text3For(context);
    final bodyColor = AppColors.text2For(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
        color: isSolved
            ? AppColors.solved.withValues(alpha: 0.05)
            : Colors.transparent,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (author != null)
            UserAvatar(user: author!, size: reply.isTopLevel ? 38 : 34)
          else
            Container(
              width: reply.isTopLevel ? 38 : 34,
              height: reply.isTopLevel ? 38 : 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: surfaceColor,
                border: Border.all(color: borderColor),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 18,
                color: metaColor,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Text(
                            author?.name ?? 'DevSpace User',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: reply.isTopLevel ? 14 : 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (author != null)
                            Text(
                              '@${author!.handle}',
                              style: TextStyle(
                                color: metaColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          Text(
                            timeago.format(reply.createdAt),
                            style: TextStyle(
                              color: metaColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSolved)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.solved.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.solved.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          'Accepted',
                          style: TextStyle(
                            color: AppColors.solved,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                if (replyingToHandle != null &&
                    replyingToHandle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Replying to @$replyingToHandle',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  reply.content,
                  style: TextStyle(
                    color: bodyColor,
                    fontSize: reply.isTopLevel ? 14 : 13,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: onReply,
                      icon: const Icon(
                        Icons.reply_rounded,
                        size: 16,
                      ),
                      label: const Text('Reply'),
                      style: TextButton.styleFrom(
                        foregroundColor: metaColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 0,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    if (canMarkSolved && !isSolved && onMarkSolved != null)
                      OutlinedButton.icon(
                        onPressed: isMarkingSolved ? null : onMarkSolved,
                        icon: isMarkingSolved
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.solved,
                                ),
                              )
                            : const Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: AppColors.solved,
                              ),
                        label: const Text('Mark as Solution'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.solved,
                          side: BorderSide(
                            color: AppColors.solved.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineReplyComposer extends StatelessWidget {
  final TextEditingController controller;
  final String replyingToHandle;
  final bool submitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const _InlineReplyComposer({
    required this.controller,
    required this.replyingToHandle,
    required this.submitting,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppColors.bg2For(context);
    final borderColor = AppColors.borderFor(context);
    final textColor = AppColors.textFor(context);
    final mutedColor = AppColors.text3For(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.reply_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Replying to @$replyingToHandle',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            style: TextStyle(color: textColor, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Type your reply...',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: submitting ? null : onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: mutedColor,
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: submitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: submitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Reply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
