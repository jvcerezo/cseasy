import 'dart:math';

import '../content/question.dart';
import 'scheduler.dart';

/// Orders a topic/section pool for a practice round: questions never seen
/// come first (shuffled), then seen ones, most overdue first.
///
/// Users who practise daily keep meeting new items instead of repeats until
/// the topic is exhausted.
List<Question> pickRound(
  List<Question> pool,
  Map<String, CardState> cards, {
  required int count,
  Random? random,
}) {
  final unseen = <Question>[];
  final seen = <Question>[];
  for (final q in pool) {
    (cards.containsKey(q.id) ? seen : unseen).add(q);
  }
  unseen.shuffle(random);
  seen.sort((a, b) => cards[a.id]!.dueAt.compareTo(cards[b.id]!.dueAt));
  return [...unseen, ...seen].take(count).toList(growable: false);
}

/// Due cards for a review round, most overdue first.
List<Question> pickReview(
  Map<String, Question> byId,
  Map<String, CardState> cards, {
  required DateTime now,
  required int count,
}) {
  final due = cards.values.where((c) => c.isDue(now) && byId.containsKey(c.questionId)).toList()
    ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  return [for (final c in due.take(count)) byId[c.questionId]!];
}

/// A round focused on [weakTopics] (from the readiness tally): due reviews
/// first, then items missed before and not yet relearned, then unseen items,
/// then everything else in those topics. With no weak topics, falls back to
/// missed items anywhere in [pool] so the drill still has something to offer.
List<Question> pickWeakSpots(
  List<Question> pool,
  Map<String, CardState> cards,
  Set<String> weakTopics, {
  required DateTime now,
  required int count,
  Random? random,
}) {
  bool missed(CardState c) => c.lapses > 0 && !c.isMastered;
  final focus = weakTopics.isEmpty
      ? pool.where((q) => cards[q.id] != null && missed(cards[q.id]!)).toList()
      : pool.where((q) => weakTopics.contains(q.topic)).toList();

  final due = <Question>[];
  final relearn = <Question>[];
  final unseen = <Question>[];
  final rest = <Question>[];
  for (final q in focus) {
    final card = cards[q.id];
    if (card == null) {
      unseen.add(q);
    } else if (card.isDue(now)) {
      due.add(q);
    } else if (missed(card)) {
      relearn.add(q);
    } else {
      rest.add(q);
    }
  }
  int byDue(Question a, Question b) => cards[a.id]!.dueAt.compareTo(cards[b.id]!.dueAt);
  due.sort(byDue);
  relearn.sort(byDue);
  rest.sort(byDue);
  unseen.shuffle(random);
  return [...due, ...relearn, ...unseen, ...rest].take(count).toList(growable: false);
}
