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
