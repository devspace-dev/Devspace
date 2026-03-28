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
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderFor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              UserAvatar(user: me, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _openComposer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgFor(context),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.borderFor(context).withValues(alpha: 0.8),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share your build progress',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textFor(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Post an update, doubt, demo link, or what you shipped today.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: AppColors.text3For(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ComposeAction(
                  icon: Icons.edit_rounded,
                  label: 'Write post',
                  onTap: _openComposer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ComposeAction(
                  icon: Icons.photo_library_outlined,
                  label: 'Add image',
                  onTap: () => _openComposer(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ComposeAction(
                  icon: Icons.sell_outlined,
                  label: 'Add tags',
                  onTap: () => _openComposer(showTags: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposeAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ComposeAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgFor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderFor(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text2For(context),
                ),
              ),
            ),
          ],
        ),
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

