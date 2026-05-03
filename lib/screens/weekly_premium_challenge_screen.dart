import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/challenge_question.dart';
import '../models/career_goal.dart';
import '../providers/premium_provider.dart';
import '../services/challenge_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_ui_kit.dart';
import '../widgets/glass_container.dart';

class WeeklyPremiumChallengeScreen extends StatefulWidget {
  const WeeklyPremiumChallengeScreen({super.key});

  @override
  State<WeeklyPremiumChallengeScreen> createState() => _WeeklyPremiumChallengeScreenState();
}

class _WeeklyPremiumChallengeScreenState extends State<WeeklyPremiumChallengeScreen> {
  final ChallengeService _challengeService = ChallengeService();
  List<ChallengeQuestion> _questions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final questions = await _challengeService.getWeeklyQuestions();
      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load personalized questions. Please try again later.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumProvider>();
    final currentGoal = kCareerGoals.firstWhere(
      (g) => g.id == premium.careerGoal,
      orElse: () => kCareerGoals.first,
    );

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: AppBar(
        title: const Text('Premium Challenges'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadQuestions,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AppGradientBackground(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _error != null
            ? _buildErrorState()
            : _questions.isEmpty
              ? _buildEmptyState(currentGoal)
              : _buildQuestionsList(currentGoal),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.text2For(context)),
            ),
            const SizedBox(height: 24),
            AppButton(
              onPressed: _loadQuestions,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(CareerGoal goal) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(goal.icon, color: AppColors.primary, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'No questions for ${goal.title} yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textFor(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We are curating high-quality questions for your path. Check back soon!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.text3For(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsList(CareerGoal goal) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _questions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader(goal);
        }
        final question = _questions[index - 1];
        return _QuestionCard(question: question);
      },
    );
  }

  Widget _buildHeader(CareerGoal goal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(goal.icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '${goal.title.toUpperCase()} PATH',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Weekly Skill-up',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.textFor(context),
            ),
          ),
          Text(
            'Master these concepts to reach your dream role.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.text3For(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatefulWidget {
  final ChallengeQuestion question;
  const _QuestionCard({required this.question});

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DifficultyBadge(difficulty: widget.question.difficulty),
                Text(
                  widget.question.topic.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text3For(context),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.question.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textFor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.question.description,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.text2For(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.question.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bg3For(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text3For(context),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
            
            if (!_isExpanded)
              AppButton(
                onPressed: () => setState(() => _isExpanded = true),
                child: const Text('View Hint & Solution'),
              )
            else ...[
              const Divider(height: 32),
              if (widget.question.hint != null) ...[
                Text(
                  '💡 HINT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber.shade700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.question.hint!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.text2For(context),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (widget.question.solution != null) ...[
                Text(
                  '✅ SOLUTION / APPROACH',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.green.shade700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderFor(context)),
                  ),
                  child: Text(
                    widget.question.solution!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textFor(context),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isExpanded = false),
                child: const Text('Show Less'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;
  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = Colors.green;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'hard':
        color = Colors.redAccent;
        break;
      default:
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}
