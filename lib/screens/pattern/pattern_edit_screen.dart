import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/exercise.dart';
import '../../models/pattern_exercise.dart';
import '../../models/target_set.dart';
import '../../models/workout_pattern.dart';
import '../../providers/exercise_providers.dart';
import '../../providers/repository_providers.dart';
import 'widgets/exercise_entry.dart';
import 'widgets/exercise_picker_sheet.dart';
import 'widgets/exercise_tile.dart';
import 'widgets/set_editor_sheet.dart';

class PatternEditScreen extends ConsumerStatefulWidget {
  final WorkoutPattern pattern;

  const PatternEditScreen({super.key, required this.pattern});

  @override
  ConsumerState<PatternEditScreen> createState() => _PatternEditScreenState();
}

class _PatternEditScreenState extends ConsumerState<PatternEditScreen> {
  late TextEditingController _nameController;
  List<ExerciseEntry> _entries = [];
  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pattern.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initEntries(List<Exercise> allExercises) {
    final nameMap = {for (final e in allExercises) e.id: e.name};
    final sorted = List.of(widget.pattern.exercises)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    _entries = sorted
        .map((pe) => ExerciseEntry(
              exerciseId: pe.exerciseId,
              name: nameMap[pe.exerciseId] ?? '不明な種目',
              targetSets: pe.targetSets,
            ))
        .toList();
    _isInitialized = true;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final updatedPattern = WorkoutPattern(
        id: widget.pattern.id,
        name: _nameController.text.trim(),
        exercises: _entries.asMap().entries.map((e) {
          return PatternExercise(
            exerciseId: e.value.exerciseId,
            sortOrder: e.key,
            targetSets: e.value.targetSets,
          );
        }).toList(),
      );

      final repo = ref.read(workoutPatternRepositoryProvider);
      await repo.update(updatedPattern);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showExercisePicker() {
    final alreadyAdded = _entries.map((e) => e.exerciseId).toSet();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ExercisePickerSheet(
        alreadyAdded: alreadyAdded,
        onSelected: (exercise) {
          Navigator.of(context).pop();
          setState(() {
            _entries.add(ExerciseEntry(
              exerciseId: exercise.id,
              name: exercise.name,
              targetSets: [const TargetSet(repsMin: 8, repsMax: 10)],
            ));
          });
        },
      ),
    );
  }

  void _showSetEditor(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SetEditorSheet(
        exerciseName: _entries[index].name,
        initialSets: _entries[index].targetSets,
        onSaved: (newSets) {
          setState(() => _entries[index].targetSets = newSets);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return exercisesAsync.when(
      data: (allExercises) {
        if (!_isInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _initEntries(allExercises));
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildContent();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('エラー: $e')),
      ),
    );
  }

  Widget _buildContent() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('パターン編集',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('保存',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'パターン名',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text('種目',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500)),
                const Spacer(),
                Text('長押しで並び替え',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _entries.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _entries.removeAt(oldIndex);
                  _entries.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return ExerciseTile(
                  key: ValueKey(entry.exerciseId + index.toString()),
                  entry: entry,
                  onDelete: () => setState(() => _entries.removeAt(index)),
                  onEditSets: () => _showSetEditor(index),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _showExercisePicker,
                icon: const Icon(Icons.add),
                label: const Text('種目を追加'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
