import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import '../services/storage_service.dart';
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

    if (!mounted || result == null) return;

    if (result.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message!)),
      );
    }

    if (!result.posted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post shared successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderFor(context), width: 0.5)),
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
                  color: AppColors.bg2For(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderFor(context), width: 0.5),
                ),
                child: Text(
                  'What\'s happening?',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.text3For(context),
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
  final String? message;

  const _CreatePostSheetResult({
    required this.posted,
    this.message,
  });
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
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      color: AppColors.bgFor(context),
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
                  child: Text('Cancel', style: TextStyle(color: AppColors.textFor(context))),
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
                            style: TextStyle(fontSize: 18, color: AppColors.textFor(context)),
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
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_selectedImage!, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 10,
                            top: 10,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImage = null),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags
                            .map(
                              (tag) => GestureDetector(
                                onTap: () => setState(() => _tags.remove(tag)),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Text(
                                    '#$tag  ×',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Divider(color: AppColors.borderFor(context)),
            Row(
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_outlined, color: AppColors.primary),
                ),
                IconButton(
                  onPressed: _editTags,
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

    if (!mounted) return;

    if (result.success) {
      Navigator.pop(
        context,
        _CreatePostSheetResult(
          posted: true,
          message: result.warning,
        ),
      );
      return;
    }

    setState(() => _posting = false);
    Navigator.pop(
      context,
      _CreatePostSheetResult(
        posted: false,
        message: result.error ?? 'Failed to publish post.',
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: GlassContainer(
          color: AppColors.bg2For(context),
          opacity: 0.98,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border2For(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: Text(
                  'Take a photo',
                  style: TextStyle(color: AppColors.textFor(context)),
                ),
                onTap: () => Navigator.pop(sheetContext, true),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: Text(
                  'Choose from gallery',
                  style: TextStyle(color: AppColors.textFor(context)),
                ),
                onTap: () => Navigator.pop(sheetContext, false),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final file = await StorageService.instance.pickImage(fromCamera: source);
    if (file == null || !mounted) return;
    setState(() => _selectedImage = file);
  }

  Future<void> _editTags() async {
    final controller = TextEditingController(text: _tags.join(', '));
    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.bg2For(context),
        title: Text(
          'Add hashtags',
          style: TextStyle(color: AppColors.textFor(context)),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppColors.textFor(context)),
          decoration: const InputDecoration(
            hintText: 'flutter, campus, ai',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final tags = controller.text
                  .split(',')
                  .map((tag) => tag.trim().replaceAll('#', ''))
                  .where((tag) => tag.isNotEmpty)
                  .toSet()
                  .toList();
              Navigator.pop(dialogContext, tags);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null || !mounted) return;
    setState(() {
      _tags
        ..clear()
        ..addAll(result);
    });
  }
}

