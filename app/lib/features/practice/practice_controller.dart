import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content/content_providers.dart';
import '../../core/content/question.dart';
import '../../core/content/topic_labels.dart';
import '../../core/quiz/quiz_session.dart';
import '../../core/quiz/round_picker.dart';
import '../../core/strings.dart';
import '../../data/progress_providers.dart';

const practiceRoundSize = 10;

/// What a practice round draws from.
sealed class PracticeScope {
  const PracticeScope();

  String get title;
}

class TopicScope extends PracticeScope {
  final Section section;
  final String topic;

  const TopicScope(this.section, this.topic);

  @override
  String get title => topicLabel(topic);

  @override
  bool operator ==(Object other) =>
      other is TopicScope && other.section == section && other.topic == topic;

  @override
  int get hashCode => Object.hash(section, topic);
}

class SectionScope extends PracticeScope {
  final Section section;

  const SectionScope(this.section);

  @override
  String get title => section.label;

  @override
  bool operator ==(Object other) => other is SectionScope && other.section == section;

  @override
  int get hashCode => section.hashCode;
}

/// Questions whose spaced-repetition review is due.
class ReviewScope extends PracticeScope {
  const ReviewScope();

  @override
  String get title => Strings.review;

  @override
  bool operator ==(Object other) => other is ReviewScope;

  @override
  int get hashCode => (ReviewScope).hashCode;
}

final practiceControllerProvider =
    NotifierProvider.autoDispose.family<PracticeController, QuizSession?, PracticeScope>(
  PracticeController.new,
);

/// State is null when the scope has nothing to practise (e.g. no reviews due).
class PracticeController extends AutoDisposeFamilyNotifier<QuizSession?, PracticeScope> {
  @override
  QuizSession? build(PracticeScope scope) {
    // Practice is only reachable from the home screen after the bank has loaded.
    final bank = ref.watch(questionBankProvider).requireValue;
    // read, not watch: answering updates the cards, and that must not
    // reshuffle the round in progress.
    final cards = ref.read(cardsProvider).valueOrNull ?? const {};

    final questions = switch (scope) {
      TopicScope(:final topic) => pickRound(bank.byTopic(topic), cards, count: practiceRoundSize),
      SectionScope(:final section) =>
        pickRound(bank.bySection(section), cards, count: practiceRoundSize),
      ReviewScope() =>
        pickReview(bank.byId, cards, now: DateTime.now(), count: practiceRoundSize),
    };
    return questions.isEmpty ? null : QuizSession.of(questions);
  }

  void select(int choice) {
    final before = state;
    if (before == null) return;
    final after = before.select(choice);
    if (identical(before, after)) return; // already answered; nothing new to record
    state = after;

    // Fire-and-forget: a failed progress write must never block the quiz.
    unawaited(
      ref
          .read(progressRepositoryProvider)
          .recordAnswer(after.current, choice, DateTime.now())
          .catchError((Object e) => debugPrint('[Practice] failed to record answer: $e')),
    );
  }

  void advance() => state = state?.advance();

  void restart() => ref.invalidateSelf();
}
