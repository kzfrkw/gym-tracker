import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/workout_pattern.dart';
import '../../providers/repository_providers.dart';
import '../../providers/workout_pattern_providers.dart';
import 'pattern_edit_screen.dart';

class PatternListScreen extends ConsumerWidget {
  const PatternListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patternsAsync = ref.watch(workoutPatternsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('パターン管理',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final name = await _showCreateDialog(context);
          if (name == null || name.isEmpty) return;
          final newPattern = WorkoutPattern(
            id: const Uuid().v4(),
            name: name,
            exercises: [],
          );
          await ref.read(workoutPatternRepositoryProvider).create(newPattern);
          ref.invalidate(workoutPatternsProvider);
          if (context.mounted) {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PatternEditScreen(pattern: newPattern),
            ));
            ref.invalidate(workoutPatternsProvider);
          }
        },
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: patternsAsync.when(
        data: (patterns) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: patterns.length,
          itemBuilder: (context, index) {
            final pattern = patterns[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                title: Text(
                  pattern.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  '${pattern.exercises.length}種目',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PatternEditScreen(pattern: pattern),
                    ));
                    ref.invalidate(workoutPatternsProvider);
                  },
                  child: const Text('編集'),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
      ),
    );
  }
}

Future<String?> _showCreateDialog(BuildContext context) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('パターン名'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: '例: 胸・肩・三頭'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('作成', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
