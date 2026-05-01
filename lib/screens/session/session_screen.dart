import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workout_pattern.dart';
import '../../providers/session_provider.dart';
import '../../providers/set_record_providers.dart';
import '../../models/set_record.dart';
import '../../providers/repository_providers.dart';
import '../../services/draft_session_service.dart';
import 'workout_completion_screen.dart';

class SessionScreen extends ConsumerStatefulWidget {
  final WorkoutPattern pattern;
  final SessionDraft? draft;

  const SessionScreen({super.key, required this.pattern, this.draft});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  late List<int> repsValues;
  late List<bool> completedValues;
  late List<TextEditingController> weightControllers;
  late SessionState _sessionState;
  bool _isInitialized = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    try {
      final draft = widget.draft;
      if (draft != null) {
        // ドラフトから復元
        setState(() {
          _sessionState = draft.sessionState;
          _isInitialized = true;
          repsValues = List.of(draft.repsValues);
          weightControllers = List.generate(
            draft.weightTexts.length,
            (i) => TextEditingController(text: draft.weightTexts[i]),
          );
        });
      } else {
        final exerciseRepo = ref.read(exerciseRepositoryProvider);
        final sessionState = await initializeSession(widget.pattern, exerciseRepo);
        await _initializeInputs(sessionState);
        setState(() {
          _sessionState = sessionState;
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _initializeInputs(SessionState sessionState) async {
    final index = sessionState.currentExerciseIndex;
    final targetSets = sessionState.pattern.exercises[index].targetSets;
    final exerciseId = sessionState.exercises[index].id;

    List<SetRecord> previousRecords = [];
    try {
      previousRecords = await ref.read(
        lastSessionSetRecordsByExerciseProvider(exerciseId).future,
      );
    } catch (_) {}

    repsValues = targetSets.map((s) => s.repsMin).toList();
    completedValues = List.filled(targetSets.length, false);
    weightControllers = List.generate(targetSets.length, (i) {
      final match = previousRecords.where((r) => r.setIndex == i).firstOrNull;
      final w = match?.weight;
      return TextEditingController(text: w != null ? _formatWeight(w) : '');
    });
  }

  String _formatWeight(double w) {
    if (w == w.truncateToDouble()) return w.toInt().toString();
    return w.toString();
  }

  Future<void> _suspend() async {
    await DraftSessionService.save(
      state: _sessionState,
      repsValues: repsValues,
      weightTexts: weightControllers.map((c) => c.text).toList(),
    );
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _disposeControllers() {
    for (final c in weightControllers) {
      c.dispose();
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('トレーニング中',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isInitialized ? _suspend : null,
            child: const Text('中断', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : _buildSessionView(),
    );
  }

  Widget _buildSessionView() {
    final currentExercise = _sessionState.currentExercise;
    final patternExercise =
        _sessionState.pattern.exercises[_sessionState.currentExerciseIndex];

    if (repsValues.length != patternExercise.targetSets.length) {
      _disposeControllers();
      _initializeInputs(_sessionState); // 非同期だが種目切替後に呼ばれる前提なので無視
    }

    final previousRecordsAsync = ref.watch(
      lastSessionSetRecordsByExerciseProvider(currentExercise.id),
    );

    return Column(
      children: [
        // 種目ヘッダー
        Container(
          color: Colors.white,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentExercise.name,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${_sessionState.currentExerciseIndex + 1} / ${_sessionState.exercises.length}種目',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // セットリスト
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: patternExercise.targetSets.length,
            itemBuilder: (context, setIndex) {
              final targetSet = patternExercise.targetSets[setIndex];
              final previousRecord = previousRecordsAsync.when(
                data: (records) {
                  final matches =
                      records.where((r) => r.setIndex == setIndex).toList();
                  return matches.isNotEmpty ? matches.first : null;
                },
                loading: () => null,
                error: (_, _) => null,
              );
              return _SetCard(
                setIndex: setIndex,
                targetLabel: targetSet.label,
                isBodyweight: currentExercise.isBodyweight,
                previousRecord: previousRecord != null
                    ? '前回: ${previousRecord.reps}回${previousRecord.weight != null ? ' / ${previousRecord.weight}kg' : ''}'
                    : null,
                reps: repsValues[setIndex],
                weightController: weightControllers[setIndex],
                completed: completedValues[setIndex],
                onRepsChanged: (value) {
                  setState(() => repsValues[setIndex] = value);
                },
                onCompletedToggled: () {
                  setState(() => completedValues[setIndex] = !completedValues[setIndex]);
                },
              );
            },
          ),
        ),
        // 次へ / スキップボタン
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _sessionState.currentExerciseIndex + 1 <
                            _sessionState.exercises.length
                        ? '次の種目へ'
                        : '完了',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_sessionState.currentExerciseIndex > 0) ...[
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: _handleBack,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: const BorderSide(color: Colors.black54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('前の種目へ'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _handleSkip,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Colors.black54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('スキップ'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleBack() {
    // 現在の種目の状態を保存してから戻る
    final currentExercise = _sessionState.currentExercise;
    final currentResults = List.generate(repsValues.length, (i) {
      return SetResult(
        setIndex: i,
        reps: repsValues[i],
        weight: double.tryParse(weightControllers[i].text),
        completed: completedValues[i],
      );
    });
    _sessionState = _sessionState.saveSetRecords(currentExercise.id, currentResults);

    final prevIndex = _sessionState.currentExerciseIndex - 1;
    final prevExercise = _sessionState.exercises[prevIndex];
    final prevPatternExercise = _sessionState.pattern.exercises[prevIndex];
    final savedResults = _sessionState.setRecords[prevExercise.id];

    setState(() {
      _sessionState = _sessionState.copyWith(currentExerciseIndex: prevIndex);
      _disposeControllers();

      if (savedResults != null && savedResults.isNotEmpty) {
        // 前回入力した値を復元
        repsValues = savedResults.map((r) => r.reps).toList();
        completedValues = savedResults.map((r) => r.completed).toList();
        weightControllers = savedResults
            .map((r) => TextEditingController(
                text: r.weight != null ? _formatWeight(r.weight!) : ''))
            .toList();
      } else {
        // 未入力だった場合はデフォルト値
        repsValues =
            prevPatternExercise.targetSets.map((s) => s.repsMin).toList();
        completedValues =
            List.filled(prevPatternExercise.targetSets.length, false);
        weightControllers = List.generate(
            prevPatternExercise.targetSets.length,
            (_) => TextEditingController());
      }
    });
    _scrollToTop();
  }

  Future<void> _handleSkip() async {
    final isLastExercise =
        _sessionState.currentExerciseIndex + 1 >= _sessionState.exercises.length;

    if (isLastExercise) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WorkoutCompletionScreen(sessionState: _sessionState),
        ),
      );
    } else {
      final nextState = _sessionState.copyWith(
        currentExerciseIndex: _sessionState.currentExerciseIndex + 1,
      );
      _disposeControllers();
      await _restoreOrInitialize(nextState);
      _scrollToTop();
    }
  }

  /// 次の種目に進む際、保存済み状態があれば復元し、なければFirestoreから初期化する
  Future<void> _restoreOrInitialize(SessionState nextState) async {
    final nextExercise = nextState.exercises[nextState.currentExerciseIndex];
    final savedResults = nextState.setRecords[nextExercise.id];

    if (savedResults != null && savedResults.isNotEmpty) {
      setState(() {
        _sessionState = nextState;
        repsValues = savedResults.map((r) => r.reps).toList();
        completedValues = savedResults.map((r) => r.completed).toList();
        weightControllers = savedResults
            .map((r) => TextEditingController(
                text: r.weight != null ? _formatWeight(r.weight!) : ''))
            .toList();
      });
    } else {
      await _initializeInputs(nextState);
      setState(() {
        _sessionState = nextState;
      });
    }
  }

  Future<void> _handleNext() async {
    final currentExercise = _sessionState.currentExercise;

    final setResults = List.generate(repsValues.length, (i) {
      return SetResult(
        setIndex: i,
        reps: repsValues[i],
        weight: double.tryParse(weightControllers[i].text),
        completed: completedValues[i],
      );
    });

    _sessionState = _sessionState.saveSetRecords(currentExercise.id, setResults);

    final isLastExercise =
        _sessionState.currentExerciseIndex + 1 >= _sessionState.exercises.length;

    if (isLastExercise) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WorkoutCompletionScreen(sessionState: _sessionState),
        ),
      );
    } else {
      final nextState = _sessionState.copyWith(
        currentExerciseIndex: _sessionState.currentExerciseIndex + 1,
      );
      _disposeControllers();
      await _restoreOrInitialize(nextState);
      _scrollToTop();
    }
  }
}

class _SetCard extends StatelessWidget {
  final int setIndex;
  final String targetLabel;
  final bool isBodyweight;
  final String? previousRecord;
  final int reps;
  final TextEditingController weightController;
  final bool completed;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onCompletedToggled;

  const _SetCard({
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
            // SET番号 + 目標 + 完了チェック
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
                      style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
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
            // 入力行
            Row(
              children: [
                // 回数 ± ボタン
                Text('回数', style: TextStyle(fontSize: 13, color: completed ? Colors.green.shade600 : Colors.grey)),
                const SizedBox(width: 12),
                _RepsCounter(
                  value: reps,
                  onDecrement: () => onRepsChanged(reps > 0 ? reps - 1 : 0),
                  onIncrement: () => onRepsChanged(reps + 1),
                  completed: completed,
                ),
                const SizedBox(width: 20),
                // 重量入力
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                Text('kg', style: TextStyle(fontSize: 13, color: completed ? Colors.green.shade600 : Colors.grey)),
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
