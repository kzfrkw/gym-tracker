import 'pattern_exercise.dart';

class WorkoutPattern {
  final String id;
  final String name;
  final List<PatternExercise> exercises;

  const WorkoutPattern({
    required this.id,
    required this.name,
    required this.exercises,
  });

  factory WorkoutPattern.fromMap(String id, Map<String, dynamic> map) {
    return WorkoutPattern(
      id: id,
      name: map['name'] as String,
      exercises: (map['exercises'] as List<dynamic>)
          .map((e) => PatternExercise.fromMap(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }
}
