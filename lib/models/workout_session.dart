class WorkoutSession {
  final String id;
  final DateTime date;
  final String patternId;

  const WorkoutSession({
    required this.id,
    required this.date,
    required this.patternId,
  });

  factory WorkoutSession.fromMap(String id, Map<String, dynamic> map) {
    return WorkoutSession(
      id: id,
      date: DateTime.parse(map['date'] as String),
      patternId: map['patternId'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'patternId': patternId,
    };
  }
}
