import '../../../models/target_set.dart';

class ExerciseEntry {
  final String exerciseId;
  final String name;
  List<TargetSet> targetSets;

  ExerciseEntry({
    required this.exerciseId,
    required this.name,
    required List<TargetSet> targetSets,
  }) : targetSets = List.of(targetSets);
}
