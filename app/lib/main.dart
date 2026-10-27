import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/strings.dart';
import 'core/theme/app_theme.dart';
import 'data/progress_providers.dart';
import 'data/settings_providers.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/level_picker_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const CSEasyApp(),
  ));
}

class CSEasyApp extends ConsumerStatefulWidget {
  const CSEasyApp({super.key});

  @override
  ConsumerState<CSEasyApp> createState() => _CSEasyAppState();
}

class _CSEasyAppState extends ConsumerState<CSEasyApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(clockProvider.notifier).state = DateTime.now(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Strings.appName,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: ref.watch(examLevelProvider) == null ? const LevelPickerScreen() : const HomeScreen(),
    );
  }
}
