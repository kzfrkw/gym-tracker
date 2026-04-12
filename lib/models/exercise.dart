class Exercise {
  final String id;
  final String name;
  final bool isBodyweight;
  final bool isOptional;

  const Exercise({
    required this.id,
    required this.name,
    this.isBodyweight = false,
    this.isOptional = false,
  });

  factory Exercise.fromMap(String id, Map<String, dynamic> map) {
    return Exercise(
      id: id,
      name: map['name'] as String,
      isBodyweight: map['isBodyweight'] as bool? ?? false,
      isOptional: map['isOptional'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isBodyweight': isBodyweight,
      'isOptional': isOptional,
    };
  }
}
