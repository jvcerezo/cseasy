import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content/question.dart';
import '../../core/strings.dart';
import '../../data/settings_providers.dart';

/// First-launch screen; also reused from home to switch levels.
class LevelPickerScreen extends ConsumerWidget {
  /// Pops after choosing when opened from home; on first launch the root
  /// rebuilds into the home screen instead.
  final bool popOnSelect;

  const LevelPickerScreen({super.key, this.popOnSelect = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(examLevelProvider);
    final textTheme = Theme.of(context).textTheme;

    Future<void> choose(ExamLevel level) async {
      await ref.read(examLevelProvider.notifier).set(level);
      if (popOnSelect && context.mounted) Navigator.of(context).pop();
    }

    return Scaffold(
      appBar: popOnSelect ? AppBar() : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (!popOnSelect) ...[
              const SizedBox(height: 32),
              Text(Strings.appName, style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(Strings.tagline, style: textTheme.titleMedium),
              const SizedBox(height: 40),
            ],
            Text(Strings.whichLevel, style: textTheme.titleLarge),
            const SizedBox(height: 16),
            _LevelCard(
              title: ExamLevel.professional.label,
              description: Strings.professionalDescription,
              selected: current == ExamLevel.professional,
              onTap: () => choose(ExamLevel.professional),
            ),
            const SizedBox(height: 12),
            _LevelCard(
              title: ExamLevel.subprofessional.label,
              description: Strings.subprofessionalDescription,
              selected: current == ExamLevel.subprofessional,
              onTap: () => choose(ExamLevel.subprofessional),
            ),
            const SizedBox(height: 16),
            Text(Strings.levelChangeLater, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _LevelCard({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card.outlined(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(description, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
