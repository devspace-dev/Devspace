import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class ImageUploadWidget extends StatefulWidget {
  final String? existingUrl;
  final String uploadPath;
  final double size;
  final bool isCircle;
  final void Function(String url) onUploaded;

  const ImageUploadWidget({
    super.key,
    this.existingUrl,
    required this.uploadPath,
    required this.onUploaded,
    this.size = 80,
    this.isCircle = false,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  File? _localFile;
  double? _progress;
  bool _uploading = false;

  Future<void> _pick({required bool fromCamera}) async {
    final file = await StorageService.instance.pickImage(fromCamera: fromCamera);
    if (file == null || !mounted) return;

    setState(() {
      _localFile = file;
      _uploading = true;
      _progress = 0;
    });

    try {
      final url = await StorageService.instance.uploadWithProgress(
        widget.uploadPath,
        file,
        onProgress: (p) => setState(() => _progress = p),
      );
      widget.onUploaded(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _progress = null;
        });
      }
    }
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg2For(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border2For(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: Text(
                'Take a photo',
                style: TextStyle(color: AppColors.textFor(context)),
              ),
              onTap: () {
                Navigator.pop(context);
                _pick(fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: Text(
                'Choose from gallery',
                style: TextStyle(color: AppColors.textFor(context)),
              ),
              onTap: () {
                Navigator.pop(context);
                _pick(fromCamera: false);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.isCircle
        ? BorderRadius.circular(widget.size)
        : BorderRadius.circular(12);

    Widget imageContent;

    if (_localFile != null) {
      imageContent = Image.file(
        _localFile!,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
      );
    } else if (widget.existingUrl != null && widget.existingUrl!.isNotEmpty) {
      imageContent = CachedNetworkImage(
        imageUrl: StorageService.instance.resolvePublicUrl(widget.existingUrl!),
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
        placeholder: (_, __) => Container(color: AppColors.bg3For(context)),
        errorWidget: (_, __, ___) => _placeholder(context),
      );
    } else {
      imageContent = _placeholder(context);
    }

    return GestureDetector(
      onTap: _showPicker,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              imageContent,
              if (_uploading)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          value: _progress,
                          color: AppColors.primary,
                          strokeWidth: 2.5,
                        ),
                        if (_progress != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '${(_progress! * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              if (!_uploading)
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.bgFor(context),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      color: AppColors.bg3For(context),
      child: Icon(
        Icons.add_photo_alternate_outlined,
        color: AppColors.text3For(context),
        size: widget.size * 0.3,
      ),
    );
  }
}

class PostImagePicker extends StatefulWidget {
  final void Function(File file) onPicked;
  final VoidCallback? onCleared;

  const PostImagePicker({
    super.key,
    required this.onPicked,
    this.onCleared,
  });

  @override
  State<PostImagePicker> createState() => _PostImagePickerState();
}

class _PostImagePickerState extends State<PostImagePicker> {
  File? _preview;

  Future<void> _pick({required bool fromCamera}) async {
    final file = await StorageService.instance.pickImage(fromCamera: fromCamera);
    if (file == null || !mounted) return;
    setState(() => _preview = file);
    widget.onPicked(file);
  }

  @override
  Widget build(BuildContext context) {
    if (_preview != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              _preview!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () {
                setState(() => _preview = null);
                widget.onCleared?.call();
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        _PickerBtn(
          icon: Icons.camera_alt_rounded,
          label: 'Camera',
          onTap: () => _pick(fromCamera: true),
        ),
        const SizedBox(width: 8),
        _PickerBtn(
          icon: Icons.photo_library_rounded,
          label: 'Gallery',
          onTap: () => _pick(fromCamera: false),
        ),
      ],
    );
  }
}

class _PickerBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.bg3For(context),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.borderFor(context)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: AppColors.text2For(context)),
            ),
          ],
        ),
      ),
    );
  }
}
