import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content/question.dart';
import '../../core/content/question_bank.dart';
import '../../core/content/topic_labels.dart';
import '../../core/strings.dart';
import '../../data/progress_providers.dart';
import '../../data/progress_repository.dart';
import '../../core/quiz/mock_exam.dart';
import '../../data/settings_providers.dart';
import '../mock/mock_screen.dart';
import '../premium/entitlement_controller.dart';
import '../premium/paywall_screen.dart';
import '../premium/premium_gate.dart';
import '../premium/study_bank.dart';
import '../onboarding/level_picker_screen.dart';
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
    // Watching the study bank keeps it loaded before practice reads it.
    final study = ref.watch(studyBankProvider);
    final level = ref.watch(examLevelProvider);
    final isPremium = ref.watch(isPremiumProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.appName),
        actions: [
          IconButton(
            tooltip: Strings.unlockTitle,
            icon: Icon(isPremium ? Icons.workspace_premium : Icons.workspace_premium_outlined),
            onPressed: () => PaywallScreen.open(context),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const LevelPickerScreen(popOnSelect: true)),
            ),
            icon: const Icon(Icons.swap_horiz, size: 18),
            label: Text(level?.shortLabel ?? ''),
          ),
        ],
      ),
      body: study.when(
        data: (_) => _TopicList(bank: ref.watch(examBankProvider).requireValue),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(Strings.loadError),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(studyBankProvider),
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
    final isPremium = ref.watch(isPremiumProvider);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(Strings.tagline),
        ),
        const _ActivityCard(),
        if (!isPremium) ...[
          const SizedBox(height: 12),
          _UnlockCard(total: bank.questions.length),
        ],
        const SizedBox(height: 12),
        const _MockExamCard(),
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
              locked: !isPremium && bank.byTopic(topic).length > freeQuestionsPerTopic,
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
            // Wrap, not Row: with large text the button drops below the
            // label instead of overflowing.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(Strings.reviewDue, style: textTheme.titleSmall),
                    Text(Strings.questionCount(due), style: textTheme.bodyMedium),
                  ],
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

class _MockExamCard extends ConsumerWidget {
  const _MockExamCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(examLevelProvider) ?? ExamLevel.professional;
    final results = ref.watch(mockResultsProvider).valueOrNull ?? const [];
    final isPremium = ref.watch(isPremiumProvider);
    final fullTaken = results.where((r) => MockExamSpec.isFull(r.itemCount)).length;
    final fullAllowed = canStartFullMock(isPremium: isPremium, fullMocksTaken: fullTaken);
    final textTheme = Theme.of(context).textTheme;
    final full = MockExamSpec.full(level);
    final mini = MockExamSpec.mini(level);

    void open(MockExamSpec spec) => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => MockScreen(spec: spec)),
        );

    return Card.outlined(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Strings.mockExams, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(Strings.mockDescription, style: textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              results.isEmpty
                  ? Strings.noMockYet
                  : '${Strings.lastScore}: ${(results.first.ratio * 100).toStringAsFixed(1)}%',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => fullAllowed ? open(full) : _showFullMockLocked(context),
                    child: Text(
                      Strings.mockButton(Strings.fullMock, full.itemCount, full.duration),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => open(mini),
                    child: Text(
                      Strings.mockButton(Strings.miniMock, mini.itemCount, mini.duration),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showFullMockLocked(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text(Strings.unlockTitle),
      content: const Text(Strings.fullMockLocked),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text(Strings.stay)),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            PaywallScreen.open(context);
          },
          child: const Text(Strings.unlockTitle),
        ),
      ],
    ),
  );
}

class _UnlockCard extends StatelessWidget {
  final int total;

  const _UnlockCard({required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card.filled(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: scheme.primaryContainer,
      child: ListTile(
        leading: Icon(Icons.workspace_premium, color: scheme.onPrimaryContainer),
        title: Text(Strings.unlockBanner(total), style: TextStyle(color: scheme.onPrimaryContainer)),
        subtitle: Text(Strings.unlockBenefitOnce, style: TextStyle(color: scheme.onPrimaryContainer)),
        trailing: Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
        onTap: () => PaywallScreen.open(context),
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
  final bool locked;
  final VoidCallback onTap;

  const _TopicTile({
    required this.topic,
    required this.total,
    required this.stats,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final seen = stats?.seen ?? 0;
    final accuracyPct = ((stats?.accuracy ?? 0) * 100).round();
    // Free users can only reach the free slice, so progress is measured
    // against that rather than a total they can never complete.
    final reachable = locked ? freeQuestionsPerTopic : total;
    return ListTile(
      title: Text(topicLabel(topic)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locked
                ? Strings.freeTopicProgress(seen, reachable, total, accuracyPct)
                : Strings.topicProgress(seen, total, accuracyPct),
          ),
          if (locked)
            Text(
              Strings.moreWithFullAccess(total - reachable),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (seen > 0) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: (seen / reachable).clamp(0.0, 1.0),
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ],
      ),
      trailing: Icon(locked ? Icons.lock_outline : Icons.chevron_right),
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
