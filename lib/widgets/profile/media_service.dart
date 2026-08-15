import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Uploads user-generated images (profile photos, post images) to Firebase
/// Storage.
///
/// Images are compressed on the client before upload: [image_picker] applies
/// the native compressor with [ImagePicker.pickImage]'s `maxWidth`,
/// `maxHeight` and `imageQuality` options, which keeps uploads small without
/// needing a Cloud Function. Files are stored under a deterministic path per
/// user so replacing a photo overwrites the old blob (no orphaned files).
class MediaService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Picks an image from the gallery (or camera) and returns the compressed
  /// file, or null if the user cancels.
  Future<File?> pickImage({bool fromCamera = false}) async {
    final source =
        fromCamera ? ImageSource.camera : ImageSource.gallery;
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1440,
      maxHeight: 1440,
      imageQuality: 82,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Picks a document for identity/credential uploads: images or PDFs (the
  /// extensions are enforced by the native file picker), or null if the user
  /// cancels. Web/desktop paths are null, so those platforms are skipped for
  /// now — uploads are mobile-focused.
  Future<File?> pickDocument() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'heic', 'webp', 'pdf'],
    );
    final path = file?.path;
    if (path == null) return null;
    return File(path);
  }

  /// Uploads a profile photo for [uid], overwriting any previous upload, and
  /// returns the public download URL.
  Future<String> uploadProfilePhoto({
    required String uid,
    required File file,
    void Function(double progress)? onProgress,
  }) {
    return uploadFile(
      storagePath: 'profile_photos/$uid.jpg',
      file: file,
      onProgress: onProgress,
    );
  }

  /// Uploads a post image for [uid] under a unique path and returns the
  /// public download URL.
  Future<String> uploadPostImage({
    required String uid,
    required File file,
    void Function(double progress)? onProgress,
  }) {
    return uploadFile(
      storagePath:
          'post_images/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg',
      file: file,
      onProgress: onProgress,
    );
  }

  /// Uploads a sensitive verification document (government ID or professional
  /// credentials) to the private `counselor_ids/<uid>/` or
  /// `counselor_credentials/<uid>/` Storage path and returns the download
  /// URL. The uid lives in its own path segment so the Storage rules can bind
  /// it directly to `request.auth.uid` (owner-write, owner-or-admin-read).
  Future<String> uploadCounselorDocument({
    required String uid,
    required String folder,
    required File file,
  }) async {
    final ext = file.path.split('.').last.toLowerCase();
    final safeExt =
        const {'jpg', 'jpeg', 'png', 'heic', 'webp', 'pdf'}.contains(ext)
            ? ext
            : 'jpg';
    return uploadFile(
      storagePath: '$folder/$uid/document.$safeExt',
      file: file,
    );
  }

  /// Generic upload: writes [file] to [storagePath], reports optional
  /// progress and returns the public download URL. Every other upload in the
  /// app (profile photos, post images, counselor documents) goes through this
  /// so the putFile + progress + URL mechanics live in one place.
  Future<String> uploadFile({
    required String storagePath,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref(storagePath);
    final task = ref.putFile(file);
    if (onProgress != null) {
      final sub = task.snapshotEvents.listen((snap) {
        if (snap.totalBytes > 0) {
          onProgress(snap.bytesTransferred / snap.totalBytes);
        }
      });
      await task;
      await sub.cancel();
    } else {
      await task;
    }
    return ref.getDownloadURL();
  }

  /// Deletes a stored file best-effort (used when replacing images).
  Future<void> deleteIfStored(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Best-effort: never block the caller on cleanup failures.
    }
  }
}
