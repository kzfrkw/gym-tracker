import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../models/workout_pattern.dart';
import '../models/workout_session.dart';
import '../repositories/exercise_repository.dart';
import 'repository_providers.dart';

const uuid = Uuid();

class SetResult {
  final int setIndex;
  final int reps;
  final double? weight;
  final bool completed;

  const SetResult({
    required this.setIndex,
    required this.reps,
    this.weight,
    this.completed = false,
  });
}

class SessionState {
  final WorkoutSession session;
  final WorkoutPattern pattern;
  final List<Exercise> exercises;
  final int currentExerciseIndex;
  final Map<String, List<SetResult>> setRecords; // exerciseId -> SetResult list

  const SessionState({
    required this.session,
    required this.pattern,
    required this.exercises,
    required this.currentExerciseIndex,
    this.setRecords = const {},
  });

  Exercise get currentExercise => exercises[currentExerciseIndex];

  SessionState copyWith({
    int? currentExerciseIndex,
    Map<String, List<SetResult>>? setRecords,
  }) {
    return SessionState(
      session: session,
      pattern: pattern,
      exercises: exercises,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      setRecords: setRecords ?? this.setRecords,
    );
  }

  /// セット記録を保存
  SessionState saveSetRecords(String exerciseId, List<SetResult> records) {
    final updatedRecords = {...setRecords, exerciseId: records};
    return copyWith(setRecords: updatedRecords);
  }
}

Future<SessionState> initializeSession(
  WorkoutPattern pattern,
  ExerciseRepository exerciseRepo,
) async {
  final session = WorkoutSession(
    id: uuid.v4(),
    date: DateTime.now().toUtc(),
    patternId: pattern.id,
  );

  final exercises = <Exercise>[];
  for (final patternExercise in pattern.exercises) {
    final exercise = await exerciseRepo.getById(patternExercise.exerciseId);
    if (exercise != null) exercises.add(exercise);
  }

  return SessionState(
    session: session,
    pattern: pattern,
    exercises: exercises,
    currentExerciseIndex: 0,
  );
}

// セッション初期化用 FutureProvider.family
final sessionInitProvider = FutureProvider.family<SessionState, WorkoutPattern>(
  (ref, pattern) async {
    final exerciseRepo = ref.watch(exerciseRepositoryProvider);
    return initializeSession(pattern, exerciseRepo);
  },
);
