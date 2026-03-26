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
  final _textCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  bool _expanded = false;
  bool _posting = false;
  String? _submitError;
  File? _selectedImage;
  int _imagePickerVersion = 0;

  @override
  void dispose() {
    _textCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _textCtrl.text.trim();
    if (content.isEmpty) return;
    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    setState(() {
      _posting = true;
      _submitError = null;
    });

    final me = context.read<AuthProvider>().currentUser;
    final result = await context.read<PostsProvider>().addPost(
          me.id,
          content,
          tags,
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

    _textCtrl.clear();
    _tagsCtrl.clear();
    setState(() {
      _posting = false;
      _expanded = false;
      _selectedImage = null;
      _submitError = null;
      _imagePickerVersion += 1;
    });

    if (result.warning != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.warning!)),
      );
    }
  }

  void _cancelCompose() {
    _textCtrl.clear();
    _tagsCtrl.clear();
    setState(() {
      _expanded = false;
      _posting = false;
      _submitError = null;
      _selectedImage = null;
      _imagePickerVersion += 1;
    });
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
                  if (_submitError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 10),
                  PostImagePicker(
                    key: ValueKey(_imagePickerVersion),
                    onPicked: (file) => setState(() => _selectedImage = file),
                    onCleared: () => setState(() => _selectedImage = null),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedImage == null
                            ? 'Add one image if it helps explain the build.'
                            : 'Image attached',
                        style: const TextStyle(
                          color: AppColors.text3,
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _posting ? null : _cancelCompose,
                            child: const Text('Cancel',
                                style: TextStyle(color: AppColors.text3, fontSize: 13)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: !_posting && _textCtrl.text.trim().isNotEmpty
                                ? _submit
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !_posting &&
                                      _textCtrl.text.trim().isNotEmpty
                                  ? AppColors.primary
                                  : AppColors.border2,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                              minimumSize: Size.zero,
                            ),
                            child: _posting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Post',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    )),
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
