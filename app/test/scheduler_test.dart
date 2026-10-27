import 'dart:math';

import 'package:cseasy/core/content/question.dart';
import 'package:cseasy/core/quiz/round_picker.dart';
import 'package:cseasy/core/quiz/scheduler.dart';
import 'package:cseasy/data/progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 27, 9);

CardState _answer(CardState? prev, bool correct, [DateTime? at]) => schedule(
      questionId: 'q',
      topic: 't',
      previous: prev,
      correct: correct,
      now: at ?? _now,
    );

Question _q(String id) => Question(
      id: id,
      levels: const {'professional'},
      section: Section.numerical,
      topic: 't',
      stem: id,
      choices: const ['a', 'b', 'c', 'd'],
      answer: 0,
      explanation: 'e',
      source: null,
      difficulty: 1,
    );

CardState _card(String id, DateTime dueAt) => CardState(
      questionId: id,
      topic: 't',
      intervalDays: 1,
      dueAt: dueAt,
      reps: 1,
      lapses: 0,
    );

void main() {
  group('schedule', () {
    test('correct answers climb the ladder 1, 3, 7, 14', () {
      var c = _answer(null, true);
      final intervals = [c.intervalDays];
      for (var i = 0; i < 3; i++) {
        c = _answer(c, true);
        intervals.add(c.intervalDays);
      }
      expect(intervals, [1, 3, 7, 14]);
      expect(c.reps, 4);
      expect(c.isMastered, isTrue);
    });

    test('the ladder tops out instead of growing forever', () {
      var c = _answer(null, true);
      for (var i = 0; i < 20; i++) {
        c = _answer(c, true);
      }
      expect(c.intervalDays, 60);
    });

    test('a wrong answer resets to due-now and counts a lapse', () {
      final learned = _answer(_answer(_answer(null, true), true), true);
      final missed = _answer(learned, false);
      expect(missed.intervalDays, 0);
      expect(missed.isDue(_now), isTrue);
      expect(missed.lapses, 1);
      expect(missed.isMastered, isFalse);
    });

    test('a correct card is not due until its interval passes', () {
      final c = _answer(null, true);
      expect(c.isDue(_now), isFalse);
      expect(c.isDue(_now.add(const Duration(days: 1))), isTrue);
    });
  });

  group('pickRound', () {
    test('puts unseen questions before seen ones', () {
      final pool = [for (var i = 0; i < 6; i++) _q('q$i')];
      final cards = {
        'q0': _card('q0', _now),
        'q1': _card('q1', _now),
        'q2': _card('q2', _now),
      };
      final round = pickRound(pool, cards, count: 4, random: Random(3));
      expect(round.take(3).map((q) => q.id).toSet(), {'q3', 'q4', 'q5'});
      expect(cards.containsKey(round.last.id), isTrue);
    });

    test('orders seen questions most overdue first', () {
      final pool = [_q('a'), _q('b'), _q('c')];
      final cards = {
        'a': _card('a', _now.add(const Duration(days: 3))),
        'b': _card('b', _now.subtract(const Duration(days: 2))),
        'c': _card('c', _now),
      };
      expect(pickRound(pool, cards, count: 3).map((q) => q.id), ['b', 'c', 'a']);
    });
  });

  group('pickReview', () {
    test('returns only due cards that still exist in the bank', () {
      final byId = {'a': _q('a'), 'b': _q('b')};
      final cards = {
        'a': _card('a', _now.subtract(const Duration(hours: 1))),
        'b': _card('b', _now.add(const Duration(days: 1))),
        'gone': _card('gone', _now.subtract(const Duration(days: 1))),
      };
      expect(pickReview(byId, cards, now: _now, count: 10).map((q) => q.id), ['a']);
    });
  });

  group('computeActivity', () {
    DateTime day(int d) => DateTime(2026, 10, d);

    test('counts consecutive days ending today', () {
      final a = computeActivity({day(27): 5, day(26): 3, day(25): 1, day(23): 9}, _now);
      expect(a.streakDays, 3);
      expect(a.answeredToday, 5);
    });

    test('a streak survives until today is over', () {
      final a = computeActivity({day(26): 3, day(25): 1}, _now);
      expect(a.streakDays, 2);
      expect(a.answeredToday, 0);
    });

    test('a missed day breaks the streak', () {
      expect(computeActivity({day(25): 4}, _now).streakDays, 0);
    });

    test('walks across a month boundary', () {
      final a = computeActivity(
        {DateTime(2026, 11, 1): 1, DateTime(2026, 10, 31): 1, DateTime(2026, 10, 30): 1},
        DateTime(2026, 11, 1, 20),
      );
      expect(a.streakDays, 3);
    });
  });
}
