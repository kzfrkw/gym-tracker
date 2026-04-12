import 'target_set.dart';

class PatternExercise {
  final String exerciseId;
  final int sortOrder;
  final List<TargetSet> targetSets;

  const PatternExercise({
    required this.exerciseId,
    required this.sortOrder,
    required this.targetSets,
  });

  factory PatternExercise.fromMap(Map<String, dynamic> map) {
    return PatternExercise(
      exerciseId: map['exerciseId'] as String,
      sortOrder: map['sortOrder'] as int,
      targetSets: (map['targetSets'] as List<dynamic>)
          .map((e) => TargetSet.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'sortOrder': sortOrder,
      'targetSets': targetSets.map((e) => e.toMap()).toList(),
    };
  }
}
