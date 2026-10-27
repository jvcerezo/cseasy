import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content/content_providers.dart';
import '../../core/content/question.dart';
import '../../core/content/question_bank.dart';
import '../../core/content/topic_labels.dart';
import '../../core/strings.dart';
import '../../data/progress_providers.dart';
import '../../data/progress_repository.dart';
import '../practice/practice_controller.dart';
import '../practice/practice_screen.dart';

void _openPractice(BuildContext context, PracticeScope scope) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => PracticeScreen(scope: scope)),
  );
}

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

class _TopicList extends ConsumerWidget {
  final QuestionBank bank;

  const _TopicList({required this.bank});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(topicStatsProvider).valueOrNull ?? const {};
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(Strings.tagline),
        ),
        const _ActivityCard(),
        const SizedBox(height: 8),
        for (final section in bank.sections) ...[
          _SectionHeader(
            section: section,
            onMixed: () => _openPractice(context, SectionScope(section)),
          ),
          for (final topic in bank.topicsBySection[section]!)
            _TopicTile(
              topic: topic,
              total: bank.byTopic(topic).length,
              stats: stats[topic],
              onTap: () => _openPractice(context, TopicScope(section, topic)),
            ),
          const Divider(height: 24),
        ],
      ],
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(activityProvider).valueOrNull ?? Activity.empty;
    final due = ref.watch(dueCountProvider);
    final textTheme = Theme.of(context).textTheme;

    return Card.filled(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _Stat(value: '${activity.streakDays}', label: Strings.dayStreak),
                ),
                Expanded(
                  child: _Stat(value: '${activity.answeredToday}', label: Strings.answeredToday),
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Strings.reviewDue, style: textTheme.titleSmall),
                      Text(Strings.questionCount(due), style: textTheme.bodyMedium),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: due == 0 ? null : () => _openPractice(context, const ReviewScope()),
                  child: const Text(Strings.startReview),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }
}

class _TopicTile extends StatelessWidget {
  final String topic;
  final int total;
  final TopicStats? stats;
  final VoidCallback onTap;

  const _TopicTile({
    required this.topic,
    required this.total,
    required this.stats,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final seen = stats?.seen ?? 0;
    final accuracyPct = ((stats?.accuracy ?? 0) * 100).round();
    return ListTile(
      title: Text(topicLabel(topic)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Strings.topicProgress(seen, total, accuracyPct)),
          if (seen > 0) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: seen / total,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
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
