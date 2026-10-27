import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content/question.dart';
import '../../core/quiz/quiz_session.dart';
import '../../core/strings.dart';
import '../../shared/widgets/choice_tile.dart';
import '../../shared/widgets/question_parts.dart';
import '../../data/progress_providers.dart';
import '../../data/settings_providers.dart';
import '../premium/entitlement_controller.dart';
import '../premium/paywall_screen.dart';
import '../premium/study_bank.dart';
import '../report/report_sheet.dart';
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
          notice: _freeSetUsedUp(ref) ? const _UnlockNotice() : null,
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

extension on PracticeScreen {
  /// True for a free user who has now seen every free question in this scope
  /// while more exist behind the unlock, so "Practice again" would only repeat.
  bool _freeSetUsedUp(WidgetRef ref) {
    if (ref.watch(isPremiumProvider)) return false;
    final study = ref.watch(studyBankProvider).valueOrNull;
    final full = ref.watch(examBankProvider).valueOrNull;
    final cards = ref.watch(cardsProvider).valueOrNull;
    if (study == null || full == null || cards == null) return false;
    final (free, all) = switch (scope) {
      TopicScope(:final topic) => (study.byTopic(topic), full.byTopic(topic)),
      SectionScope(:final section) => (study.bySection(section), full.bySection(section)),
      ReviewScope() => (const <Question>[], const <Question>[]),
    };
    return all.length > free.length && free.every((q) => cards.containsKey(q.id));
  }
}

class _UnlockNotice extends StatelessWidget {
  const _UnlockNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Strings.freeTopicDone, style: TextStyle(color: scheme.onPrimaryContainer)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => PaywallScreen.open(context),
              child: const Text(Strings.unlockTitle),
            ),
          ],
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
          ReportButton(question: question),
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
