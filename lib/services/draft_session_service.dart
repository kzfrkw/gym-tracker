import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise.dart';
import '../models/pattern_exercise.dart';
import '../models/workout_pattern.dart';
import '../models/workout_session.dart';
import '../providers/session_provider.dart';

class SessionDraft {
  final SessionState sessionState;
  final List<int> repsValues;
  final List<String> weightTexts;
  final List<bool> completedValues;

  const SessionDraft({
    required this.sessionState,
    required this.repsValues,
    required this.weightTexts,
    required this.completedValues,
  });
}

class DraftSessionService {
  static const _key = 'session_draft';

  static Future<void> save({
    required SessionState state,
    required List<int> repsValues,
    required List<String> weightTexts,
    required List<bool> completedValues,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'session': {
        'id': state.session.id,
        'date': state.session.date.toIso8601String(),
        'patternId': state.session.patternId,
      },
      'pattern': {
        'id': state.pattern.id,
        'name': state.pattern.name,
        'exercises': state.pattern.exercises.map((e) => e.toMap()).toList(),
      },
      'exercises': state.exercises
          .map((e) => {
                'id': e.id,
                'name': e.name,
                'isBodyweight': e.isBodyweight,
                'isOptional': e.isOptional,
              })
          .toList(),
      'currentExerciseIndex': state.currentExerciseIndex,
      'setRecords': state.setRecords.map(
        (k, v) => MapEntry(
          k,
          v
              .map((r) => {
                    'setIndex': r.setIndex,
                    'reps': r.reps,
                    'weight': r.weight,
                    'completed': r.completed,
                  })
              .toList(),
        ),
      ),
      'currentReps': repsValues,
      'currentWeights': weightTexts,
      'currentCompleted': completedValues,
    };
    await prefs.setString(_key, jsonEncode(data));
  }

  static Future<SessionDraft?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return null;

    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final sessionMap = data['session'] as Map<String, dynamic>;
      final session = WorkoutSession(
        id: sessionMap['id'] as String,
        date: DateTime.parse(sessionMap['date'] as String),
        patternId: sessionMap['patternId'] as String,
      );

      final patternMap = data['pattern'] as Map<String, dynamic>;
      final pattern = WorkoutPattern(
        id: patternMap['id'] as String,
        name: patternMap['name'] as String,
        exercises: (patternMap['exercises'] as List)
            .map((e) => PatternExercise.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

      final exercises = (data['exercises'] as List)
          .map((e) => Exercise.fromMap(
                e['id'] as String,
                e as Map<String, dynamic>,
              ))
          .toList();

      final setRecordsRaw =
          data['setRecords'] as Map<String, dynamic>;
      final setRecords = setRecordsRaw.map(
        (k, v) => MapEntry(
          k,
          (v as List)
              .map((r) => SetResult(
                    setIndex: r['setIndex'] as int,
                    reps: r['reps'] as int,
                    weight: (r['weight'] as num?)?.toDouble(),
                    completed: r['completed'] as bool? ?? false,
                  ))
              .toList(),
        ),
      );

      final sessionState = SessionState(
        session: session,
        pattern: pattern,
        exercises: exercises,
        currentExerciseIndex: data['currentExerciseIndex'] as int,
        setRecords: setRecords,
      );

      final repsValues =
          (data['currentReps'] as List).map((e) => e as int).toList();
      final weightTexts =
          (data['currentWeights'] as List).map((e) => e as String).toList();
      final completedValues =
          (data['currentCompleted'] as List? ?? List.filled(repsValues.length, false))
              .map((e) => e as bool)
              .toList();

      return SessionDraft(
        sessionState: sessionState,
        repsValues: repsValues,
        weightTexts: weightTexts,
        completedValues: completedValues,
      );
    } catch (_) {
      await clear();
      return null;
    }
  }

  static Future<bool> exists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
