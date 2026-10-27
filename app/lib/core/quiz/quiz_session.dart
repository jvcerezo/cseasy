import 'dart:math';

import '../content/question.dart';

/// An in-progress practice round. Immutable: every action returns a new session.
///
/// Practice mode locks a question once answered so the feedback shown
/// (right/wrong + explanation) always matches the recorded choice.
class QuizSession {
  final List<Question> questions;
  final List<int?> selections;
  final int index;
  final bool finished;

  const QuizSession._(this.questions, this.selections, this.index, this.finished);

  /// Draws up to [count] random questions from [pool].
  factory QuizSession.start(List<Question> pool, {required int count, Random? random}) {
    if (pool.isEmpty) throw ArgumentError('Cannot start a quiz with no questions');
    final picked = [...pool]..shuffle(random);
    final questions = List<Question>.unmodifiable(picked.take(count));
    return QuizSession._(questions, List.filled(questions.length, null), 0, false);
  }

  Question get current => questions[index];
  int? get currentSelection => selections[index];
  bool get isAnswered => currentSelection != null;
  bool get isLast => index == questions.length - 1;
  int get length => questions.length;

  int get correctCount => [
        for (var i = 0; i < length; i++)
          if (selections[i] case final s? when questions[i].isCorrect(s)) i,
      ].length;

  double get scoreRatio => correctCount / length;

  /// Questions answered wrong, in the order they were asked.
  List<(Question, int)> get mistakes => [
        for (var i = 0; i < length; i++)
          if (selections[i] case final s? when !questions[i].isCorrect(s)) (questions[i], s),
      ];

  QuizSession select(int choice) {
    if (finished || isAnswered) return this;
    if (choice < 0 || choice >= current.choices.length) {
      throw RangeError.index(choice, current.choices, 'choice');
    }
    final next = [...selections]..[index] = choice;
    return QuizSession._(questions, List.unmodifiable(next), index, finished);
  }

  /// Moves to the next question, or finishes after the last one.
  QuizSession advance() {
    if (!isAnswered || finished) return this;
    if (isLast) return QuizSession._(questions, selections, index, true);
    return QuizSession._(questions, selections, index + 1, false);
  }
}
