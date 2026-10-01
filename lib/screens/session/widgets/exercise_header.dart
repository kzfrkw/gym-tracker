import 'package:flutter/material.dart';

class ExerciseHeader extends StatelessWidget {
  final String exerciseName;
  final int position; // 1始まり
  final int total;
  final VoidCallback onChangePressed;

  const ExerciseHeader({
    super.key,
    required this.exerciseName,
    required this.position,
    required this.total,
    required this.onChangePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exerciseName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$position / $total種目',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onChangePressed,
            icon: const Icon(Icons.swap_horiz, size: 18),
            label: const Text('変更'),
            style: TextButton.styleFrom(foregroundColor: Colors.black87),
          ),
        ],
      ),
    );
  }
}
