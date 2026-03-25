import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'mongo_service.dart';

class StorageService {
  StorageService._();
  static final instance = StorageService._();

  final _picker = ImagePicker();

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
    final bytes = await file.readAsBytes();
    final base64 = base64Encode(bytes);
    final path = 'profile_photos/$uid.jpg';
    return await MongoService.instance.uploadImage(path, base64);
  }

  // ── Upload post image ────────────────────────────
  Future<String> uploadPostImage(String postId, File file) async {
    final bytes = await file.readAsBytes();
    final base64 = base64Encode(bytes);
    final path = 'post_images/$postId.jpg';
    return await MongoService.instance.uploadImage(path, base64);
  }

  /// Upload with progress callback — useful for showing a progress bar.
  Future<String> uploadWithProgress(
    String path,
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    if (onProgress != null) onProgress(0.1);
    final bytes = await file.readAsBytes();
    if (onProgress != null) onProgress(0.5);
    final base64 = base64Encode(bytes);
    if (onProgress != null) onProgress(0.9);
    final result = await MongoService.instance.uploadImage(path, base64);
    if (onProgress != null) onProgress(1.0);
    return result;
  }

  /// Delete a file.
  Future<void> deleteFile(String path) async {
    // In our simple Mongo implementation, we could remove the doc
    // But for now, we'll just ignore or implement if needed.
  }

  /// Helper to get image data (since we store it in Mongo, we need to fetch it)
  Future<String?> getImageBase64(String path) async {
    return await MongoService.instance.getImage(path);
  }
}
