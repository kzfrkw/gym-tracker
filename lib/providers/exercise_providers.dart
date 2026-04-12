import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import 'repository_providers.dart';

final exercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.getAll();
});

final exerciseByIdProvider = FutureProvider.family<Exercise?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.getById(id);
});
