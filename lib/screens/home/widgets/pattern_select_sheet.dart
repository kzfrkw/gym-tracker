import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/workout_pattern.dart';

class PatternSelectSheet extends StatelessWidget {
  final AsyncValue<List<WorkoutPattern>> patternsAsync;
  final void Function(WorkoutPattern) onPatternSelected;

  const PatternSelectSheet({
    super.key,
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
