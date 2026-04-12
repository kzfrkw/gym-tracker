import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';

/// 1セッション分の進捗データ
class ExerciseProgressEntry {
  final DateTime date;
  final double maxWeight;
  final int setCount;

  const ExerciseProgressEntry({
    required this.date,
    required this.maxWeight,
    required this.setCount,
  });
}

/// exerciseId ごとのセッション別最大重量リスト（日付昇順）
final exerciseProgressProvider =
    FutureProvider.family<List<ExerciseProgressEntry>, String>(
      (ref, exerciseId) async {
        final repo = ref.watch(setRecordRepositoryProvider);
        final records = await repo.getByExerciseId(exerciseId);

        // weight が null のレコードは除外（自重種目対策）
        final weighted = records.where((r) => r.weight != null).toList();

        // sessionId ごとにグループ化
        final grouped = <String, List<double>>{};
        final sessionDates = <String, DateTime>{};

        for (final r in weighted) {
          grouped.putIfAbsent(r.sessionId, () => []).add(r.weight!);
          if (r.date != null) sessionDates[r.sessionId] = r.date!;
        }

        // セッションごとに最大重量を計算して日付昇順でソート
        final entries = grouped.entries.map((e) {
          return ExerciseProgressEntry(
            date: sessionDates[e.key] ?? DateTime(0),
            maxWeight: e.value.reduce((a, b) => a > b ? a : b),
            setCount: e.value.length,
          );
        }).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        return entries;
      },
    );
