class SetRecord {
  final String id;
  final String sessionId;
  final String exerciseId;
  final int setIndex;
  final double? weight; // null if bodyweight
  final int reps;
  final DateTime? date; // セッション日時（前回記録の取得に使用）

  const SetRecord({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.setIndex,
    this.weight,
    required this.reps,
    this.date,
  });

  factory SetRecord.fromMap(String id, Map<String, dynamic> map) {
    return SetRecord(
      id: id,
      sessionId: map['sessionId'] as String,
      exerciseId: map['exerciseId'] as String,
      setIndex: map['setIndex'] as int,
      weight: (map['weight'] as num?)?.toDouble(),
      reps: map['reps'] as int,
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'exerciseId': exerciseId,
      'setIndex': setIndex,
      'weight': weight,
      'reps': reps,
      if (date != null) 'date': date!.toIso8601String(),
    };
  }
}
