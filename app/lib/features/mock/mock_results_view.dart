import 'package:flutter/material.dart';

import '../../core/quiz/mock_exam.dart';
import '../../core/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/question_parts.dart';
import '../practice/results_view.dart' show passingRatio;

class MockResultsView extends StatelessWidget {
  final MockSession session;
  final VoidCallback onDone;

  const MockResultsView({super.key, required this.session, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final quiz = QuizColors.of(context);
    final passed = session.scoreRatio >= passingRatio;
    // Wrong and unanswered items, in exam order.
    final review = [
      for (var i = 0; i < session.length; i++)
        if (!session.isCorrect(i)) i,
    ];
    final used = session.submittedAt!.difference(session.startedAt);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: review.length + 2,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${(session.scoreRatio * 100).toStringAsFixed(1)}%',
                  style: textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: passed ? quiz.correct : quiz.wrong,
                  ),
                ),
              ),
              Center(
                child: Text(
                  '${session.correctCount} / ${session.length}',
                  style: textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  passed ? Strings.passedRound : Strings.failedRound,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '${Strings.timeUsed}: ${used.inMinutes} min',
                  style: textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 24),
              Text(Strings.bySection, style: textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final MapEntry(key: section, value: (correct, total)) in session.sectionScores.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(section.label)),
                          Text('$correct / $total'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: total == 0 ? 0 : correct / total,
                        borderRadius: BorderRadius.circular(2),
                        color: correct / total >= passingRatio ? quiz.correct : quiz.wrong,
                      ),
                    ],
                  ),
                ),
              Text(Strings.sectionWeightNote, style: textTheme.bodySmall),
              const SizedBox(height: 24),
              Text(
                review.isEmpty ? Strings.perfectRound : Strings.reviewWrongAndBlank,
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
            ],
          );
        }
        if (i == review.length + 1) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text(Strings.backToTopics),
            ),
          );
        }
        final index = review[i - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MistakeCard(
            question: session.questions[index],
            chosen: session.selections[index],
          ),
        );
      },
    );
  }
}
