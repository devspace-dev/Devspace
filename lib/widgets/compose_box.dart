import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import '../theme/app_colors.dart';
import 'user_avatar.dart';
import 'glass_container.dart';

class ComposeBox extends StatefulWidget {
  const ComposeBox({super.key});

  @override
  State<ComposeBox> createState() => _ComposeBoxState();
}

class _ComposeBoxState extends State<ComposeBox> {
  Future<void> _openComposer({bool showTags = false}) async {
    final result = await showModalBottomSheet<_CreatePostSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePostSheet(showTagsInitially: showTags),
    );

    if (!mounted || result == null || !result.posted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post shared successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          UserAvatar(user: me, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _openComposer,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'What\'s happening?',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.text3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _openComposer(),
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _CreatePostSheetResult {
  final bool posted;
  const _CreatePostSheetResult({required this.posted});
}

class _CreatePostSheet extends StatefulWidget {
  final bool showTagsInitially;
  const _CreatePostSheet({required this.showTagsInitially});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _textCtrl = TextEditingController();
  final List<String> _tags = [];
  bool _posting = false;
  File? _selectedImage;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      color: AppColors.bg,
      opacity: 0.98,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.text)),
                ),
                ElevatedButton(
                  onPressed: _posting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Post', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserAvatar(user: context.read<AuthProvider>().currentUser, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _textCtrl,
                            maxLines: null,
                            autofocus: true,
                            style: const TextStyle(fontSize: 18),
                            decoration: const InputDecoration(
                              hintText: 'Share your progress...',
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(),
            Row(
              children: [
                IconButton(
                  onPressed: () {}, // Add image logic
                  icon: const Icon(Icons.photo_outlined, color: AppColors.primary),
                ),
                IconButton(
                  onPressed: () {}, // Add tag logic
                  icon: const Icon(Icons.tag_rounded, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty && _selectedImage == null) return;
    setState(() => _posting = true);
    final me = context.read<AuthProvider>().currentUser;
    final result = await context.read<PostsProvider>().addPost(
          me.id,
          text,
          _tags,
          imageFile: _selectedImage,
        );
    if (mounted && result.success) {
      Navigator.pop(context, const _CreatePostSheetResult(posted: true));
    }
  }
}
