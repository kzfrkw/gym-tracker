import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/workout_pattern_repository.dart';
import '../repositories/workout_session_repository.dart';
import '../repositories/set_record_repository.dart';
import 'auth_providers.dart';

/// ログイン中の userId が取れない場合は例外を投げる
String _requireUserId(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) throw StateError('Not authenticated');
  return userId;
}

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository(userId: _requireUserId(ref));
});

final workoutPatternRepositoryProvider =
    Provider<WorkoutPatternRepository>((ref) {
  return WorkoutPatternRepository(userId: _requireUserId(ref));
});

final workoutSessionRepositoryProvider =
    Provider<WorkoutSessionRepository>((ref) {
  return WorkoutSessionRepository(userId: _requireUserId(ref));
});

final setRecordRepositoryProvider = Provider<SetRecordRepository>((ref) {
  return SetRecordRepository(userId: _requireUserId(ref));
});
