import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';

import '../models/question_model.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';
import '../widgets/user_avatar.dart';

class QuestionCard extends StatelessWidget {
  final QuestionModel question;
  final UserModel? author;
  final VoidCallback? onTap;
  final VoidCallback? onUpvote;
  final bool isUpvoteUpdating;
  final bool isDetail;

  const QuestionCard({
    super.key,
    required this.question,
    required this.author,
    this.onTap,
    this.onUpvote,
    this.isUpvoteUpdating = false,
    this.isDetail = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = Container(
      margin: isDetail ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: EdgeInsets.fromLTRB(20, isDetail ? 24 : 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: isDetail ? BorderRadius.zero : BorderRadius.circular(32),
        border: isDetail 
          ? const Border(bottom: BorderSide(color: AppColors.border, width: 2))
          : Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          if (!isDetail)
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QuestionAuthor(author: author),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            question.title,
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: isDetail ? 24 : 18,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                        if (question.isSolved) ...[
                          const SizedBox(width: 10),
                          _SolvedBadge(compact: !isDetail),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      question.body,
                      maxLines: isDetail ? null : 3,
                      overflow: isDetail ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.text2,
                        fontSize: 15,
                        height: 1.6,
                        fontWeight: isDetail ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    if (question.tags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: question.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bg3,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                color: AppColors.text2,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _QuestionStatButton(
                          icon: Icons.arrow_upward_rounded,
                          label: '${question.upvotesCount}',
                          active: question.isUpvoted,
                          loading: isUpvoteUpdating,
                          onTap: onUpvote,
                        ),
                        const SizedBox(width: 12),
                        _InfoPill(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: '${question.repliesCount} replies',
                          color: AppColors.mint,
                        ),
                        const Spacer(),
                        Text(
                          timeago.format(question.createdAt, locale: 'en_short'),
                          style: const TextStyle(
                            color: AppColors.text4,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (!isDetail && onTap != null) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: AppColors.text4,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);

    if (onTap == null) {
      return body;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: body,
    );
  }
}

class _QuestionAuthor extends StatelessWidget {
  final UserModel? author;

  const _QuestionAuthor({required this.author});

  @override
  Widget build(BuildContext context) {
    if (author == null) {
      return Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bg3,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.text3,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 64,
            child: Text(
              'User',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text3,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
    }

    final safeAuthor = author!;

    return Column(
      children: [
        UserAvatar(user: safeAuthor, size: 48, showRing: true),
        const SizedBox(height: 10),
        SizedBox(
          width: 80,
          child: Column(
            children: [
              Text(
                safeAuthor.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '@${safeAuthor.handle}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text3,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SolvedBadge extends StatelessWidget {
  final bool compact;

  const _SolvedBadge({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.solved.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: AppColors.solved.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: compact ? 14 : 16,
            color: AppColors.solved,
          ),
          const SizedBox(width: 6),
          Text(
            'Solved',
            style: TextStyle(
              color: AppColors.solved,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionStatButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool loading;
  final VoidCallback? onTap;

  const _QuestionStatButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.text2;
    
    return GestureDetector(
      onTap: loading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.bg3,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(
                    icon,
                    size: 16,
                    color: color,
                  ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.label,
    this.color = AppColors.text2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
