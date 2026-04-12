import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/history_providers.dart';
import '../../providers/workout_pattern_providers.dart';
import 'session_detail_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedMonth = ref.watch(historyFocusedMonthProvider);
    final selectedDay = ref.watch(historySelectedDayProvider);
    final sessionsAsync = ref.watch(sessionsByMonthProvider(focusedMonth));

    final sessionMap = sessionsAsync.when(
      data: (m) => m,
      loading: () => <DateTime, List<dynamic>>{},
      error: (_, _) => <DateTime, List<dynamic>>{},
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('トレーニング履歴',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // カレンダー
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 8),
            child: TableCalendar(
              firstDay: DateTime(2020, 1, 1),
              lastDay: DateTime(2100, 12, 31),
              focusedDay: focusedMonth,
              selectedDayPredicate: (day) =>
                  selectedDay != null && isSameDay(day, selectedDay),
              eventLoader: (day) {
                final key = DateTime(day.year, day.month, day.day);
                return sessionMap[key] ?? [];
              },
              onDaySelected: (selected, focused) {
                ref.read(historySelectedDayProvider.notifier).select(selected);
                ref.read(historyFocusedMonthProvider.notifier).setMonth(focused);
              },
              onPageChanged: (focused) {
                ref.read(historyFocusedMonthProvider.notifier).setMonth(focused);
                ref.read(historySelectedDayProvider.notifier).select(null);
              },
              calendarStyle: const CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Color(0xFF555555),
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(color: Colors.white),
                todayTextStyle: TextStyle(color: Colors.white),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          // セッション一覧
          Expanded(child: _buildSessionList(context, ref, selectedDay)),
        ],
      ),
    );
  }

  Widget _buildSessionList(
    BuildContext context,
    WidgetRef ref,
    DateTime? selectedDay,
  ) {
    if (selectedDay == null) {
      return const Center(
        child: Text(
          '日付を選択してください',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    final sessionsAsync = ref.watch(selectedDaySessionsProvider);
    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return const Center(
            child: Text(
              'この日の記録はありません',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) =>
              _SessionCard(session: sessions[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('エラー: $e')),
    );
  }
}

class _SessionCard extends ConsumerWidget {
  final dynamic session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patternAsync =
        ref.watch(workoutPatternByIdProvider(session.patternId));

    final patternName = patternAsync.when(
      data: (p) => p?.name ?? '不明なパターン',
      loading: () => '読み込み中...',
      error: (_, _) => '不明なパターン',
    );

    final date = (session.date as DateTime).toLocal();
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SessionDetailScreen(session: session),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fitness_center, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patternName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$timeStr 開始',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
