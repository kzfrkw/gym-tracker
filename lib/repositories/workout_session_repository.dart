import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_session.dart';

class WorkoutSessionRepository {
  WorkoutSessionRepository({required this.userId});

  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(userId).collection('workoutSessions');

  Future<List<WorkoutSession>> getAll() async {
    final snap = await _col.get();
    return snap.docs
        .map((doc) => WorkoutSession.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<WorkoutSession?> getById(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) return null;
    return WorkoutSession.fromMap(snap.id, snap.data()!);
  }

  Future<List<WorkoutSession>> getByMonth(int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth =
        DateTime(year, month + 1, 1).subtract(const Duration(seconds: 1));

    final snap = await _col
        .where('date', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .where('date', isLessThanOrEqualTo: endOfMonth.toIso8601String())
        .get();

    return snap.docs
        .map((doc) => WorkoutSession.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<WorkoutSession>> getByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay =
        DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snap = await _col
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThanOrEqualTo: endOfDay.toIso8601String())
        .get();

    return snap.docs
        .map((doc) => WorkoutSession.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<WorkoutSession>> getRecent(int limit) async {
    final snap = await _col
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((doc) => WorkoutSession.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> create(WorkoutSession session) async {
    await _col.doc(session.id).set(session.toMap());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
