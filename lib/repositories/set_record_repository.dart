import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/set_record.dart';

class SetRecordRepository {
  SetRecordRepository({required this.userId});

  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(userId).collection('setRecords');

  Future<List<SetRecord>> getBySessionId(String sessionId) async {
    final snap = await _col
        .where('sessionId', isEqualTo: sessionId)
        .get();

    return snap.docs
        .map((doc) => SetRecord.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<SetRecord>> getByExerciseId(String exerciseId) async {
    final snap = await _col
        .where('exerciseId', isEqualTo: exerciseId)
        .get();

    return snap.docs
        .map((doc) => SetRecord.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<SetRecord?> getLastByExerciseId(String exerciseId) async {
    final snap = await _col
        .where('exerciseId', isEqualTo: exerciseId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return SetRecord.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  /// 直近セッションの全セット記録を取得（前回の記録表示用）
  Future<List<SetRecord>> getLastSessionRecordsByExerciseId(
      String exerciseId) async {
    // 最新の1件で sessionId を特定
    final latestSnap = await _col
        .where('exerciseId', isEqualTo: exerciseId)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (latestSnap.docs.isEmpty) return [];

    final lastSessionId =
        latestSnap.docs.first.data()['sessionId'] as String;

    // そのセッションの全セットを setIndex 順で取得
    final snap = await _col
        .where('exerciseId', isEqualTo: exerciseId)
        .where('sessionId', isEqualTo: lastSessionId)
        .orderBy('setIndex')
        .get();

    return snap.docs
        .map((doc) => SetRecord.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> create(SetRecord record) async {
    await _col.doc(record.id).set(record.toMap());
  }

  Future<void> createBatch(List<SetRecord> records) async {
    final batch = _firestore.batch();
    for (final record in records) {
      batch.set(_col.doc(record.id), record.toMap());
    }
    await batch.commit();
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> deleteBySessionId(String sessionId) async {
    final snap = await _col
        .where('sessionId', isEqualTo: sessionId)
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
