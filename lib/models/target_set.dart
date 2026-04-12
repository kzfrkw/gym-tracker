class TargetSet {
  final int repsMin;
  final int repsMax;

  const TargetSet({required this.repsMin, required this.repsMax});

  factory TargetSet.fromMap(Map<String, dynamic> map) {
    return TargetSet(
      repsMin: map['repsMin'] as int,
      repsMax: map['repsMax'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {'repsMin': repsMin, 'repsMax': repsMax};
  }

  String get label => repsMin == repsMax ? '$repsMin回' : '$repsMin〜$repsMax回';
}
