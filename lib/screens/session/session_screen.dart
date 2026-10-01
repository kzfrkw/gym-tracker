import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workout_pattern.dart';
import '../../providers/session_provider.dart';
import '../../providers/set_record_providers.dart';
import '../../models/set_record.dart';
import '../../providers/repository_providers.dart';
import '../../services/draft_session_service.dart';
import '../../models/exercise.dart';
import '../../widgets/exercise_picker_sheet.dart';
import 'widgets/exercise_header.dart';
import 'widgets/set_card.dart';
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
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onInactive: _autoSave,
      onPause: _autoSave,
    );
    _initializeSession();
  }

  Future<void> _autoSave() async {
    if (!_isInitialized) return;
    await DraftSessionService.save(
      state: _sessionState,
      repsValues: repsValues,
      weightTexts: weightControllers.map((c) => c.text).toList(),
      completedValues: completedValues,
    );
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
          completedValues = draft.completedValues.isNotEmpty
              ? List.of(draft.completedValues)
              : List.filled(draft.repsValues.length, false);
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
      completedValues: completedValues,
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
    _lifecycleListener.dispose();
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
        ExerciseHeader(
          exerciseName: currentExercise.name,
          position: _sessionState.currentExerciseIndex + 1,
          total: _sessionState.exercises.length,
          onChangePressed: _handleChangeExercise,
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
              return SetCard(
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

  /// 今日のセッションだけ、現在の種目を別の種目に差し替える
  Future<void> _handleChangeExercise() async {
    if (completedValues.any((c) => c)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('種目を変更しますか？'),
          content: const Text('この種目で完了チェックしたセットの記録は破棄されます。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('変更する'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    final selected = await showModalBottomSheet<Exercise>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ExercisePickerSheet(
        alreadyAdded: _sessionState.exercises.map((e) => e.id).toSet(),
        onSelected: (exercise) => Navigator.of(context).pop(exercise),
      ),
    );
    if (selected == null || !mounted) return;

    final nextState = _sessionState.replaceExercise(
        _sessionState.currentExerciseIndex, selected);
    final oldControllers = weightControllers;
    await _initializeInputs(nextState);
    if (!mounted) return;
    setState(() => _sessionState = nextState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in oldControllers) {
        c.dispose();
      }
    });
    _scrollToTop();
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

