import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/exercise.dart';
import '../../models/set_record.dart';
import '../../providers/session_provider.dart';
import '../../providers/set_record_providers.dart';
import '../../providers/repository_providers.dart';
import '../../services/draft_session_service.dart';
import '../../utils/one_rm_calculator.dart';

class WorkoutCompletionScreen extends ConsumerWidget {
  final SessionState sessionState;

  const WorkoutCompletionScreen({super.key, required this.sessionState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 全種目の前回記録（セットごとの比較バッジ用）
    final previousRecordsMap = {
      for (final exercise in sessionState.exercises)
        exercise.id: ref.watch(
          lastSessionSetRecordsByExerciseProvider(exercise.id),
        ),
    };

    // 全種目の全期間ベスト1RM（PR判定用）
    final allTimeBest1RMMap = {
      for (final exercise in sessionState.exercises)
        exercise.id: ref.watch(allTimeBest1RMProvider(exercise.id)),
    };

    // 全体サマリー（完了チェックしたセットのみカウント）
    final totalSets = sessionState.setRecords.values.fold(0, (sum, records) {
      return sum + records.where((r) => r.completed).length;
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          // ヘッダー
          _buildHeader(context, totalSets),
          // 種目別記録
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                ...sessionState.exercises
                  .where((exercise) {
                    final records = sessionState.setRecords[exercise.id] ?? [];
                    if (records.isEmpty) return false;
                    // 完了チェックのないセットのみの種目は表示しない
                    if (!records.any((r) => r.completed)) return false;
                    return true;
                  })
                  .map((exercise) {
                  final allResults = sessionState.setRecords[exercise.id] ?? [];
                  final current = allResults.where((r) => r.completed).toList();
                  final previousAsync = previousRecordsMap[exercise.id];
                  final previous = previousAsync?.when(
                        data: (r) => r,
                        loading: () => <SetRecord>[],
                        error: (_, _) => <SetRecord>[],
                      ) ??
                      [];
                  final allTimeBest1RM = allTimeBest1RMMap[exercise.id]?.when(
                    data: (v) => v,
                    loading: () => null,
                    error: (_, _) => null,
                  );
                  return _ExerciseCard(
                    exercise: exercise,
                    current: current,
                    previous: previous,
                    allTimeBest1RM: allTimeBest1RM,
                  );
                }),
                const SizedBox(height: 16),
                _buildButtons(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int totalSets) {
    final date = sessionState.session.date.toLocal();
    final dateStr =
        '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 28,
        left: 24,
        right: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏋️', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text(
            'トレーニング完了！',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sessionState.pattern.name,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(
                label: '種目数',
                value: '${sessionState.exercises.length}',
              ),
              const SizedBox(width: 12),
              _StatChip(label: '総セット', value: '$totalSets'),
              const SizedBox(width: 12),
              _StatChip(label: '日付', value: dateStr),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => _showSaveDialog(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '保存して完了',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('戻る'),
          ),
        ),
      ],
    );
  }

  void _showSaveDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('保存しますか？'),
        content: const Text('今日のトレーニングを記録します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _saveSessionToFirestore(context, ref);
              await DraftSessionService.clear();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('保存',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSessionToFirestore(BuildContext context, WidgetRef ref) async {
    try {
      final sessionRepo = ref.read(workoutSessionRepositoryProvider);
      final setRecordRepo = ref.read(setRecordRepositoryProvider);

      await sessionRepo.create(sessionState.session);

      final setRecords = <SetRecord>[];
      sessionState.setRecords.forEach((exerciseId, results) {
        // 完了チェックしたセットのみ保存
        final toSave = results.where((r) => r.completed).toList();
        for (final result in toSave) {
          setRecords.add(SetRecord(
            id: '${sessionState.session.id}_${exerciseId}_${result.setIndex}',
            sessionId: sessionState.session.id,
            exerciseId: exerciseId,
            setIndex: result.setIndex,
            weight: result.weight,
            reps: result.reps,
            date: sessionState.session.date.toUtc(),
          ));
        }
      });

      if (setRecords.isNotEmpty) {
        await setRecordRepo.createBatch(setRecords);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存しました'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}


class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final List<SetResult> current;
  final List<SetRecord> previous;
  final double? allTimeBest1RM;

  const _ExerciseCard({
    required this.exercise,
    required this.current,
    required this.previous,
    required this.allTimeBest1RM,
  });

  @override
  Widget build(BuildContext context) {
    final current1RM = exercise.isBodyweight
        ? null
        : best1RM(current.map((r) => (weight: r.weight, reps: r.reps)));
    final isPR = current1RM != null &&
        (allTimeBest1RM == null || current1RM > allTimeBest1RM!);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          ...current.map((result) {
            final prev = previous
                .where((r) => r.setIndex == result.setIndex)
                .firstOrNull;
            return _SetRow(current: result, previous: prev);
          }),
          if (current1RM != null) ...[
            const Divider(height: 20, color: Color(0xFFF0F0F0)),
            Row(
              children: [
                Text(
                  '推定1RM',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(width: 8),
                Text(
                  '${current1RM.toStringAsFixed(1)}kg',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                if (isPR) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events,
                            size: 11, color: Colors.amber.shade700),
                        const SizedBox(width: 2),
                        Text(
                          'PR更新',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final SetResult current;
  final SetRecord? previous;

  const _SetRow({required this.current, required this.previous});

  @override
  Widget build(BuildContext context) {
    final repsUp = previous != null && current.reps > previous!.reps;
    final weightUp = previous != null &&
        current.weight != null &&
        previous!.weight != null &&
        current.weight! > previous!.weight!;
    final hasImprovement = repsUp || weightUp;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // SET番号
          SizedBox(
            width: 48,
            child: Text(
              'SET ${current.setIndex + 1}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // 記録
          Text(
            '${current.reps}回${current.weight != null ? '  ${current.weight}kg' : ''}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          // 改善バッジ
          if (hasImprovement)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_upward,
                      size: 11, color: Colors.green.shade700),
                  const SizedBox(width: 2),
                  Text(
                    _improvementText(repsUp, weightUp),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _improvementText(bool repsUp, bool weightUp) {
    if (repsUp && weightUp) return '回数・重量UP';
    if (repsUp) return '回数UP';
    return '重量UP';
  }
}
