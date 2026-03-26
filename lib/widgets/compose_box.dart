import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import 'image_upload_widget.dart';
import 'user_avatar.dart';

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

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.warning ?? '+10 aura for sharing your build',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(user: me, size: 46, showRing: true),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _openComposer,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Share what you\'re building',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Post text, screenshots, or both.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.text3,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ComposerQuickAction(
                  icon: Icons.photo_library_outlined,
                  label: 'Photo',
                  onTap: _openComposer,
                ),
                const SizedBox(width: 8),
                _ComposerQuickAction(
                  icon: Icons.sell_outlined,
                  label: 'Add tags',
                  onTap: () => _openComposer(showTags: true),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _openComposer(),
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('Post'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.text,
                    backgroundColor: AppColors.bg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePostSheetResult {
  final bool posted;
  final String? warning;

  const _CreatePostSheetResult({
    required this.posted,
    this.warning,
  });
}

class _CreatePostSheet extends StatefulWidget {
  final bool showTagsInitially;

  const _CreatePostSheet({
    required this.showTagsInitially,
  });

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _textCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final List<String> _tags = [];

  bool _showTags = false;
  bool _posting = false;
  String? _submitError;
  File? _selectedImage;

  bool get _canPost => _textCtrl.text.trim().isNotEmpty || _selectedImage != null;

  @override
  void initState() {
    super.initState();
    _showTags = widget.showTagsInitially;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _handleTagInputChanged(String value) {
    if (!value.contains(',')) return;

    final segments = value.split(',');
    for (final segment in segments.take(segments.length - 1)) {
      _addTag(segment);
    }

    final pending = segments.last.trimLeft();
    _tagCtrl.value = TextEditingValue(
      text: pending,
      selection: TextSelection.collapsed(offset: pending.length),
    );
  }

  void _addTag(String rawTag) {
    final normalizedTag = rawTag.trim().replaceFirst(RegExp(r'^#+'), '');
    if (normalizedTag.isEmpty) return;

    final exists = _tags.any(
      (tag) => tag.toLowerCase() == normalizedTag.toLowerCase(),
    );
    if (exists) return;

    setState(() {
      _tags.add(normalizedTag);
    });
  }

  void _commitPendingTag() {
    final pending = _tagCtrl.text.trim();
    if (pending.isEmpty) return;
    _addTag(pending);
    _tagCtrl.clear();
  }

  Future<void> _submit() async {
    _commitPendingTag();

    if (!_canPost) {
      setState(() {
        _submitError = 'Add some text or attach an image to post.';
      });
      return;
    }

    setState(() {
      _posting = true;
      _submitError = null;
    });

    final me = context.read<AuthProvider>().currentUser;
    final result = await context.read<PostsProvider>().addPost(
          me.id,
          _textCtrl.text.trim(),
          _tags,
          imageFile: _selectedImage,
        );

    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _posting = false;
        _submitError = result.error;
      });
      return;
    }

    context.read<AuthProvider>().addAura(kAuraPost);

    Navigator.of(context).pop(
      _CreatePostSheetResult(
        posted: true,
        warning: result.warning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.88,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border2,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create post',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Text, image, or both. Keep it useful for other builders.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.text3,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _posting ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.text2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.border, height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.bg2,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your update',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  color: AppColors.text3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _textCtrl,
                                onChanged: (_) => setState(() {}),
                                autofocus: true,
                                minLines: 5,
                                maxLines: 10,
                                textCapitalization: TextCapitalization.sentences,
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: AppColors.text,
                                  height: 1.5,
                                ),
                                decoration: const InputDecoration(
                                  hintText:
                                      'Share a build update, screenshot, lesson, or something you are stuck on...',
                                  hintStyle: TextStyle(
                                    color: AppColors.text3,
                                    height: 1.5,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bg2,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Attachment',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  color: AppColors.text3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              PostImagePicker(
                                onPicked: (file) => setState(() => _selectedImage = file),
                                onCleared: () => setState(() => _selectedImage = null),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _selectedImage == null
                                    ? 'Add a screenshot or visual when it helps the update.'
                                    : 'Image attached. You can still post with or without text.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.text3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _ComposerQuickAction(
                              icon: Icons.sell_outlined,
                              label: _showTags ? 'Hide tags' : 'Add tags',
                              onTap: () {
                                setState(() {
                                  _showTags = !_showTags;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _StatusPill(
                              label: _canPost ? 'Ready to post' : 'Add text or image',
                              active: _canPost,
                            ),
                          ],
                        ),
                        if (_showTags) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.bg2,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tags',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                    color: AppColors.text3,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _tagCtrl,
                                  onChanged: _handleTagInputChanged,
                                  onSubmitted: (_) {
                                    setState(_commitPendingTag);
                                  },
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.text,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Add tags like Flutter, AI, Hackathon',
                                    hintStyle: const TextStyle(
                                      color: AppColors.text3,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.bg,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppColors.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppColors.primary),
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(_commitPendingTag),
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_tags.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _tags
                                        .map(
                                          (tag) => _TagChip(
                                            label: tag,
                                            onRemoved: () {
                                              setState(() {
                                                _tags.remove(tag);
                                              });
                                            },
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (_submitError != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.24),
                              ),
                            ),
                            child: Text(
                              _submitError!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  decoration: const BoxDecoration(
                    color: AppColors.bg,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _posting ? null : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.text2,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _posting || !_canPost ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _posting || !_canPost ? AppColors.border2 : AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _posting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Post',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ComposerQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.bg,
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusPill({
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.bg2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? AppColors.primary.withValues(alpha: 0.32)
              : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? AppColors.primary : AppColors.text3,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemoved;

  const _TagChip({
    required this.label,
    required this.onRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 7, bottom: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$label',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemoved,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
