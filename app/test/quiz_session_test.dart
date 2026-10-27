import 'dart:math';

import 'package:cseasy/core/content/question.dart';
import 'package:cseasy/core/quiz/quiz_session.dart';
import 'package:flutter_test/flutter_test.dart';

Question _q(String id, {int answer = 0}) => Question(
      id: id,
      levels: const {'professional'},
      section: Section.numerical,
      topic: 'percentage',
      stem: 'stem $id',
      choices: const ['a', 'b', 'c', 'd'],
      answer: answer,
      explanation: 'because',
      source: null,
      difficulty: 1,
    );

void main() {
  final pool = [for (var i = 0; i < 20; i++) _q('q$i')];

  test('start draws the requested number of distinct questions', () {
    final s = QuizSession.start(pool, count: 10, random: Random(1));
    expect(s.length, 10);
    expect(s.questions.map((q) => q.id).toSet().length, 10);
  });

  test('start caps the round at the pool size', () {
    expect(QuizSession.start(pool.take(3).toList(), count: 10).length, 3);
  });

  test('start rejects an empty pool', () {
    expect(() => QuizSession.start(const [], count: 10), throwsArgumentError);
  });

  test('cannot advance before answering', () {
    final s = QuizSession.start(pool, count: 3);
    expect(s.advance().index, 0);
  });

  test('an answer is locked once chosen', () {
    final s = QuizSession.start(pool, count: 3).select(2).select(0);
    expect(s.currentSelection, 2);
  });

  test('scores a full round and lists mistakes in order', () {
    var s = QuizSession.start(pool, count: 3, random: Random(2));
    s = s.select(0).advance(); // right (answer is 0)
    s = s.select(1).advance(); // wrong
    s = s.select(0);
    expect(s.isLast, isTrue);
    s = s.advance();

    expect(s.finished, isTrue);
    expect(s.correctCount, 2);
    expect(s.scoreRatio, closeTo(2 / 3, 1e-9));
    expect(s.mistakes.single.$1.id, s.questions[1].id);
    expect(s.mistakes.single.$2, 1);
  });

  test('select rejects out-of-range choices', () {
    final s = QuizSession.start(pool, count: 1);
    expect(() => s.select(4), throwsRangeError);
  });
}
