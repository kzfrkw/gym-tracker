import 'package:flutter/material.dart';
import '../../../models/target_set.dart';

class SetEditorSheet extends StatefulWidget {
  final String exerciseName;
  final List<TargetSet> initialSets;
  final void Function(List<TargetSet>) onSaved;

  const SetEditorSheet({
    super.key,
    required this.exerciseName,
    required this.initialSets,
    required this.onSaved,
  });

  @override
  State<SetEditorSheet> createState() => _SetEditorSheetState();
}

class _SetEditorSheetState extends State<SetEditorSheet> {
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
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('セット設定',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 16),
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
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ),
                  Expanded(child: _RepsField(controller: minCtrl)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('〜', style: TextStyle(color: Colors.grey)),
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
