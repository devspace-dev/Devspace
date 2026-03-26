import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  StorageService._();
  static final instance = StorageService._();

  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  // ── Pick from camera or gallery ──────────────────
  Future<File?> pickImage({bool fromCamera = false}) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    return picked != null ? File(picked.path) : null;
  }

  // ── Upload profile picture ───────────────────────
  Future<String> uploadProfilePhoto(String uid, File file) async {
    final path = 'profiles/$uid.jpg';
    await _supabase.storage.from('images').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    return _supabase.storage.from('images').getPublicUrl(path);
  }

  // ── Upload post image ────────────────────────────
  Future<String> uploadPostImage(String postId, File file) async {
    final path = 'posts/$postId.jpg';
    await _supabase.storage.from('images').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    return _supabase.storage.from('images').getPublicUrl(path);
  }

  /// Upload with progress callback.
  Future<String> uploadWithProgress(
    String path,
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    // Supabase flutter doesn't support progress in upload yet easily without custom implementation
    // But we'll do our best.
    if (onProgress != null) onProgress(0.1);
    await _supabase.storage.from('images').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
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
}
