import 'package:flutter/material.dart';

class SetCard extends StatelessWidget {
  final int setIndex;
  final String targetLabel;
  final bool isBodyweight;
  final String? previousRecord;
  final int reps;
  final TextEditingController weightController;
  final bool completed;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onCompletedToggled;

  const SetCard({
    super.key,
    required this.setIndex,
    required this.targetLabel,
    required this.isBodyweight,
    required this.previousRecord,
    required this.reps,
    required this.weightController,
    required this.completed,
    required this.onRepsChanged,
    required this.onCompletedToggled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCompletedToggled,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: completed ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: completed
              ? Border.all(color: Colors.green.shade300, width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'SET ${setIndex + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: completed ? Colors.green.shade700 : Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  targetLabel,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                if (isBodyweight) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      '自重',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const Spacer(),
                if (previousRecord != null)
                  Text(
                    previousRecord!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                const SizedBox(width: 8),
                Icon(
                  completed ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: completed ? Colors.green : Colors.grey.shade400,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text('回数',
                    style: TextStyle(
                        fontSize: 13,
                        color: completed
                            ? Colors.green.shade600
                            : Colors.grey)),
                const SizedBox(width: 12),
                _RepsCounter(
                  value: reps,
                  onDecrement: () => onRepsChanged(reps > 0 ? reps - 1 : 0),
                  onIncrement: () => onRepsChanged(reps + 1),
                  completed: completed,
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    onTap: () {
                      weightController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: weightController.text.length,
                      );
                    },
                    decoration: InputDecoration(
                      hintText: isBodyweight ? '0' : '—',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: completed
                              ? Colors.green.shade300
                              : isBodyweight
                                  ? Colors.blue.shade200
                                  : Colors.grey.shade300,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text('kg',
                    style: TextStyle(
                        fontSize: 13,
                        color: completed
                            ? Colors.green.shade600
                            : Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RepsCounter extends StatelessWidget {
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool completed;

  const _RepsCounter({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    this.completed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CounterButton(icon: Icons.remove, onTap: onDecrement),
        SizedBox(
          width: 44,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: completed ? Colors.green.shade700 : Colors.black,
            ),
          ),
        ),
        _CounterButton(icon: Icons.add, onTap: onIncrement),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CounterButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
