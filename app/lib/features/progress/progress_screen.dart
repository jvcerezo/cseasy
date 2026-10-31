import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content/topic_labels.dart';
import '../../core/quiz/mock_exam.dart';
import '../../core/quiz/readiness.dart';
import '../../core/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../data/progress_providers.dart';
import '../../data/settings_providers.dart';
import '../premium/study_bank.dart';
import '../practice/practice_controller.dart';
import '../practice/practice_screen.dart';
import '../settings/settings_screen.dart' show formatDate;

void openPractice(BuildContext context, PracticeScope scope) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => PracticeScreen(scope: scope)),
  );
}

/// Big estimated-score figure, or what is still needed to get one.
class EstimateView extends StatelessWidget {
  final Readiness readiness;

  const EstimateView({super.key, required this.readiness});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final estimate = readiness.estimate;
    if (estimate == null) {
      return Text(Strings.estimateNeeds(readiness.attemptsNeeded), style: textTheme.bodyMedium);
    }
    final quiz = QuizColors.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 8,
      children: [
        Text(
          Strings.percent(estimate),
          style: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: estimate >= passingRatio ? quiz.correct : quiz.wrong,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(Strings.estimatedScore, style: textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  static void open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ProgressScreen()),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readiness = ref.watch(readinessProvider);
    final mocks = ref.watch(mockResultsProvider).valueOrNull ?? const [];
    final study = ref.watch(studyBankProvider).valueOrNull;
    final cards = ref.watch(cardsProvider).valueOrNull ?? const {};
    final examDate = ref.watch(examDateProvider);
    final now = ref.watch(clockProvider);
    final textTheme = Theme.of(context).textTheme;
    final quiz = QuizColors.of(context);

    if (readiness == null || study == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(Strings.progressTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final seen = study.questions.where((q) => cards.containsKey(q.id)).length;
    final mastered = study.questions.where((q) => cards[q.id]?.isMastered ?? false).length;
    final total = study.questions.length;
    final daysLeft = examDate == null ? null : daysUntil(examDate, now);
    final perDay =
        daysLeft == null ? null : newPerDayToFinish(unseen: total - seen, daysLeft: daysLeft);

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(text, style: textTheme.titleMedium),
        );

    return Scaffold(
      appBar: AppBar(title: const Text(Strings.progressTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EstimateView(readiness: readiness),
          const SizedBox(height: 4),
          Text(Strings.estimateBasis, style: textTheme.bodySmall),
          heading(Strings.bySectionRecent),
          for (final s in readiness.sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: Text(s.section.label)),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          s.tally.attempts == 0
                              ? Strings.sectionNeeds(s.attemptsNeeded)
                              : s.counted
                                  ? Strings.percent(s.tally.accuracy)
                                  : '${Strings.percent(s.tally.accuracy)} · ${Strings.sectionNeeds(s.attemptsNeeded)}',
                          textAlign: TextAlign.end,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: s.tally.accuracy,
                    borderRadius: BorderRadius.circular(2),
                    color: s.tally.accuracy >= passingRatio ? quiz.correct : quiz.wrong,
                  ),
                ],
              ),
            ),
          heading(Strings.weakestTopics),
          if (readiness.weakTopics.isEmpty)
            Text(Strings.noWeakTopics, style: textTheme.bodyMedium)
          else ...[
            for (final w in readiness.weakTopics)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(topicLabel(w.topic)),
                subtitle: Text(Strings.topicAccuracy((w.tally.accuracy * 100).round(), w.tally.attempts)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openPractice(context, TopicScope(w.section, w.topic)),
              ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => openPractice(context, const WeakSpotScope()),
              icon: const Icon(Icons.fitness_center),
              label: const Text(Strings.weakSpotDrill),
            ),
          ],
          heading(Strings.coverage),
          Text(Strings.seenOf(seen, total)),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: total == 0 ? 0 : seen / total,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 8),
          Text(Strings.masteredCount(mastered), style: textTheme.bodySmall),
          if (perDay != null && seen < total) ...[
            const SizedBox(height: 4),
            Text(Strings.pace(perDay), style: textTheme.bodySmall),
          ],
          heading(Strings.mockHistory),
          if (mocks.isEmpty)
            Text(Strings.noMockYet, style: textTheme.bodyMedium)
          else
            for (final m in mocks)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(Strings.mockLabel(MockExamSpec.isFull(m.itemCount), m.itemCount)),
                subtitle: Text(formatDate(m.submittedAt)),
                trailing: Text(
                  Strings.percent(m.ratio),
                  style: textTheme.titleMedium?.copyWith(
                    color: m.ratio >= passingRatio ? quiz.correct : quiz.wrong,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
