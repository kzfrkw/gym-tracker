import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_session.dart';
import '../models/set_record.dart';
import '../models/exercise.dart';
import 'repository_providers.dart';

// 表示中の年月を管理する Notifier
class HistoryFocusedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void setMonth(DateTime month) => state = DateTime(month.year, month.month);
}

final historyFocusedMonthProvider =
    NotifierProvider<HistoryFocusedMonthNotifier, DateTime>(
      HistoryFocusedMonthNotifier.new,
    );

// 選択中の日付を管理する Notifier
class HistorySelectedDayNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void select(DateTime? day) => state = day;
}

final historySelectedDayProvider =
    NotifierProvider<HistorySelectedDayNotifier, DateTime?>(
      HistorySelectedDayNotifier.new,
    );

// 月ごとのセッション取得（カレンダーのマーク用）
final sessionsByMonthProvider =
    FutureProvider.family<Map<DateTime, List<WorkoutSession>>, DateTime>(
      (ref, month) async {
        final repo = ref.watch(workoutSessionRepositoryProvider);
        final sessions = await repo.getByMonth(month.year, month.month);

        // 時刻なしの date でグループ化
        final map = <DateTime, List<WorkoutSession>>{};
        for (final session in sessions) {
          final day = DateTime(
            session.date.year,
            session.date.month,
            session.date.day,
          );
          map.putIfAbsent(day, () => []).add(session);
        }
        return map;
      },
    );

// 選択日のセッション一覧
final selectedDaySessionsProvider =
    FutureProvider<List<WorkoutSession>>((ref) async {
      final selectedDay = ref.watch(historySelectedDayProvider);
      if (selectedDay == null) return [];

      final repo = ref.watch(workoutSessionRepositoryProvider);
      return repo.getByDate(selectedDay);
    });

// 直近N件のセッション
final recentSessionsProvider = FutureProvider<List<WorkoutSession>>((ref) {
  final repo = ref.watch(workoutSessionRepositoryProvider);
  return repo.getRecent(10);
});

// セッション詳細（SetRecord + Exercise 名）
class SessionDetail {
  final Exercise exercise;
  final List<SetRecord> setRecords;
  const SessionDetail({required this.exercise, required this.setRecords});
}

final sessionDetailProvider =
    FutureProvider.family<List<SessionDetail>, String>((ref, sessionId) async {
      final setRecordRepo = ref.watch(setRecordRepositoryProvider);
      final exerciseRepo = ref.watch(exerciseRepositoryProvider);

      final setRecords = await setRecordRepo.getBySessionId(sessionId);

      // exerciseId でグループ化
      final grouped = <String, List<SetRecord>>{};
      for (final record in setRecords) {
        grouped.putIfAbsent(record.exerciseId, () => []).add(record);
      }

      final details = <SessionDetail>[];
      for (final entry in grouped.entries) {
        final exercise = await exerciseRepo.getById(entry.key);
        if (exercise != null) {
          final sortedRecords = List<SetRecord>.from(entry.value)
            ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
          details.add(
            SessionDetail(exercise: exercise, setRecords: sortedRecords),
          );
        }
      }
      return details;
    });
