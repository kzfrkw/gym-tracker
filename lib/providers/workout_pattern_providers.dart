import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_pattern.dart';
import 'repository_providers.dart';

final workoutPatternsProvider = FutureProvider<List<WorkoutPattern>>((
  ref,
) async {
  final repo = ref.watch(workoutPatternRepositoryProvider);
  return repo.getAll();
});

final workoutPatternByIdProvider =
    FutureProvider.family<WorkoutPattern?, String>((ref, id) async {
      final repo = ref.watch(workoutPatternRepositoryProvider);
      return repo.getById(id);
    });
