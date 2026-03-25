import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService._();
  static final instance = StorageService._();

  final _storage = FirebaseStorage.instance;
  final _picker  = ImagePicker();

  // ── Pick from camera or gallery ──────────────────
  Future<File?> pickImage({bool fromCamera = false}) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth:  1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    return picked != null ? File(picked.path) : null;
  }

  // ── Upload profile picture ───────────────────────
  Future<String> uploadProfilePhoto(String uid, File file) async {
    final ref = _storage.ref('profile_photos/$uid.jpg');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }

  // ── Upload post image ────────────────────────────
  Future<String> uploadPostImage(String postId, File file) async {
    final ref  = _storage.ref('post_images/$postId.jpg');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }

  /// Upload with progress callback — useful for showing a progress bar.
  Future<String> uploadWithProgress(
    String path,
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    final ref  = _storage.ref(path);
    final task = ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));

    task.snapshotEvents.listen((snap) {
      if (onProgress != null && snap.totalBytes > 0) {
        onProgress(snap.bytesTransferred / snap.totalBytes);
      }
    });

    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  /// Delete a file (e.g. when replacing profile photo).
  Future<void> deleteFile(String downloadUrl) async {
    try {
      await _storage.refFromURL(downloadUrl).delete();
    } catch (_) {
      // File may not exist — ignore silently
    }
  }
}
