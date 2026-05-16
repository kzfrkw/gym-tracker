import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/exercise.dart';
import '../../providers/exercise_progress_provider.dart';
import '../../providers/set_record_providers.dart';
import '../../utils/chart_utils.dart';

class ExerciseProgressScreen extends ConsumerWidget {
  final Exercise exercise;

  const ExerciseProgressScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(exerciseProgressProvider(exercise.id));
    final best1RMAsync = ref.watch(allTimeBest1RMProvider(exercise.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Text(
                'まだ記録がありません',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final allTimeBestWeight = entries
              .map((e) => e.maxWeight)
              .reduce((a, b) => a > b ? a : b);
          final best1RM = best1RMAsync.when(
            data: (v) => v,
            loading: () => null,
            error: (_, _) => null,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BestRecordCard(bestWeight: allTimeBestWeight, best1RM: best1RM),
              const SizedBox(height: 16),
              _ChartCard(entries: entries),
              const SizedBox(height: 16),
              _HistoryList(entries: entries),
            ],
          );
        },
      ),
    );
  }
}

class _BestRecordCard extends StatelessWidget {
  final double bestWeight;
  final double? best1RM;

  const _BestRecordCard({required this.bestWeight, required this.best1RM});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          _StatItem(label: 'ベスト重量', value: '${bestWeight.toStringAsFixed(bestWeight == bestWeight.truncateToDouble() ? 0 : 1)}kg'),
          const SizedBox(width: 24),
          if (best1RM != null)
            _StatItem(label: '推定1RM', value: '${best1RM!.toStringAsFixed(1)}kg'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final List<ExerciseProgressEntry> entries;

  const _ChartCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final spots = entries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.maxWeight);
    }).toList();

    final maxY = entries.map((e) => e.maxWeight).reduce((a, b) => a > b ? a : b);
    final minY = entries.map((e) => e.maxWeight).reduce((a, b) => a < b ? a : b);
    final yPadding = ((maxY - minY) * 0.2).clamp(5.0, double.infinity);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              '最大重量の推移 (kg)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: (minY - yPadding).clamp(0, double.infinity),
                maxY: maxY + yPadding,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: niceYInterval(maxY - minY),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, _) => Text(
                        '${value.toInt()}',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: bottomXInterval(entries.length),
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        final date = entries[idx].date.toLocal();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${date.month}/${date.day}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: Colors.black,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, _, _, _) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: Colors.black,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _HistoryList extends StatelessWidget {
  final List<ExerciseProgressEntry> entries;

  const _HistoryList({required this.entries});

  @override
  Widget build(BuildContext context) {
    // 新しい順に表示
    final reversed = entries.reversed.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              '記録一覧',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const Divider(height: 1),
          ...reversed.asMap().entries.map((e) {
            final index = e.key;
            final entry = e.value;
            final date = entry.date.toLocal();
            final dateStr =
                '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
            final isLast = index == reversed.length - 1;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.grey),
                      ),
                      const Spacer(),
                      Text(
                        '${entry.maxWeight}kg',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${entry.setCount}セット',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (!isLast) const Divider(height: 1, indent: 16),
              ],
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
