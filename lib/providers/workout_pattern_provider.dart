import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_pattern.dart';
import 'repository_providers.dart';

final workoutPatternsProvider =
    FutureProvider.autoDispose<List<WorkoutPattern>>((ref) async {
      final repo = ref.watch(workoutPatternRepositoryProvider);
      return repo.getAll();
    });
