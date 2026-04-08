import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final borderColor = AppColors.borderFor(context);
    final titleColor = AppColors.textFor(context);
    final bodyColor = AppColors.text2For(context);
    final metaColor = AppColors.text3For(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: isDetail
              ? null
              : Border(bottom: BorderSide(color: borderColor, width: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (author != null) ...[
                  UserAvatar(user: author!, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    author!.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: bodyColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '• ${timeago.format(question.createdAt, locale: 'en_short')}',
                    style: TextStyle(fontSize: 13, color: metaColor),
                  ),
                ],
                const Spacer(),
                if (question.isSolved)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.solved,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              question.title,
              style: TextStyle(
                fontSize: isDetail ? 24 : 18,
                fontWeight: FontWeight.w700,
                color: titleColor,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              question.body,
              maxLines: isDetail ? null : 3,
              overflow:
                  isDetail ? TextOverflow.visible : TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                color: isDetail ? titleColor : bodyColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatItem(
                  icon: Icons.arrow_upward_rounded,
                  label: '${question.upvotesCount}',
                  active: question.isUpvoted,
                  onTap: onUpvote,
                ),
                const SizedBox(width: 16),
                _StatItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${question.repliesCount}',
                  active: false,
                ),
                const Spacer(),
                if (question.tags.isNotEmpty)
                  const Text(
                    '',
                  ),
                if (question.tags.isNotEmpty)
                  Text(
                    '#${question.tags.first}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.text3For(context);

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
