import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/exercise.dart';
import '../../models/pattern_exercise.dart';
import '../../models/target_set.dart';
import '../../models/workout_pattern.dart';
import '../../providers/exercise_providers.dart';
import '../../providers/repository_providers.dart';

// 編集中の種目エントリ（ローカル状態用）
class _ExerciseEntry {
  final String exerciseId;
  final String name;
  List<TargetSet> targetSets;

  _ExerciseEntry({
    required this.exerciseId,
    required this.name,
    required List<TargetSet> targetSets,
  }) : targetSets = List.of(targetSets);
}

class PatternEditScreen extends ConsumerStatefulWidget {
  final WorkoutPattern pattern;

  const PatternEditScreen({super.key, required this.pattern});

  @override
  ConsumerState<PatternEditScreen> createState() => _PatternEditScreenState();
}

class _PatternEditScreenState extends ConsumerState<PatternEditScreen> {
  late TextEditingController _nameController;
  List<_ExerciseEntry> _entries = [];
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
        .map((pe) => _ExerciseEntry(
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
      builder: (context) => _ExercisePickerSheet(
        alreadyAdded: alreadyAdded,
        onSelected: (exercise) {
          Navigator.of(context).pop();
          setState(() {
            _entries.add(_ExerciseEntry(
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
      builder: (context) => _SetEditorSheet(
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
        return _buildContent(allExercises);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('エラー: $e')),
      ),
    );
  }

  Widget _buildContent(List<Exercise> allExercises) {
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
          // パターン名
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
          // 種目リストヘッダー
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
          // 種目リスト
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
                return _ExerciseTile(
                  key: ValueKey(entry.exerciseId + index.toString()),
                  entry: entry,
                  onDelete: () => setState(() => _entries.removeAt(index)),
                  onEditSets: () => _showSetEditor(index),
                );
              },
            ),
          ),
          // 種目を追加ボタン
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _showExercisePicker(),
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

class _ExerciseTile extends StatelessWidget {
  final _ExerciseEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onEditSets;

  const _ExerciseTile({
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

class _ExercisePickerSheet extends ConsumerStatefulWidget {
  final Set<String> alreadyAdded;
  final void Function(Exercise) onSelected;

  const _ExercisePickerSheet({
    required this.alreadyAdded,
    required this.onSelected,
  });

  @override
  ConsumerState<_ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
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
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
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
                              color:
                                  isAdded ? Colors.grey[400] : Colors.black,
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

class _SetEditorSheet extends StatefulWidget {
  final String exerciseName;
  final List<TargetSet> initialSets;
  final void Function(List<TargetSet>) onSaved;

  const _SetEditorSheet({
    required this.exerciseName,
    required this.initialSets,
    required this.onSaved,
  });

  @override
  State<_SetEditorSheet> createState() => _SetEditorSheetState();
}

class _SetEditorSheetState extends State<_SetEditorSheet> {
  late List<(TextEditingController, TextEditingController)> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.initialSets
        .map((s) => (
              TextEditingController(text: s.repsMin.toString()),
              TextEditingController(text: s.repsMax.toString()),
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final (min, max) in _controllers) {
      min.dispose();
      max.dispose();
    }
    super.dispose();
  }

  void _addSet() {
    final last = _controllers.isNotEmpty ? _controllers.last : null;
    setState(() {
      _controllers.add((
        TextEditingController(text: last?.$1.text ?? '8'),
        TextEditingController(text: last?.$2.text ?? '10'),
      ));
    });
  }

  void _removeSet(int index) {
    if (_controllers.length <= 1) return;
    final (min, max) = _controllers.removeAt(index);
    min.dispose();
    max.dispose();
    setState(() {});
  }

  void _save() {
    final sets = _controllers.map((c) {
      final min = int.tryParse(c.$1.text) ?? 8;
      final max = int.tryParse(c.$2.text) ?? 10;
      return TargetSet(repsMin: min, repsMax: max > min ? max : min);
    }).toList();
    widget.onSaved(sets);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
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
          const SizedBox(height: 16),
          Text(widget.exerciseName,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('セット設定',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 16),
          // ヘッダー
          Row(
            children: [
              const SizedBox(width: 56),
              Expanded(
                child: Text('最小回数',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text('最大回数',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 8),
          ..._controllers.asMap().entries.map((e) {
            final index = e.key;
            final (minCtrl, maxCtrl) = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text('SET ${index + 1}',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600])),
                  ),
                  Expanded(child: _RepsField(controller: minCtrl)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('〜',
                        style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: _RepsField(controller: maxCtrl)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _controllers.length > 1
                        ? () => _removeSet(index)
                        : null,
                    child: Icon(
                      Icons.remove_circle_outline,
                      color: _controllers.length > 1
                          ? Colors.red
                          : Colors.grey[300],
                      size: 22,
                    ),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: _addSet,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('セットを追加'),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('決定',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepsField extends StatelessWidget {
  final TextEditingController controller;

  const _RepsField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        suffixText: '回',
        suffixStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
    );
  }
}
