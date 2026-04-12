import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workout_pattern.dart';
import '../../models/workout_session.dart';
import '../../providers/workout_pattern_providers.dart';
import '../../providers/history_providers.dart';
import '../../services/draft_session_service.dart';
import '../session/session_screen.dart';
import '../history/history_screen.dart';
import '../history/session_detail_screen.dart';
import '../settings/settings_screen.dart';
import '../progress/exercise_select_screen.dart';

final _draftProvider = FutureProvider.autoDispose<SessionDraft?>((ref) {
  return DraftSessionService.load();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patternsAsync = ref.watch(workoutPatternsProvider);
    final draftAsync = ref.watch(_draftProvider);
    final recentAsync = ref.watch(recentSessionsProvider);

    final draft = draftAsync.when(
      data: (d) => d,
      loading: () => null,
      error: (_, _) => null,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Gym Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentSessionsProvider);
          ref.invalidate(_draftProvider);
          ref.invalidate(workoutPatternsProvider);
        },
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            if (draft != null) ...[
              _ResumeCard(
                draft: draft,
                onResume: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SessionScreen(
                      pattern: draft.sessionState.pattern,
                      draft: draft,
                    ),
                  ));
                  ref.invalidate(_draftProvider);
                },
                onDiscard: () async {
                  await DraftSessionService.clear();
                  ref.invalidate(_draftProvider);
                },
              ),
              const SizedBox(height: 12),
            ],
            _StartTrainingCard(
              patternsAsync: patternsAsync,
              onPatternSelected: (pattern) async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SessionScreen(pattern: pattern),
                ));
                ref.invalidate(_draftProvider);
                ref.invalidate(recentSessionsProvider);
              },
            ),
            const SizedBox(height: 12),
            _ProgressCard(),
            const SizedBox(height: 24),
            _RecentSessionsSection(recentAsync: recentAsync),
          ],
        ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ExerciseSelectScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.show_chart, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                '種目の記録',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _RecentSessionsSection extends ConsumerWidget {
  final AsyncValue<List<WorkoutSession>> recentAsync;

  const _RecentSessionsSection({required this.recentAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '最近のトレーニング',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('すべて見る', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        recentAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                child: Text(
                  'まだ記録がありません',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              );
            }
            return Column(
              children: sessions
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RecentSessionTile(session: s),
                      ))
                  .toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Center(child: Text('エラー: $e')),
        ),
      ],
    );
  }
}

class _RecentSessionTile extends ConsumerWidget {
  final WorkoutSession session;

  const _RecentSessionTile({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patternAsync = ref.watch(workoutPatternByIdProvider(session.patternId));

    final patternName = patternAsync.when(
      data: (p) => p?.name ?? '不明なパターン',
      loading: () => '...',
      error: (_, _) => '不明なパターン',
    );

    final date = session.date.toLocal();
    final now = DateTime.now();
    final dateLabel = _formatDate(date, now);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SessionDetailScreen(session: session),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${date.month}/${date.day}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    dateLabel,
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 1,
              height: 32,
              color: Colors.grey.shade200,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                patternName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date, DateTime now) {
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    if (diff == 0) return '今日';
    if (diff == 1) return '昨日';
    return '$diff日前';
  }
}

// ---- 以下は変更なし ----

class _ResumeCard extends StatelessWidget {
  final SessionDraft draft;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  const _ResumeCard({
    required this.draft,
    required this.onResume,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final state = draft.sessionState;
    final current = state.currentExerciseIndex + 1;
    final total = state.exercises.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.pause_circle_outline,
                    color: Colors.orange.shade700, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '中断中のセッション',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      state.pattern.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '$current / $total種目目',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onDiscard,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[400],
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('破棄', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onResume,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('再開する',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartTrainingCard extends StatelessWidget {
  final AsyncValue<List<WorkoutPattern>> patternsAsync;
  final void Function(WorkoutPattern) onPatternSelected;

  const _StartTrainingCard({
    required this.patternsAsync,
    required this.onPatternSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPatternSheet(context),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今日のトレーニング',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '始める',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  void _showPatternSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PatternSelectSheet(
        patternsAsync: patternsAsync,
        onPatternSelected: onPatternSelected,
      ),
    );
  }
}

class _PatternSelectSheet extends StatelessWidget {
  final AsyncValue<List<WorkoutPattern>> patternsAsync;
  final void Function(WorkoutPattern) onPatternSelected;

  const _PatternSelectSheet({
    required this.patternsAsync,
    required this.onPatternSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'パターンを選択',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          patternsAsync.when(
            data: (patterns) => Column(
              children: patterns
                  .map((pattern) => _PatternTile(
                        pattern: pattern,
                        onTap: () {
                          Navigator.of(context).pop();
                          onPatternSelected(pattern);
                        },
                      ))
                  .toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('エラー: $e'),
          ),
        ],
      ),
    );
  }
}

class _PatternTile extends StatelessWidget {
  final WorkoutPattern pattern;
  final VoidCallback onTap;

  const _PatternTile({required this.pattern, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      title: Text(
        pattern.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${pattern.exercises.length}種目'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
