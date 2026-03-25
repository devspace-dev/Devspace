import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import 'user_avatar.dart';

class ComposeBox extends StatefulWidget {
  const ComposeBox({super.key});

  @override
  State<ComposeBox> createState() => _ComposeBoxState();
}

class _ComposeBoxState extends State<ComposeBox> {
  final _textCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  bool _expanded  = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final content = _textCtrl.text.trim();
    if (content.isEmpty) return;
    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final me = context.read<AuthProvider>().currentUser;
    context.read<PostsProvider>().addPost(me.id, content, tags);
    context.read<AuthProvider>().addAura(kAuraPost);

    _textCtrl.clear();
    _tagsCtrl.clear();
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(user: me, size: 44, showRing: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _expanded = true),
                  child: TextField(
                    controller: _textCtrl,
                    onTap: () => setState(() => _expanded = true),
                    onChanged: (_) => setState(() {}),
                    maxLines: _expanded ? 4 : 1,
                    style: const TextStyle(fontSize: 17, color: AppColors.text),
                    decoration: const InputDecoration(
                      hintText: 'What are you building today?',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      filled: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_expanded) ...[
                  const Divider(color: AppColors.border, height: 16),
                  TextField(
                    controller: _tagsCtrl,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.primary),
                    decoration: const InputDecoration(
                      hintText: 'Tags: React, Python, ML ...',
                      hintStyle: TextStyle(color: AppColors.text3, fontSize: 14),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      filled: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: ['📸', '🔗', '📊'].map((e) => Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Text(e,
                              style: const TextStyle(fontSize: 18, color: AppColors.text3)),
                        )).toList(),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              _textCtrl.clear();
                              _tagsCtrl.clear();
                              setState(() => _expanded = false);
                            },
                            child: const Text('Cancel',
                                style: TextStyle(color: AppColors.text3, fontSize: 13)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _textCtrl.text.trim().isNotEmpty ? _submit : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _textCtrl.text.trim().isNotEmpty
                                  ? AppColors.primary
                                  : AppColors.border2,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Post',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                        ],
                      ),
                    ],
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
