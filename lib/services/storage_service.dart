import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../theme/app_colors.dart';

class StorageService {
  StorageService._();
  static final instance = StorageService._();
  static const _uuid = Uuid();

  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  // ── Pick from camera or gallery ──────────────────
  Future<File?> pickImage({
    bool fromCamera = false,
    bool crop = false,
    bool isCircle = false,
    int imageQuality = 70,
    double maxWidth = 1024,
    double maxHeight = 1024,
  }) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
    if (picked == null) return null;

    if (crop) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: isCircle ? CropAspectRatioPreset.square : CropAspectRatioPreset.original,
            lockAspectRatio: isCircle,
            aspectRatioPresets: isCircle
                ? [CropAspectRatioPreset.square]
                : [
                    CropAspectRatioPreset.original,
                    CropAspectRatioPreset.square,
                    CropAspectRatioPreset.ratio3x2,
                    CropAspectRatioPreset.ratio4x3,
                    CropAspectRatioPreset.ratio16x9,
                  ],
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioPresets: isCircle
                ? [CropAspectRatioPreset.square]
                : [
                    CropAspectRatioPreset.original,
                    CropAspectRatioPreset.square,
                    CropAspectRatioPreset.ratio3x2,
                    CropAspectRatioPreset.ratio4x3,
                    CropAspectRatioPreset.ratio16x9,
                  ],
          ),
        ],
      );
      if (croppedFile != null) {
        return File(croppedFile.path);
      }
    }

    return File(picked.path);
  }

  // ── Upload profile picture ───────────────────────
  Future<String> uploadProfilePhoto(String uid, File file) async {
    final path = 'profiles/$uid.jpg';
    await _supabase.storage.from('images').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    return _supabase.storage.from('images').getPublicUrl(path);
  }

  // ── Upload cover photo ───────────────────────────
  Future<String> uploadCoverPhoto(String uid, File file) async {
    final path = 'covers/$uid.jpg';
    await _supabase.storage.from('images').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    return _supabase.storage.from('images').getPublicUrl(path);
  }

  // ── Upload post image ────────────────────────────
  Future<String> uploadPostImage(String postId, File file) async {
    final path = 'posts/$postId.jpg';
    await _supabase.storage.from('images').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    return _supabase.storage.from('images').getPublicUrl(path);
  }

  Future<String> uploadPostImageForDraft(File file) async {
    final path = 'posts/${_uuid.v4()}.jpg';
    await _supabase.storage.from('images').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    return _supabase.storage.from('images').getPublicUrl(path);
  }

  /// Upload with progress callback.
  Future<String> uploadWithProgress(
    String path,
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    if (onProgress != null) onProgress(0.1);
    await _supabase.storage.from('images').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    if (onProgress != null) onProgress(1.0);
    return _supabase.storage.from('images').getPublicUrl(path);
  }

  /// Delete a file.
  Future<void> deleteFile(String path) async {
    await _supabase.storage.from('images').remove([path]);
  }

  String resolvePublicUrl(String pathOrUrl) {
    if (pathOrUrl.startsWith('http')) return pathOrUrl;
    return _supabase.storage.from('images').getPublicUrl(pathOrUrl);
  }

  Future<String> uploadChatImage(String conversationId, File file) async {
    final path = 'chat/$conversationId/${_uuid.v4()}.jpg';
    await _supabase.storage.from('images').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    return _supabase.storage.from('images').getPublicUrl(path);
  }
}
