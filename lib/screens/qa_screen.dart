import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/questions_provider.dart';
import '../providers/users_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/question_card.dart';
import '../widgets/skeleton_loaders.dart';
import 'question_detail_screen.dart';

class QAScreen extends StatefulWidget {
  const QAScreen({super.key});

  @override
  State<QAScreen> createState() => _QAScreenState();
}

class _QAScreenState extends State<QAScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final questionsP = context.read<QuestionsProvider>();
      if (questionsP.questions.isEmpty && !questionsP.isLoading) {
        _refreshQuestions();
      } else {
        final userIds = questionsP.questions.map((q) => q.userId).toList();
        context.read<UsersProvider>().fetchAndCacheUsers(userIds);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshQuestions() async {
    final questionsP = context.read<QuestionsProvider>();
    await questionsP.refreshQuestions();
    if (mounted) {
      final userIds = questionsP.questions.map((q) => q.userId).toList();
      await context.read<UsersProvider>().fetchAndCacheUsers(userIds);
    }
  }

  Future<void> _loadMoreQuestions() async {
    final questionsP = context.read<QuestionsProvider>();
    await questionsP.loadMoreQuestions();
    if (mounted) {
      final userIds = questionsP.questions.map((q) => q.userId).toList();
      await context.read<UsersProvider>().fetchAndCacheUsers(userIds);
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.position.pixels >= threshold) {
      _loadMoreQuestions();
    }
  }

  Future<void> _showAskSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg2For(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => const _AskQuestionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionsP = context.watch<QuestionsProvider>();
    final usersP = context.watch<UsersProvider>();
    final currentUser = context.read<AuthProvider>().currentUser;
    final questions = questionsP.questions;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: canPop
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Q&A',
                style: TextStyle(
                  color: AppColors.textFor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: _showAskSheet,
                  icon: const Icon(Icons.add_rounded),
                  color: AppColors.textFor(context),
                  tooltip: 'Ask a question',
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.bg2For(context),
        onRefresh: _refreshQuestions,
        edgeOffset: 0,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
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
                child: Text(
                  'Replies earn aura. Solved answers stay visible so the next student can learn faster.',
                  style: TextStyle(
                    color: AppColors.text2For(context),
                    fontSize: 11,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ask, solve, and leave answers that help the next builder.',
                        style: TextStyle(
                          color: AppColors.textFor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!canPop)
                      IconButton(
                        onPressed: _showAskSheet,
                        icon: const Icon(Icons.add_circle_rounded),
                        color: AppColors.primary,
                        tooltip: 'Ask a question',
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 0, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 20,
                      color: AppColors.text3For(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            'latest',
                            'relevance',
                            'popularity',
                            'most replies',
                            'oldest'
                          ].map((filter) {
                            final isSelected = questionsP.currentFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(
                                  filter == 'latest' ? 'Latest' :
                                  filter == 'relevance' ? 'Relevance' :
                                  filter == 'popularity' ? 'Popularity' :
                                  filter == 'most replies' ? 'Most Replies' : 'Oldest',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: isSelected ? Colors.white : AppColors.text2For(context),
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.bg2For(context),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primary : AppColors.borderFor(context),
                                  ),
                                ),
                                showCheckmark: false,
                                onSelected: (selected) {
                                  if (selected) {
                                    context.read<QuestionsProvider>().setFilter(filter);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (questionsP.error != null && questions.isNotEmpty)
              SliverToBoxAdapter(
                child: AppInlineError(
                  message: questionsP.error!,
                  onRetry: questionsP.refreshQuestions,
                ),
              ),
            if (questionsP.isLoading && questions.isEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => QuestionCardSkeleton(),
                  childCount: 5,
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
            if (questionsP.isLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              )
            else if (!questionsP.hasMore && questions.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No more questions.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.text3For(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _AskQuestionSheet extends StatefulWidget {
  const _AskQuestionSheet();

  @override
  State<_AskQuestionSheet> createState() => _AskQuestionSheetState();
}

class _AskQuestionSheetState extends State<_AskQuestionSheet> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _bodyCtrl = TextEditingController();
  final TextEditingController _tagsCtrl = TextEditingController();
  bool _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final result = await context.read<QuestionsProvider>().addQuestion(
          userId: context.read<AuthProvider>().currentUser.id,
          title: _titleCtrl.text,
          body: _bodyCtrl.text,
          tags: _tagsCtrl.text
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList(),
        );

    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _submitting = false;
        _submitError = result.error;
      });
      return;
    }

    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Question posted. Replies will now persist.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                  color: AppColors.border2For(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Ask a question',
                style: TextStyle(
                  color: AppColors.textFor(context),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Post the exact bug, doubt, architecture tradeoff, or tool choice you need help with.',
                style: TextStyle(
                  color: AppColors.text2For(context),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              const _SheetLabel('TITLE'),
              const SizedBox(height: 8),
              TextField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: AppColors.textFor(context)),
                decoration: const InputDecoration(
                  hintText: 'What exactly do you need help with?',
                ),
              ),
              const SizedBox(height: 16),
              const _SheetLabel('DETAILS'),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyCtrl,
                maxLines: 6,
                minLines: 5,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: AppColors.textFor(context)),
                decoration: const InputDecoration(
                  hintText:
                      'Share the context, what you tried, what failed, and what output or behavior you expected.',
                ),
              ),
              const SizedBox(height: 16),
              const _SheetLabel('TAGS'),
              const SizedBox(height: 8),
              TextField(
                controller: _tagsCtrl,
                style: TextStyle(color: AppColors.textFor(context)),
                decoration: const InputDecoration(
                  hintText: 'Flutter, Supabase, Docker',
                ),
              ),
              if (_submitError != null) ...[
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
                    _submitError!,
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
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
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
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;

  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.text3For(context),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}
