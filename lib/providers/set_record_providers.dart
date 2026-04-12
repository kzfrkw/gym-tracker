import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/set_record.dart';
import 'repository_providers.dart';

final setRecordsByExerciseProvider =
    FutureProvider.family<List<SetRecord>, String>((ref, exerciseId) async {
      final repo = ref.watch(setRecordRepositoryProvider);
      return repo.getByExerciseId(exerciseId);
    });

final lastSetRecordByExerciseProvider =
    FutureProvider.family<SetRecord?, String>((ref, exerciseId) async {
      final repo = ref.watch(setRecordRepositoryProvider);
      return repo.getLastByExerciseId(exerciseId);
    });

final lastSessionSetRecordsByExerciseProvider =
    FutureProvider.family<List<SetRecord>, String>((ref, exerciseId) async {
      final repo = ref.watch(setRecordRepositoryProvider);
      return repo.getLastSessionRecordsByExerciseId(exerciseId);
    });

/// 全期間で最も高い推定1RM（Epley式）
final allTimeBest1RMProvider =
    FutureProvider.family<double?, String>((ref, exerciseId) async {
      final repo = ref.watch(setRecordRepositoryProvider);
      final records = await repo.getByExerciseId(exerciseId);

      return records
          .where((r) => r.weight != null && r.weight! > 0 && r.reps > 0)
          .map((r) => r.weight! * (1 + r.reps / 30))
          .fold<double?>(null, (best, v) => best == null || v > best ? v : best);
    });
