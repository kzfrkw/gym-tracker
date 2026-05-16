import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/workout_session.dart';
import '../../../providers/workout_pattern_providers.dart';
import '../../history/history_screen.dart';
import '../../history/session_detail_screen.dart';

class RecentSessionsSection extends ConsumerWidget {
  final AsyncValue<List<WorkoutSession>> recentAsync;

  const RecentSessionsSection({super.key, required this.recentAsync});

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
    final patternAsync =
        ref.watch(workoutPatternByIdProvider(session.patternId));

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
