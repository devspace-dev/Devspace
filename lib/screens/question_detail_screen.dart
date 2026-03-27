import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/question_reply_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/questions_provider.dart';
import '../providers/users_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<QuestionsProvider>().fetchReplies(widget.questionId);
    });
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
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

    authP.addAura(kAuraComment);
    _replyCtrl.clear();
    messenger.showSnackBar(
      const SnackBar(content: Text('+5 aura for helping another builder')),
    );
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
              ? 'Marked as solved. The reply author received +$kAuraAnswerAccepted aura.'
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
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: AppLoadingState(
          title: 'Loading question',
          message: 'Pulling in the full thread and replies.',
        ),
      );
    }

    if (question == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
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
    final replies = _sortedReplies(
      questionsP.repliesForQuestion(widget.questionId),
      question.solvedReplyId,
    );
    final canMarkSolved = currentUser.id == question.userId && !question.isSolved;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Question'),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.bg2,
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
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border),
                  bottom: BorderSide(color: AppColors.border),
                ),
                color: AppColors.bg2,
              ),
              child: Row(
                children: [
                  Text(
                    '${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                    style: const TextStyle(
                      color: AppColors.text,
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
            if (questionsP.isReplyLoading(widget.questionId) && replies.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: AppLoadingState(
                  title: 'Loading replies',
                  message: 'Pulling in the latest help from the community.',
                ),
              )
            else if (questionsP.replyError(widget.questionId) != null &&
                replies.isEmpty)
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
            else if (replies.isEmpty)
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
              ...replies.map((reply) {
                final replyAuthor = _replyAuthor(
                  usersP: usersP,
                  currentUser: currentUser,
                  userId: reply.userId,
                );
                final isSolvedReply = reply.id == question.solvedReplyId;
                return _QuestionReplyTile(
                  reply: reply,
                  author: replyAuthor,
                  isSolved: isSolvedReply,
                  canMarkSolved: canMarkSolved,
                  isMarkingSolved: questionsP.isSolveUpdating(question.id),
                  onMarkSolved: () => _markSolved(reply),
                );
              }),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.bg2,
            border: Border(top: BorderSide(color: AppColors.border)),
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
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(
                    hintText: 'Reply with what worked, what you tried, or what to fix next...',
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

  List<QuestionReplyModel> _sortedReplies(
    List<QuestionReplyModel> replies,
    String? solvedReplyId,
  ) {
    final sorted = List<QuestionReplyModel>.from(replies);
    sorted.sort((a, b) {
      if (solvedReplyId != null && solvedReplyId.isNotEmpty) {
        if (a.id == solvedReplyId) return -1;
        if (b.id == solvedReplyId) return 1;
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    return sorted;
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
  final VoidCallback onMarkSolved;

  const _QuestionReplyTile({
    required this.reply,
    required this.author,
    required this.isSolved,
    required this.canMarkSolved,
    required this.isMarkingSolved,
    required this.onMarkSolved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        border: const Border(bottom: BorderSide(color: AppColors.border)),
        color: isSolved
            ? AppColors.solved.withValues(alpha: 0.05)
            : Colors.transparent,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (author != null)
            UserAvatar(user: author!, size: 38)
          else
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bg3,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 18,
                color: AppColors.text3,
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
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (author != null)
                            Text(
                              '@${author!.handle}',
                              style: const TextStyle(
                                color: AppColors.text3,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          Text(
                            timeago.format(reply.createdAt),
                            style: const TextStyle(
                              color: AppColors.text3,
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
                const SizedBox(height: 10),
                Text(
                  reply.content,
                  style: const TextStyle(
                    color: AppColors.text2,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
                if (canMarkSolved && !isSolved) ...[
                  const SizedBox(height: 12),
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
                    label: const Text('Mark as solved'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.solved,
                      side: BorderSide(
                        color: AppColors.solved.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
