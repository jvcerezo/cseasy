import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content/question.dart';
import '../../core/quiz/quiz_session.dart';
import '../../core/strings.dart';
import '../../shared/widgets/choice_tile.dart';
import '../../shared/widgets/question_parts.dart';
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

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(scope.title)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(Strings.nothingDue, textAlign: TextAlign.center),
          ),
        ),
      );
    }

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
        if (question.table case final table?) ...[
          const SizedBox(height: 16),
          QuestionTableView(table: table),
        ],
        const SizedBox(height: 20),
        for (var i = 0; i < question.choices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ChoiceTile(
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

  static ChoiceState _choiceState(Question q, int? selection, int i) {
    if (selection == null) return ChoiceState.idle;
    if (q.isCorrect(i)) return ChoiceState.correct;
    if (i == selection) return ChoiceState.wrong;
    return ChoiceState.dimmed;
  }
}
