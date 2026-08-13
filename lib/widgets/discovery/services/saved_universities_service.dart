import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/university_models.dart';

/// Firestore data access for saved universities.
///
/// Documents live at `saved_universities/{uid}/items/{programId}` (one doc
/// per saved program — saving is available to ALL tiers and unlimited) and
/// folders at `saved_universities/{uid}/folders/{folderId}` (Pro/Premium).
/// Everything is owned by [uid]; security rules enforce that.
class SavedUniversitiesService {
  DocumentReference<Map<String, dynamic>> _root(String uid) =>
      FirebaseFirestore.instance
          .collection('saved_universities')
          .doc(uid);

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _root(uid).collection('items');

  CollectionReference<Map<String, dynamic>> _folders(String uid) =>
      _root(uid).collection('folders');

  // ── Items ───────────────────────────────────────────────────────────────

  /// Streams the user's saved programs, newest first.
  Stream<List<SavedUniversity>> watchSaved(String uid) => _items(uid)
      .orderBy('savedAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(SavedUniversity.fromSnapshot).toList());

  /// One-shot fetch (e.g. for the dashboard badge count).
  Future<List<SavedUniversity>> fetchSaved(String uid) async {
    final snap =
        await _items(uid).orderBy('savedAt', descending: true).get();
    return snap.docs.map(SavedUniversity.fromSnapshot).toList();
  }

  /// Streams whether a specific program is currently saved.
  Stream<bool> watchSavedStatus(String uid, String programId) =>
      _items(uid).doc(programId).snapshots().map((s) => s.exists);

  /// Toggles a program's saved state. Returns the new state.
  /// Logs are written separately by the caller via [UserInteractionsService].
  Future<bool> toggleSave({
    required String uid,
    required RecommendedProgram program,
    String? folderId,
  }) async {
    final ref = _items(uid).doc(program.programId);
    final existing = await ref.get();
    if (existing.exists) {
      await ref.delete();
      return false;
    }
    await ref.set({
      'programId': program.programId,
      'universityId': program.universityId,
      'universityName': program.universityName,
      'programName': program.programName,
      'country': ?program.country,
      'countryCode': ?program.countryCode,
      'degreeLevel': ?program.degreeLevel,
      'folderId': ?folderId,
      'savedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  Future<void> removeSave({required String uid, required String programId}) =>
      _items(uid).doc(programId).delete();

  /// Moves a saved program into a folder (or removes the folder assignment
  /// when [folderId] is null). Pro/Premium feature; free tier keeps
  /// everything unsorted.
  Future<void> assignFolder({
    required String uid,
    required String programId,
    String? folderId,
  }) =>
      _items(uid).doc(programId).update({
        // null folderId = detach (remove the field), non-null = assign.
        'folderId': folderId ?? FieldValue.delete(),
      });

  /// Detaches every saved program assigned to [folderId] so no item keeps a
  /// dangling reference after the folder is deleted.
  Future<void> clearItemsInFolder({
    required String uid,
    required String folderId,
  }) async {
    final snap = await _items(uid)
        .where('folderId', isEqualTo: folderId)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'folderId': FieldValue.delete()});
    }
    await batch.commit();
  }

  // ── Folders (Pro/Premium) ───────────────────────────────────────────────

  Stream<List<SavedFolder>> watchFolders(String uid) => _folders(uid)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snap) => snap.docs.map(SavedFolder.fromSnapshot).toList());

  Future<String> createFolder({
    required String uid,
    required String name,
  }) async {
    final ref = _folders(uid).doc();
    await ref.set({
      'name': name.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> deleteFolder({required String uid, required String folderId}) =>
      _folders(uid).doc(folderId).delete();
}
