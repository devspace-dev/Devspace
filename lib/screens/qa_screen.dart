import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/questions_provider.dart';
import '../providers/users_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/question_card.dart';
import 'question_detail_screen.dart';

class QAScreen extends StatefulWidget {
  const QAScreen({super.key});

  @override
  State<QAScreen> createState() => _QAScreenState();
}

class _QAScreenState extends State<QAScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final questionsP = context.read<QuestionsProvider>();
      if (questionsP.questions.isEmpty && !questionsP.isLoading) {
        questionsP.fetchQuestions();
      }
    });
  }

  Future<void> _showAskSheet() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();
    final questionsP = context.read<QuestionsProvider>();
    final authP = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        bool submitting = false;
        String? submitError;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              final navigator = Navigator.of(sheetContext);
              setSheetState(() {
                submitting = true;
                submitError = null;
              });

              final result = await questionsP.addQuestion(
                userId: authP.currentUser.id,
                title: titleCtrl.text,
                body: bodyCtrl.text,
                tags: tagsCtrl.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList(),
              );

              if (!mounted) return;

              if (!result.success) {
                setSheetState(() {
                  submitting = false;
                  submitError = result.error;
                });
                return;
              }

              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Question posted. Replies will now persist.'),
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 18,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border2,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Ask a question',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Post the exact bug, doubt, architecture tradeoff, or tool choice you need help with.',
                        style: TextStyle(
                          color: AppColors.text2,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _SheetLabel('TITLE'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(color: AppColors.text),
                        decoration: const InputDecoration(
                          hintText: 'What exactly do you need help with?',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _SheetLabel('DETAILS'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: bodyCtrl,
                        maxLines: 6,
                        minLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(color: AppColors.text),
                        decoration: const InputDecoration(
                          hintText:
                              'Share the context, what you tried, what failed, and what output or behavior you expected.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _SheetLabel('TAGS'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: tagsCtrl,
                        style: const TextStyle(color: AppColors.text),
                        decoration: const InputDecoration(
                          hintText: 'Flutter, Supabase, Docker',
                        ),
                      ),
                      if (submitError != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Text(
                            submitError!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: submitting
                                  ? null
                                  : () => Navigator.pop(sheetContext),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: submitting ? null : submit,
                              child: submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Post question'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    bodyCtrl.dispose();
    tagsCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questionsP = context.watch<QuestionsProvider>();
    final usersP = context.watch<UsersProvider>();
    final currentUser = context.read<AuthProvider>().currentUser;
    final questions = questionsP.questions;
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.bg2,
      onRefresh: questionsP.refreshQuestions,
      edgeOffset: topInset,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: topInset,
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Q&A',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Ask practical doubts, get real replies, and close loops with solved answers.',
                          style: TextStyle(
                            color: AppColors.text3,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAskSheet,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Ask'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
              ),
              child: const Text(
                'Replies earn aura. Solved answers stay visible so the next student can learn faster.',
                style: TextStyle(
                  color: AppColors.text2,
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (questionsP.error != null && questions.isNotEmpty)
            SliverToBoxAdapter(
              child: _InlineWarningBanner(
                message: questionsP.error!,
                onRetry: questionsP.refreshQuestions,
              ),
            ),
          if (questionsP.isLoading && questions.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: AppLoadingState(
                title: 'Loading questions',
                message: 'Pulling in the latest doubts and solutions from your community.',
              ),
            )
          else if (questionsP.error != null && questions.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: AppErrorState(
                title: 'Q&A unavailable',
                message: questionsP.error!,
                actionLabel: 'Retry',
                onAction: questionsP.refreshQuestions,
              ),
            )
          else if (questions.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: AppEmptyState(
                icon: Icons.help_center_outlined,
                title: 'No questions yet',
                message:
                    'Start the first useful thread for your college by posting a real doubt or technical decision.',
                actionLabel: 'Ask question',
                onAction: _showAskSheet,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final question = questions[index];
                  final author = usersP.getUserById(question.userId) ??
                      (currentUser.id == question.userId ? currentUser : null);
                  return QuestionCard(
                    question: question,
                    author: author,
                    isUpvoteUpdating: questionsP.isVoteUpdating(question.id),
                    onUpvote: () async {
                      final questionsProvider = context.read<QuestionsProvider>();
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await questionsProvider.toggleUpvote(
                        questionId: question.id,
                        userId: currentUser.id,
                      );
                      if (!mounted || result.success || result.error == null) {
                        return;
                      }
                      messenger.showSnackBar(
                        SnackBar(content: Text(result.error!)),
                      );
                    },
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QuestionDetailScreen(
                            questionId: question.id,
                          ),
                        ),
                      );
                    },
                  );
                },
                childCount: questions.length,
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;

  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.text3,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InlineWarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineWarningBanner({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.text2,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
