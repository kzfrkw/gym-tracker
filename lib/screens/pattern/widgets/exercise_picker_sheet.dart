import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/exercise.dart';
import '../../../providers/exercise_providers.dart';
import '../../../providers/repository_providers.dart';

class ExercisePickerSheet extends ConsumerStatefulWidget {
  final Set<String> alreadyAdded;
  final void Function(Exercise) onSelected;

  const ExercisePickerSheet({
    super.key,
    required this.alreadyAdded,
    required this.onSelected,
  });

  @override
  ConsumerState<ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  Future<void> _showCreateDialog() async {
    final nameController = TextEditingController();
    bool isBodyweight = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('種目を新規登録'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: '種目名',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('自重トレーニング',
                    style: TextStyle(fontSize: 14)),
                value: isBodyweight,
                onChanged: (v) =>
                    setDialogState(() => isBodyweight = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final exercise = Exercise(
                  id: const Uuid().v4(),
                  name: name,
                  isBodyweight: isBodyweight,
                );
                final repo = ref.read(exerciseRepositoryProvider);
                await repo.create(exercise);
                ref.invalidate(exercisesProvider);

                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('登録',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    // dispose はしない（クローズアニメーション中に呼ぶとクラッシュするため）
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final exercises = exercisesAsync.when(
      data: (list) => list,
      loading: () => <Exercise>[],
      error: (_, _) => <Exercise>[],
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
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
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('種目を選択',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('新規登録', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: exercisesAsync.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      controller: scrollController,
                      children: exercises.map((exercise) {
                        final isAdded =
                            widget.alreadyAdded.contains(exercise.id);
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          title: Text(
                            exercise.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isAdded ? Colors.grey[400] : Colors.black,
                            ),
                          ),
                          trailing: isAdded
                              ? Icon(Icons.check,
                                  color: Colors.grey[400], size: 18)
                              : null,
                          onTap: isAdded
                              ? null
                              : () => widget.onSelected(exercise),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
