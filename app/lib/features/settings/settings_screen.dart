import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/strings.dart';
import '../../data/settings_providers.dart';
import '../onboarding/level_picker_screen.dart';

/// Asks for the exam date and saves it. Shared by home and settings.
Future<void> pickExamDate(BuildContext context, WidgetRef ref) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final current = ref.read(examDateProvider);
  final picked = await showDatePicker(
    context: context,
    helpText: Strings.examDateHelp,
    firstDate: today,
    lastDate: DateTime(today.year + 2, today.month, today.day),
    initialDate: current != null && !current.isBefore(today)
        ? current
        : DateTime(today.year, today.month, today.day + 30),
  );
  if (picked != null) await ref.read(examDateProvider.notifier).set(picked);
}

String formatDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

final _packageInfoProvider = FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static void open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(examLevelProvider);
    final examDate = ref.watch(examDateProvider);
    final goal = ref.watch(dailyGoalProvider);
    final themeMode = ref.watch(themeModeProvider);
    final textSize = ref.watch(textSizeProvider);
    final version = ref.watch(_packageInfoProvider).valueOrNull?.version;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(Strings.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            title: const Text(Strings.examLevel),
            subtitle: Text(level?.label ?? Strings.notSet),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const LevelPickerScreen(popOnSelect: true)),
            ),
          ),
          ListTile(
            title: const Text(Strings.examDate),
            subtitle: Text(examDate == null ? Strings.notSet : formatDate(examDate)),
            onTap: () => pickExamDate(context, ref),
            trailing: examDate == null
                ? const Icon(Icons.event)
                : TextButton(
                    onPressed: () => ref.read(examDateProvider.notifier).set(null),
                    child: const Text(Strings.clear),
                  ),
          ),
          _Section(
            title: Strings.dailyGoal,
            hint: Strings.dailyGoalHint,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (final g in dailyGoalOptions) ButtonSegment(value: g, label: Text('$g')),
              ],
              selected: {goal},
              onSelectionChanged: (s) => ref.read(dailyGoalProvider.notifier).set(s.single),
            ),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(Strings.appearance, style: textTheme.titleSmall),
          ),
          _Section(
            title: Strings.theme,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text(Strings.themeSystem)),
                ButtonSegment(value: ThemeMode.light, label: Text(Strings.themeLight)),
                ButtonSegment(value: ThemeMode.dark, label: Text(Strings.themeDark)),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.single),
            ),
          ),
          _Section(
            title: Strings.textSize,
            hint: Strings.textSizeHint,
            child: SegmentedButton<TextSize>(
              showSelectedIcon: false,
              segments: [
                for (final size in TextSize.values) ButtonSegment(value: size, label: Text(size.label)),
              ],
              selected: {textSize},
              onSelectionChanged: (s) => ref.read(textSizeProvider.notifier).set(s.single),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Card.outlined(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(Strings.textPreview, style: textTheme.titleMedium),
              ),
            ),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(Strings.about, style: textTheme.titleSmall),
          ),
          ListTile(
            title: const Text(Strings.privacyPolicy),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(
              Uri.parse(Strings.privacyPolicyUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          if (version != null)
            ListTile(title: const Text(Strings.version), subtitle: Text(version)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? hint;
  final Widget child;

  const _Section({required this.title, this.hint, required this.child});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.bodyLarge),
          if (hint != null) Text(hint!, style: textTheme.bodySmall),
          const SizedBox(height: 8),
          // Full width, so segments share the space instead of overflowing.
          SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }
}
