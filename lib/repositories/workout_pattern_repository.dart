import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_pattern.dart';

class WorkoutPatternRepository {
  WorkoutPatternRepository({required this.userId});

  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(userId).collection('workoutPatterns');

  Future<List<WorkoutPattern>> getAll() async {
    final snap = await _col.get();
    return snap.docs
        .map((doc) => WorkoutPattern.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<WorkoutPattern?> getById(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) return null;
    return WorkoutPattern.fromMap(snap.id, snap.data()!);
  }

  Future<void> create(WorkoutPattern pattern) async {
    await _col.doc(pattern.id).set(pattern.toMap());
  }

  Future<void> update(WorkoutPattern pattern) async {
    await _col.doc(pattern.id).update(pattern.toMap());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
