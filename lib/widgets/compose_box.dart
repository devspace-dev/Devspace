import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
    HapticFeedback.lightImpact();
    final result = await showModalBottomSheet<_CreatePostSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePostSheet(showTagsInitially: showTags),
    );

    if (!mounted || result == null) return;

    if (result.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message!), behavior: SnackBarBehavior.floating),
      );
    }

    if (!result.posted) return;

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post shared successfully'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgFor(context),
        border: Border(bottom: BorderSide(color: AppColors.borderFor(context).withValues(alpha: 0.5), width: 0.5)),
      ),
      child: Row(
        children: [
          UserAvatar(user: me, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _openComposer,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bg2For(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderFor(context).withValues(alpha: 0.8), width: 0.8),
                ),
                child: Text(
                  'What\'s happening?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text3For(context),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _openComposer(),
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 26),
            ),
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
  int _charCount = 0;
  static const int _maxChars = 280;

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(() {
      setState(() => _charCount = _textCtrl.text.length);
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().currentUser;
    final isOverLimit = _charCount > _maxChars;

    return GlassContainer(
      color: AppColors.bgFor(context),
      opacity: 0.98,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textFor(context), fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: (_posting || (isOverLimit)) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _posting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Post', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
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
                        UserAvatar(user: me, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              TextField(
                                controller: _textCtrl,
                                maxLines: null,
                                autofocus: true,
                                style: GoogleFonts.plusJakartaSans(fontSize: 18, color: AppColors.textFor(context), height: 1.5),
                                decoration: const InputDecoration(
                                  hintText: 'Share your build journey...',
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$_charCount / $_maxChars',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isOverLimit ? AppColors.flame : AppColors.text3For(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 20),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                          ),
                          Positioned(
                            right: 12,
                            top: 12,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedImage = null);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 10,
                          children: _tags
                              .map(
                                (tag) => GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _tags.remove(tag));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '#$tag',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderFor(context).withValues(alpha: 0.5))),
              ),
              child: Row(
                children: [
                  _ToolbarIcon(
                    icon: Icons.photo_library_outlined,
                    onTap: _pickImage,
                  ),
                  _ToolbarIcon(
                    icon: Icons.tag_rounded,
                    onTap: _editTags,
                  ),
                  const Spacer(),
                  if (_posting)
                     Text(
                      'Uploading...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty && _selectedImage == null) return;
    
    HapticFeedback.mediumImpact();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.error ?? 'Failed to publish post.'), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    final source = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: GlassContainer(
          color: AppColors.bg2For(context),
          opacity: 0.98,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border2For(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: Text(
                  'Take a photo',
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textFor(context), fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(sheetContext, true),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: Text(
                  'Choose from gallery',
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textFor(context), fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(sheetContext, false),
              ),
              const SizedBox(height: 12),
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
    HapticFeedback.lightImpact();
    final controller = TextEditingController(text: _tags.join(', '));
    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.bg2For(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add hashtags',
          style: GoogleFonts.plusJakartaSans(color: AppColors.textFor(context), fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.plusJakartaSans(color: AppColors.textFor(context)),
          decoration: InputDecoration(
            hintText: 'flutter, mnit, dev',
            hintStyle: TextStyle(color: AppColors.text3For(context)),
            filled: true,
            fillColor: AppColors.bg3For(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.text3For(context))),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Add', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
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

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ToolbarIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
    );
  }
}


