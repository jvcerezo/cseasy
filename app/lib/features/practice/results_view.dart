import 'package:flutter/material.dart';

import '../../core/quiz/quiz_session.dart';
import '../../core/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/question_parts.dart';

/// The CSE passing mark: a general rating of at least 80%.
const passingRatio = 0.8;

class ResultsView extends StatelessWidget {
  final QuizSession session;
  final VoidCallback onRestart;
  final VoidCallback onDone;

  const ResultsView({
    super.key,
    required this.session,
    required this.onRestart,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final quiz = QuizColors.of(context);
    final passed = session.scoreRatio >= passingRatio;
    final mistakes = session.mistakes;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      // Header, then one card per mistake, then the action buttons.
      itemCount: mistakes.length + 2,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Column(
            children: [
              const SizedBox(height: 16),
              Text(
                '${session.correctCount} / ${session.length}',
                style: textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: passed ? quiz.correct : quiz.wrong,
                ),
              ),
              Text('${(session.scoreRatio * 100).round()}%', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                passed ? Strings.passedRound : Strings.failedRound,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  mistakes.isEmpty ? Strings.perfectRound : Strings.reviewMistakes,
                  style: textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }
        if (i == mistakes.length + 1) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                FilledButton(
                  onPressed: onRestart,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: const Text(Strings.practiceAgain),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onDone,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: const Text(Strings.backToTopics),
                ),
              ],
            ),
          );
        }
        final (question, chosen) = mistakes[i - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MistakeCard(question: question, chosen: chosen),
        );
      },
    );
  }
}
