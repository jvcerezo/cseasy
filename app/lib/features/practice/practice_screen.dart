import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content/question.dart';
import '../../core/quiz/quiz_session.dart';
import '../../core/strings.dart';
import '../../core/theme/app_theme.dart';
import 'practice_controller.dart';
import 'results_view.dart';

class PracticeScreen extends ConsumerWidget {
  final PracticeScope scope;

  const PracticeScreen({super.key, required this.scope});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = practiceControllerProvider(scope);
    final session = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    if (session.finished) {
      return Scaffold(
        appBar: AppBar(title: Text(scope.title)),
        body: ResultsView(
          session: session,
          onRestart: controller.restart,
          onDone: () => Navigator.of(context).pop(),
        ),
      );
    }

    final answeredCount = session.selections.where((s) => s != null).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(scope.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: answeredCount / session.length),
        ),
      ),
      body: _QuestionView(
        // Fresh widget state (and scroll position) for every question.
        key: ValueKey(session.current.id),
        session: session,
        onSelect: controller.select,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: session.isAnswered ? controller.advance : null,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: Text(session.isLast ? Strings.seeResults : Strings.next),
          ),
        ),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  final QuizSession session;
  final ValueChanged<int> onSelect;

  const _QuestionView({super.key, required this.session, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final question = session.current;
    final selection = session.currentSelection;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          Strings.progress(session.index + 1, session.length),
          style: textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 8),
        Text(question.stem, style: textTheme.titleLarge),
        const SizedBox(height: 20),
        for (var i = 0; i < question.choices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ChoiceTile(
              letter: String.fromCharCode(65 + i),
              text: question.choices[i],
              state: _choiceState(question, selection, i),
              onTap: selection == null ? () => onSelect(i) : null,
            ),
          ),
        if (selection != null) ...[
          const SizedBox(height: 8),
          ExplanationCard(question: question),
        ],
      ],
    );
  }

  static _ChoiceState _choiceState(Question q, int? selection, int i) {
    if (selection == null) return _ChoiceState.idle;
    if (q.isCorrect(i)) return _ChoiceState.correct;
    if (i == selection) return _ChoiceState.wrong;
    return _ChoiceState.dimmed;
  }
}

enum _ChoiceState { idle, correct, wrong, dimmed }

class _ChoiceTile extends StatelessWidget {
  final String letter;
  final String text;
  final _ChoiceState state;
  final VoidCallback? onTap;

  const _ChoiceTile({
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final quiz = QuizColors.of(context);

    final (background, border, foreground, icon) = switch (state) {
      _ChoiceState.idle => (scheme.surfaceContainerLow, scheme.outlineVariant, scheme.onSurface, null),
      _ChoiceState.correct => (quiz.correctContainer, quiz.correct, scheme.onSurface, Icons.check_circle),
      _ChoiceState.wrong => (quiz.wrongContainer, quiz.wrong, scheme.onSurface, Icons.cancel),
      _ChoiceState.dimmed => (scheme.surfaceContainerLow, scheme.outlineVariant, scheme.onSurfaceVariant, null),
    };
    final iconColor = state == _ChoiceState.correct ? quiz.correct : quiz.wrong;

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border, width: state == _ChoiceState.idle ? 1 : 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(letter, style: TextStyle(fontWeight: FontWeight.w700, color: foreground)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(text, style: TextStyle(fontSize: 16, color: foreground)),
                ),
                if (icon != null) Icon(icon, color: iconColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
