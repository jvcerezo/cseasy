import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content/content_providers.dart';
import '../../core/content/question.dart';
import '../../core/content/question_bank.dart';
import '../../core/content/topic_labels.dart';
import '../../core/strings.dart';
import '../practice/practice_controller.dart';
import '../practice/practice_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bank = ref.watch(questionBankProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.appName)),
      body: bank.when(
        data: (bank) => _TopicList(bank: bank),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(Strings.loadError),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(questionBankProvider),
                child: const Text(Strings.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicList extends StatelessWidget {
  final QuestionBank bank;

  const _TopicList({required this.bank});

  void _open(BuildContext context, PracticeScope scope) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PracticeScreen(scope: scope)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Text(Strings.tagline, style: textTheme.bodyLarge),
        ),
        for (final section in bank.sections) ...[
          _SectionHeader(
            section: section,
            onMixed: () => _open(context, PracticeScope.section(section)),
          ),
          for (final topic in bank.topicsBySection[section]!)
            ListTile(
              title: Text(topicLabel(topic)),
              subtitle: Text(Strings.questionCount(bank.byTopic(topic).length)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, PracticeScope.topic(section, topic)),
            ),
          const Divider(height: 24),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final Section section;
  final VoidCallback onMixed;

  const _SectionHeader({required this.section, required this.onMixed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(section.label, style: Theme.of(context).textTheme.titleMedium),
          ),
          TextButton.icon(
            onPressed: onMixed,
            icon: const Icon(Icons.shuffle),
            label: const Text(Strings.mixedPractice),
          ),
        ],
      ),
    );
  }
}
