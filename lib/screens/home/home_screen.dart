import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workout_pattern_providers.dart';
import '../../providers/history_providers.dart';
import '../../services/draft_session_service.dart';
import '../session/session_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/progress_card.dart';
import 'widgets/recent_sessions_section.dart';
import 'widgets/resume_card.dart';
import 'widgets/start_training_card.dart';

final _draftProvider = FutureProvider.autoDispose<SessionDraft?>((ref) {
  return DraftSessionService.load();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _autoNavigated = false;

  @override
  Widget build(BuildContext context) {
    final patternsAsync = ref.watch(workoutPatternsProvider);
    final draftAsync = ref.watch(_draftProvider);
    final recentAsync = ref.watch(recentSessionsProvider);

    ref.listen<AsyncValue<SessionDraft?>>(_draftProvider, (_, next) {
      next.whenData((draft) {
        if (draft == null) {
          if (_autoNavigated) setState(() => _autoNavigated = false);
          return;
        }
        if (!_autoNavigated) {
          _autoNavigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SessionScreen(
                pattern: draft.sessionState.pattern,
                draft: draft,
              ),
            ));
            if (mounted) ref.invalidate(_draftProvider);
          });
        }
      });
    });

    final draft = draftAsync.when(
      data: (d) => d,
      loading: () => null,
      error: (_, _) => null,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Gym Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentSessionsProvider);
          ref.invalidate(_draftProvider);
          ref.invalidate(workoutPatternsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              if (draft != null) ...[
                ResumeCard(
                  draft: draft,
                  onResume: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SessionScreen(
                        pattern: draft.sessionState.pattern,
                        draft: draft,
                      ),
                    ));
                    ref.invalidate(_draftProvider);
                  },
                  onDiscard: () async {
                    await DraftSessionService.clear();
                    ref.invalidate(_draftProvider);
                  },
                ),
                const SizedBox(height: 12),
              ],
              StartTrainingCard(
                patternsAsync: patternsAsync,
                onPatternSelected: (pattern) async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SessionScreen(pattern: pattern),
                  ));
                  ref.invalidate(_draftProvider);
                  ref.invalidate(recentSessionsProvider);
                },
              ),
              const SizedBox(height: 12),
              const ProgressCard(),
              const SizedBox(height: 24),
              RecentSessionsSection(recentAsync: recentAsync),
            ],
          ),
        ),
      ),
    );
  }
}
