import '../models/exercise.dart';
import '../models/pattern_exercise.dart';
import '../models/target_set.dart';
import '../models/workout_pattern.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/workout_pattern_repository.dart';

class DemoDataSeeder {
  // 固定ID（冪等性確保）
  static const _ex1  = 'ex-bench-press';
  static const _ex2  = 'ex-incline-db-press';
  static const _ex3  = 'ex-db-shoulder-press';
  static const _ex4  = 'ex-barbell-squat';
  static const _ex5  = 'ex-bulgarian-squat';
  static const _ex6  = 'ex-triceps-pushdown';
  static const _ex7  = 'ex-dips';
  static const _ex8  = 'ex-deadlift';
  static const _ex9  = 'ex-bent-over-row';
  static const _ex10 = 'ex-pullup';
  static const _ex11 = 'ex-chinup';
  static const _ex12 = 'ex-incline-db-curl';
  static const _ex13 = 'ex-rear-delt';
  static const _pat1 = 'pat-chest-shoulder-leg';
  static const _pat2 = 'pat-back-arm-leg';

  /// データが空の場合にシードを実行する。
  /// シードを実行した場合は true、スキップした場合は false を返す。
  static Future<bool> seedIfNeeded({required String userId}) async {
    final patternRepo = WorkoutPatternRepository(userId: userId);
    final existing = await patternRepo.getAll();
    if (existing.isNotEmpty) return false;

    // ignore: avoid_print
    print('Seeding demo data for user: $userId');
    await _seed(userId: userId);
    // ignore: avoid_print
    print('Demo data seeded successfully!');
    return true;
  }

  static Future<void> _seed({required String userId}) async {
    final exercises = _createExercises();
    final patterns  = _createPatterns();

    final exerciseRepo = ExerciseRepository(userId: userId);
    final patternRepo  = WorkoutPatternRepository(userId: userId);

    for (final exercise in exercises) {
      await exerciseRepo.create(exercise);
    }
    for (final pattern in patterns) {
      await patternRepo.create(pattern);
    }
  }

  static List<Exercise> _createExercises() {
    return [
      Exercise(id: _ex1,  name: 'バーベルベンチプレス'),
      Exercise(id: _ex2,  name: 'インクラインダンベルベンチプレス'),
      Exercise(id: _ex3,  name: 'ダンベルショルダープレス'),
      Exercise(id: _ex4,  name: 'バーベルスクワット'),
      Exercise(id: _ex5,  name: 'ブルガリアンスクワット', isOptional: true),
      Exercise(id: _ex6,  name: 'トライセプスプッシュダウン'),
      Exercise(id: _ex7,  name: 'ディップス', isBodyweight: true),
      Exercise(id: _ex8,  name: 'バーベルデッドリフト'),
      Exercise(id: _ex9,  name: 'ベントオーバーロー'),
      Exercise(id: _ex10, name: 'プルアップ', isBodyweight: true),
      Exercise(id: _ex11, name: 'チンアップ', isBodyweight: true),
      Exercise(id: _ex12, name: 'インクラインダンベルカール'),
      Exercise(id: _ex13, name: 'リアデルト'),
    ];
  }

  static List<WorkoutPattern> _createPatterns() {
    return [
      WorkoutPattern(
        id: _pat1,
        name: 'パターン1: 胸・肩・足',
        exercises: [
          PatternExercise(
            exerciseId: _ex1,
            sortOrder: 0,
            targetSets: [
              const TargetSet(repsMin: 6, repsMax: 8),
              const TargetSet(repsMin: 6, repsMax: 8),
              const TargetSet(repsMin: 6, repsMax: 8),
            ],
          ),
          PatternExercise(
            exerciseId: _ex2,
            sortOrder: 1,
            targetSets: [
              const TargetSet(repsMin: 8, repsMax: 10),
              const TargetSet(repsMin: 8, repsMax: 10),
            ],
          ),
          PatternExercise(
            exerciseId: _ex3,
            sortOrder: 2,
            targetSets: [
              const TargetSet(repsMin: 8, repsMax: 10),
              const TargetSet(repsMin: 8, repsMax: 10),
            ],
          ),
          PatternExercise(
            exerciseId: _ex4,
            sortOrder: 3,
            targetSets: [
              const TargetSet(repsMin: 6, repsMax: 8),
              const TargetSet(repsMin: 6, repsMax: 8),
              const TargetSet(repsMin: 6, repsMax: 8),
            ],
          ),
          PatternExercise(
            exerciseId: _ex5,
            sortOrder: 4,
            targetSets: [
              const TargetSet(repsMin: 10, repsMax: 10),
              const TargetSet(repsMin: 10, repsMax: 10),
            ],
          ),
          PatternExercise(
            exerciseId: _ex6,
            sortOrder: 5,
            targetSets: [
              const TargetSet(repsMin: 10, repsMax: 12),
              const TargetSet(repsMin: 10, repsMax: 12),
            ],
          ),
          PatternExercise(
            exerciseId: _ex7,
            sortOrder: 6,
            targetSets: [
              const TargetSet(repsMin: 6, repsMax: 6),
              const TargetSet(repsMin: 6, repsMax: 6),
            ],
          ),
        ],
      ),
      WorkoutPattern(
        id: _pat2,
        name: 'パターン2: 背中・腕・足',
        exercises: [
          PatternExercise(
            exerciseId: _ex8,
            sortOrder: 0,
            targetSets: [
              const TargetSet(repsMin: 6, repsMax: 8),
              const TargetSet(repsMin: 6, repsMax: 8),
              const TargetSet(repsMin: 6, repsMax: 8),
            ],
          ),
          PatternExercise(
            exerciseId: _ex9,
            sortOrder: 1,
            targetSets: [
              const TargetSet(repsMin: 8, repsMax: 10),
              const TargetSet(repsMin: 8, repsMax: 10),
            ],
          ),
          PatternExercise(
            exerciseId: _ex10,
            sortOrder: 2,
            targetSets: [
              const TargetSet(repsMin: 6, repsMax: 6),
              const TargetSet(repsMin: 6, repsMax: 6),
            ],
          ),
          PatternExercise(
            exerciseId: _ex11,
            sortOrder: 3,
            targetSets: [
              const TargetSet(repsMin: 6, repsMax: 6),
              const TargetSet(repsMin: 6, repsMax: 6),
            ],
          ),
          PatternExercise(
            exerciseId: _ex12,
            sortOrder: 4,
            targetSets: [
              const TargetSet(repsMin: 10, repsMax: 12),
              const TargetSet(repsMin: 10, repsMax: 12),
              const TargetSet(repsMin: 10, repsMax: 12),
            ],
          ),
          PatternExercise(
            exerciseId: _ex13,
            sortOrder: 5,
            targetSets: [
              const TargetSet(repsMin: 10, repsMax: 12),
              const TargetSet(repsMin: 10, repsMax: 12),
            ],
          ),
        ],
      ),
    ];
  }
}
