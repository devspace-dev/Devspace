import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/question_model.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/user_avatar.dart';
import '../widgets/aura_pill.dart';

class QAScreen extends StatefulWidget {
  const QAScreen({super.key});
  @override
  State<QAScreen> createState() => _QAScreenState();
}

class _QAScreenState extends State<QAScreen> {
  final _uuid = const Uuid();
  List<QuestionModel> _questions = [
    QuestionModel(
      id: '1', userId: 3,
      title: 'How do I handle state management in Flutter for a complex app?',
      body: "I'm building a food delivery app and my widget tree is getting messy. Should I use Provider, Riverpod, or BLoC? Any real experience with these?",
      tags: ['Flutter', 'StateManagement', 'Dart'],
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      votes: 12, answerCount: 3,
    ),
    QuestionModel(
      id: '2', userId: 1,
      title: 'Best way to implement JWT refresh token rotation in Node.js?',
      body: 'Currently storing refresh tokens in httpOnly cookies. Should I keep a blacklist in Redis or use a rotating token family approach?',
      tags: ['NodeJS', 'JWT', 'Security'],
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      votes: 28, answerCount: 5, isSolved: true,
    ),
    QuestionModel(
      id: '3', userId: 4,
      title: 'How to structure a Vue 3 design system for reusability?',
      body: "Building a component library for college projects. Should I use Composition API throughout or mix with Options API for simpler components?",
      tags: ['Vue', 'DesignSystem', 'Components'],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      votes: 9, answerCount: 2,
    ),
  ];

  void _vote(String id, int dir) {
    setState(() {
      _questions = _questions.map((q) {
        if (q.id != id) return q;
        if (q.userVote == dir) {
          return q.copyWith(votes: q.votes - dir, userVote: null);
        }
        final undo = q.userVote ?? 0;
        return q.copyWith(votes: q.votes + dir - undo, userVote: dir);
      }).toList();
    });
  }

  void _showAskSheet() {
    final titleCtrl = TextEditingController();
    final bodyCtrl  = TextEditingController();
    final tagsCtrl  = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ask a Question',
                style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text)),
            const SizedBox(height: 18),
            _label('TITLE'),
            const SizedBox(height: 6),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: AppColors.text, fontSize: 15),
              decoration: const InputDecoration(
                hintText: "What's your question? Be specific.",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
            ),
            const SizedBox(height: 14),
            _label('DETAILS'),
            const SizedBox(height: 6),
            TextField(
              controller: bodyCtrl,
              maxLines: 4,
              style: const TextStyle(color: AppColors.text, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Describe your problem, what you tried, what you expected...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
            ),
            const SizedBox(height: 14),
            _label('TAGS'),
            const SizedBox(height: 6),
            TextField(
              controller: tagsCtrl,
              style: const TextStyle(color: AppColors.primary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'React, Python, Docker ...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.text3)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final me = context.read<AuthProvider>().currentUser;
                    setState(() {
                      _questions.insert(0, QuestionModel(
                        id: _uuid.v4(), userId: me.id,
                        title: titleCtrl.text.trim(),
                        body: bodyCtrl.text.trim(),
                        tags: tagsCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
                        createdAt: DateTime.now(),
                      ));
                    });
                    context.read<AuthProvider>().addAura(kAuraPost);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Post Question'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: AppColors.text3, letterSpacing: 0.8));

  @override
  Widget build(BuildContext context) {
    final usersP = context.read<UsersProvider>();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Q&A', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text)),
                    Text('Ask anything · help others · earn aura',
                        style: TextStyle(fontSize: 12, color: AppColors.text3)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAskSheet,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ask'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9)),
              ),
            ],
          ),
        ),

        // Aura incentive strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            border: Border(bottom: BorderSide(color: AppColors.primary.withOpacity(0.2))),
          ),
          child: Row(
            children: [
              const Text('⚡ ', style: TextStyle(fontSize: 14)),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(text: '+20 aura ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 12)),
                    TextSpan(text: 'when your answer is marked as solved!',
                        style: TextStyle(color: Color(0xFFA78BFA), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Questions list
        Expanded(
          child: ListView.builder(
            itemCount: _questions.length,
            itemBuilder: (context, i) {
              final q    = _questions[i];
              final user = usersP.getUserById(q.userId);
              if (user == null) return const SizedBox.shrink();

              return Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border))),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vote column
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () => _vote(q.id, 1),
                          child: Icon(Icons.arrow_drop_up_rounded,
                              size: 30,
                              color: q.userVote == 1 ? AppColors.primary : AppColors.text3),
                        ),
                        Text('${q.votes}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.text)),
                        GestureDetector(
                          onTap: () => _vote(q.id, -1),
                          child: Icon(Icons.arrow_drop_down_rounded,
                              size: 30,
                              color: q.userVote == -1 ? AppColors.like : AppColors.text3),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              UserAvatar(user: user, size: 26, showRing: true),
                              const SizedBox(width: 8),
                              Text(user.name,
                                  style: const TextStyle(
                                    fontSize: 13, color: AppColors.text3, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 4),
                              Text('· ${timeago.format(q.createdAt)}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.text3)),
                              const SizedBox(width: 6),
                              AuraPill(aura: user.aura, small: true),
                              if (q.isSolved) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.solved.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(color: AppColors.solved.withOpacity(0.3)),
                                  ),
                                  child: const Text('✓ Solved',
                                      style: TextStyle(
                                        fontSize: 10, color: AppColors.solved, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(q.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15,
                                color: AppColors.text, height: 1.4)),
                          const SizedBox(height: 6),
                          Text(
                            q.body.length > 120 ? '${q.body.substring(0, 120)}...' : q.body,
                            style: const TextStyle(
                              fontSize: 13, color: AppColors.text2, height: 1.6)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Wrap(
                                spacing: 8,
                                children: q.tags.map((t) => Text('#$t',
                                    style: const TextStyle(
                                      fontSize: 12, color: AppColors.primary,
                                      fontWeight: FontWeight.w500))).toList(),
                              ),
                              const Spacer(),
                              Icon(Icons.chat_bubble_outline_rounded,
                                  size: 14, color: AppColors.text3),
                              const SizedBox(width: 4),
                              Text('${q.answerCount}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.text3)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
