import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

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
      padding: EdgeInsets.fromLTRB(16, isDetail ? 18 : 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(
          bottom: BorderSide(
            color: isDetail ? Colors.transparent : AppColors.border,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QuestionAuthor(author: author),
              const SizedBox(width: 12),
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
                              fontSize: isDetail ? 22 : 17,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        if (question.isSolved) ...[
                          const SizedBox(width: 10),
                          _SolvedBadge(compact: !isDetail),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      question.body,
                      maxLines: isDetail ? null : 3,
                      overflow: isDetail ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text2,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                    if (question.tags.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: question.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bg2,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                color: AppColors.text2,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _QuestionStatButton(
                          icon: Icons.arrow_upward_rounded,
                          label: '${question.upvotesCount}',
                          active: question.isUpvoted,
                          loading: isUpvoteUpdating,
                          onTap: onUpvote,
                        ),
                        const SizedBox(width: 10),
                        _InfoPill(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: '${question.repliesCount} replies',
                        ),
                        const Spacer(),
                        Text(
                          timeago.format(question.createdAt),
                          style: const TextStyle(
                            color: AppColors.text3,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!isDetail && onTap != null) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
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
    );

    if (onTap == null) {
      return body;
    }

    return InkWell(
      onTap: onTap,
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bg3,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.text3,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 56,
            child: Text(
              'DevSpace User',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text3,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    final safeAuthor = author!;

    return Column(
      children: [
        UserAvatar(user: safeAuthor, size: 42),
        const SizedBox(height: 8),
        SizedBox(
          width: 72,
          child: Column(
            children: [
              Text(
                safeAuthor.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
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
                  fontWeight: FontWeight.w500,
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
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.solved.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.solved.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: compact ? 12 : 14,
            color: AppColors.solved,
          ),
          const SizedBox(width: 5),
          Text(
            'Solved',
            style: TextStyle(
              color: AppColors.solved,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
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
    return GestureDetector(
      onTap: loading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.bg2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(
                    icon,
                    size: 15,
                    color: active ? AppColors.primary : AppColors.text2,
                  ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.primary : AppColors.text2,
                fontSize: 12,
                fontWeight: FontWeight.w700,
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

  const _InfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.text2),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text2,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
