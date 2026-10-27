import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/strings.dart';
import 'core/theme/app_theme.dart';
import 'data/progress_providers.dart';
import 'features/home/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: CSEasyApp()));
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
      home: const HomeScreen(),
    );
  }
}
