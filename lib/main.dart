import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'repositories/auth_repository.dart';
import 'providers/auth_providers.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'dev/demo_data_seeder.dart';
import 'providers/workout_pattern_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthRepository.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const AuthGate(),
    );
  }
}

/// 認証状態に応じて LoginScreen / HomeScreen を切り替えるウィジェット
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('エラーが発生しました: $e')),
      ),
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        // ログイン後にデモデータをシード（dev環境のみ）
        if (!kReleaseMode) {
          _seedDemoDataIfNeeded(ref, user.uid);
        }

        return const HomeScreen();
      },
    );
  }

  void _seedDemoDataIfNeeded(WidgetRef ref, String userId) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final seeded = await DemoDataSeeder.seedIfNeeded(userId: userId);
      if (seeded) {
        // シードしたらパターン一覧を再フェッチさせる
        ref.invalidate(workoutPatternsProvider);
      }
    });
  }
}
