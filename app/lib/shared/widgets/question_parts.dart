import 'package:flutter/material.dart';

import '../../core/content/question.dart';
import '../../core/strings.dart';
import '../../core/theme/app_theme.dart';

class ExplanationCard extends StatelessWidget {
  final Question question;

  const ExplanationCard({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final source = question.source;
    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Strings.explanation, style: textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(question.explanation, style: textTheme.bodyMedium),
            if (source != null) ...[
              const SizedBox(height: 8),
              Text('${Strings.source}: $source', style: textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class QuestionTableView extends StatelessWidget {
  final QuestionTable table;

  const QuestionTableView({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget cell(String text, {bool header = false, bool alignEnd = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            text,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: header ? textTheme.labelLarge : textTheme.bodyMedium,
          ),
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(color: scheme.outlineVariant, borderRadius: BorderRadius.circular(8)),
        children: [
          TableRow(
            decoration: BoxDecoration(color: scheme.surfaceContainerHigh),
            children: [
              for (var i = 0; i < table.headers.length; i++)
                cell(table.headers[i], header: true, alignEnd: i > 0),
            ],
          ),
          for (final row in table.rows)
            TableRow(children: [
              for (var i = 0; i < row.length; i++) cell(row[i], header: i == 0, alignEnd: i > 0),
            ]),
        ],
      ),
    );
  }
}

/// Review card for a missed (or unanswered, when [chosen] is null) question.
class MistakeCard extends StatelessWidget {
  final Question question;
  final int? chosen;

  const MistakeCard({super.key, required this.question, required this.chosen});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final quiz = QuizColors.of(context);
    final chosen = this.chosen;
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.stem, style: textTheme.titleSmall),
            if (question.table case final table?) ...[
              const SizedBox(height: 8),
              QuestionTableView(table: table),
            ],
            const SizedBox(height: 10),
            Text(
              chosen == null
                  ? '${Strings.yourAnswer}: ${Strings.noAnswer}'
                  : '${Strings.yourAnswer}: ${question.choices[chosen]}',
              style: textTheme.bodyMedium?.copyWith(color: quiz.wrong),
            ),
            Text(
              '${Strings.correctAnswer}: ${question.choices[question.answer]}',
              style: textTheme.bodyMedium?.copyWith(color: quiz.correct, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ExplanationCard(question: question),
          ],
        ),
      ),
    );
  }
}
