import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

class NotesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const int pageSize = 10;

  // Коллекция notes пользователя
  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('notes').doc(uid).collection('items');

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<void> addNote(NoteModel note) =>
      _col(note.uid).doc(note.id).set(note.toMap());

  Future<void> updateNote(NoteModel note) =>
      _col(note.uid).doc(note.id).update(note.toMap());

  Future<void> deleteNote(String uid, String noteId) =>
      _col(uid).doc(noteId).delete();

  // ── Real-time список (snapshot) ──────────────────────────────────────────

  Stream<List<NoteModel>> notesStream({
    required String uid,
    NoteStatus? statusFilter,
    NoteCategory? categoryFilter,
  }) {
    Query<Map<String, dynamic>> q = _col(
      uid,
    ).orderBy('createdAt', descending: true);

    if (statusFilter != null) {
      q = q.where('status', isEqualTo: statusFilter.name);
    }
    if (categoryFilter != null) {
      q = q.where('category', isEqualTo: categoryFilter.name);
    }

    return q
        .snapshots()
        .handleError((e) {
          // обработка ошибок стрима — прокидываем дальше как исключение
          throw Exception('Firestore stream error: $e');
        })
        .map(
          (snap) =>
              snap.docs.map((d) => NoteModel.fromMap(d.id, d.data())).toList(),
        );
  }

  // ── Пагинация: первая страница ────────────────────────────────────────────

  Future<NotesPage> fetchFirstPage(
    String uid, {
    NoteStatus? statusFilter,
    NoteCategory? categoryFilter,
  }) async {
    Query<Map<String, dynamic>> q = _col(
      uid,
    ).orderBy('createdAt', descending: true).limit(pageSize);

    q = _applyFilters(q, statusFilter, categoryFilter);

    final snap = await q.get();
    final notes = snap.docs
        .map((d) => NoteModel.fromMap(d.id, d.data()))
        .toList();
    final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
    return NotesPage(
      notes: notes,
      lastDoc: lastDoc,
      hasMore: notes.length == pageSize,
    );
  }

  // ── Пагинация: следующая страница ─────────────────────────────────────────

  Future<NotesPage> fetchNextPage(
    String uid,
    DocumentSnapshot lastDoc, {
    NoteStatus? statusFilter,
    NoteCategory? categoryFilter,
  }) async {
    Query<Map<String, dynamic>> q = _col(uid)
        .orderBy('createdAt', descending: true)
        .startAfterDocument(lastDoc)
        .limit(pageSize);

    q = _applyFilters(q, statusFilter, categoryFilter);

    final snap = await q.get();
    final notes = snap.docs
        .map((d) => NoteModel.fromMap(d.id, d.data()))
        .toList();
    final newLast = snap.docs.isNotEmpty ? snap.docs.last : null;
    return NotesPage(
      notes: notes,
      lastDoc: newLast,
      hasMore: notes.length == pageSize,
    );
  }

  // ── Поиск по тегу (array-contains) ───────────────────────────────────────

  Future<List<NoteModel>> searchByTag(String uid, String tag) async {
    final snap = await _col(uid)
        .where('tags', arrayContains: tag)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => NoteModel.fromMap(d.id, d.data())).toList();
  }

  // ── Поиск по подстроке в заголовке (where >= / <=) ────────────────────────
  // Firestore не поддерживает LIKE, но поддерживает range query на строку

  Future<List<NoteModel>> searchByTitle(String uid, String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final end = '$q\uf8ff'; // Unicode sentinel для range
    final snap = await _col(uid)
        .orderBy('title')
        .where('title', isGreaterThanOrEqualTo: q)
        .where('title', isLessThanOrEqualTo: end)
        .get();
    return snap.docs.map((d) => NoteModel.fromMap(d.id, d.data())).toList();
  }

  Query<Map<String, dynamic>> _applyFilters(
    Query<Map<String, dynamic>> q,
    NoteStatus? status,
    NoteCategory? category,
  ) {
    if (status != null) q = q.where('status', isEqualTo: status.name);
    if (category != null) q = q.where('category', isEqualTo: category.name);
    return q;
  }
}

class NotesPage {
  final List<NoteModel> notes;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;
  const NotesPage({required this.notes, this.lastDoc, required this.hasMore});
}
