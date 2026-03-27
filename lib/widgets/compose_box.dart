import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(user: me, size: 50, showRing: true),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _openComposer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What are you building?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Share an update with the campus.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.text3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _ComposerQuickAction(
                  icon: Icons.photo_library_rounded,
                  label: 'Photo',
                  onTap: _openComposer,
                  color: AppColors.mint,
                ),
                const SizedBox(width: 10),
                _ComposerQuickAction(
                  icon: Icons.sell_rounded,
                  label: 'Tags',
                  onTap: () => _openComposer(showTags: true),
                  color: AppColors.yellow,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _openComposer(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Post'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.elasticOut),
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

  bool get _canPost =>
      PostsProvider.canCreatePost(_textCtrl.text, imageFile: _selectedImage);

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
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border2,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Post',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                                letterSpacing: -0.6,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Share your progress with the community.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.text3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _posting ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: AppColors.text2),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.border, height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.bg2,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: AppColors.border, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'THE UPDATE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: AppColors.text4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _textCtrl,
                                onChanged: (_) => setState(() {}),
                                autofocus: true,
                                minLines: 4,
                                maxLines: 12,
                                textCapitalization: TextCapitalization.sentences,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: AppColors.text,
                                  height: 1.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'What\'s happening in your lab?',
                                  hintStyle: TextStyle(color: AppColors.text4, fontWeight: FontWeight.w600),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  filled: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.bg2,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: AppColors.border, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ATTACHMENT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: AppColors.text4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              PostImagePicker(
                                onPicked: (file) => setState(() => _selectedImage = file),
                                onCleared: () => setState(() => _selectedImage = null),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _ComposerQuickAction(
                              icon: Icons.sell_rounded,
                              label: _showTags ? 'Hide Tags' : 'Add Tags',
                              color: AppColors.yellow,
                              onTap: () {
                                setState(() {
                                  _showTags = !_showTags;
                                });
                              },
                            ),
                          ],
                        ),
                        if (_showTags) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.bg2,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: AppColors.border, width: 2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TAGS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    color: AppColors.text4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _tagCtrl,
                                  onChanged: _handleTagInputChanged,
                                  onSubmitted: (_) {
                                    setState(_commitPendingTag);
                                  },
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    hintText: 'Flutter, AI, Web3...',
                                    hintStyle: const TextStyle(color: AppColors.text4),
                                    filled: true,
                                    fillColor: AppColors.bg,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppColors.border),
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(_commitPendingTag),
                                      icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                                    ),
                                  ),
                                ),
                                if (_tags.isNotEmpty) ...[
                                  const SizedBox(height: 16),
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
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              _submitError!,
                              style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  decoration: const BoxDecoration(
                    color: AppColors.bg,
                    border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _posting ? null : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _posting || !_canPost ? null : _submit,
                          child: _posting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                                )
                              : const Text('Post Now'),
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
  final Color color;

  const _ComposerQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
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
      padding: const EdgeInsets.only(left: 14, right: 8, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$label',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemoved,
            borderRadius: BorderRadius.circular(99),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
