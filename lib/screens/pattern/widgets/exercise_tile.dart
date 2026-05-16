import 'package:flutter/material.dart';
import 'exercise_entry.dart';

class ExerciseTile extends StatelessWidget {
  final ExerciseEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onEditSets;

  const ExerciseTile({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onEditSets,
  });

  @override
  Widget build(BuildContext context) {
    final setCount = entry.targetSets.length;
    final firstSet = entry.targetSets.first;
    final setLabel = firstSet.repsMin == firstSet.repsMax
        ? '${firstSet.repsMin}回 × $setCount'
        : '${firstSet.repsMin}〜${firstSet.repsMax}回 × $setCount';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.drag_handle, color: Colors.grey),
        title: Text(entry.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: GestureDetector(
          onTap: onEditSets,
          child: Row(
            children: [
              Text(setLabel,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(width: 4),
              Icon(Icons.edit, size: 11, color: Colors.grey[400]),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
