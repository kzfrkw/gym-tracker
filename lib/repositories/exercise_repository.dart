import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';

class ExerciseRepository {
  ExerciseRepository({required this.userId});

  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(userId).collection('exercises');

  Future<List<Exercise>> getAll() async {
    final snap = await _col.get();
    return snap.docs.map((doc) => Exercise.fromMap(doc.id, doc.data())).toList();
  }

  Future<Exercise?> getById(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) return null;
    return Exercise.fromMap(snap.id, snap.data()!);
  }

  Future<void> create(Exercise exercise) async {
    await _col.doc(exercise.id).set(exercise.toMap());
  }

  Future<void> update(Exercise exercise) async {
    await _col.doc(exercise.id).update(exercise.toMap());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
