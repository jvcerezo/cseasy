import 'dart:math';

import 'package:cseasy/core/content/question.dart';
import 'package:cseasy/core/content/question_bank.dart';
import 'package:cseasy/core/quiz/readiness.dart';
import 'package:cseasy/core/quiz/round_picker.dart';
import 'package:cseasy/core/quiz/scheduler.dart';
import 'package:cseasy/data/app_database.dart';
import 'package:cseasy/data/progress_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Question _q(String id, Section section, String topic) => Question(
      id: id,
      levels: const {'professional'},
      section: section,
      topic: topic,
      stem: id,
      choices: const ['a', 'b', 'c', 'd'],
      answer: 1,
      explanation: 'e',
      source: null,
      difficulty: 1,
    );

CardState _card(String id, String topic, {required DateTime due, int interval = 1, int lapses = 0}) =>
    CardState(questionId: id, topic: topic, intervalDays: interval, dueAt: due, reps: 1, lapses: lapses);

final _bank = QuestionBank('t', [
  _q('v1', Section.verbal, 'vocabulary'),
  _q('v2', Section.verbal, 'grammar'),
  _q('n1', Section.numerical, 'percentage'),
  _q('n2', Section.numerical, 'work'),
]);

void main() {
  group('computeReadiness', () {
    test('no estimate until every section has enough answers', () {
      final r = computeReadiness(_bank, {
        'vocabulary': const Tally(25, 20),
        'percentage': const Tally(10, 9),
      });
      expect(r.estimate, isNull);
      expect(r.attemptsNeeded, minAttemptsPerSection - 10);
      expect(r.sections.map((s) => s.section), [Section.verbal, Section.numerical]);
    });

    test('estimate is the mean of section accuracies, not of all answers', () {
      final r = computeReadiness(_bank, {
        'vocabulary': const Tally(80, 80), // verbal 100%
        'percentage': const Tally(10, 3),
        'work': const Tally(10, 7), // numerical 50%
      });
      expect(r.estimate, closeTo(0.75, 1e-9));
    });

    test('weak topics: below 80% with enough answers, weakest first, max 3', () {
      final bank = QuestionBank('t', [
        for (final t in ['a', 'b', 'c', 'd', 'e', 'f']) _q(t, Section.verbal, t),
        _q('x', Section.numerical, 'other_level_topic'),
      ]);
      final r = computeReadiness(bank, {
        'a': const Tally(10, 7), // 70%
        'b': const Tally(10, 2), // 20%
        'c': const Tally(4, 0), // too few answers
        'd': const Tally(10, 8), // exactly passing: not weak
        'e': const Tally(20, 10), // 50%, more evidence
        'f': const Tally(10, 5), // 50%
        'unknown': const Tally(50, 0), // not in the bank
      });
      expect(r.weakTopics.map((w) => w.topic), ['b', 'e', 'f']);
    });
  });

  test('daysUntil counts calendar days', () {
    expect(daysUntil(DateTime(2027, 3, 14), DateTime(2026, 10, 31, 23, 59)), 134);
    expect(daysUntil(DateTime(2026, 10, 31), DateTime(2026, 10, 31, 8)), 0);
    expect(daysUntil(DateTime(2026, 10, 30), DateTime(2026, 10, 31)), -1);
  });

  test('newPerDayToFinish rounds up and is null on or after exam day', () {
    expect(newPerDayToFinish(unseen: 100, daysLeft: 30), 4);
    expect(newPerDayToFinish(unseen: 0, daysLeft: 30), 0);
    expect(newPerDayToFinish(unseen: 100, daysLeft: 0), isNull);
  });

  group('pickWeakSpots', () {
    final now = DateTime(2026, 10, 31, 12);
    final pool = [
      _q('p_due', Section.numerical, 'percentage'),
      _q('p_missed', Section.numerical, 'percentage'),
      _q('p_new', Section.numerical, 'percentage'),
      _q('p_known', Section.numerical, 'percentage'),
      _q('w_missed', Section.numerical, 'work'),
    ];
    final cards = {
      'p_due': _card('p_due', 'percentage', due: now.subtract(const Duration(hours: 1))),
      'p_missed': _card('p_missed', 'percentage', due: now.add(const Duration(days: 1)), lapses: 1),
      'p_known': _card('p_known', 'percentage', due: now.add(const Duration(days: 3)), interval: 3),
      'w_missed': _card('w_missed', 'work', due: now.add(const Duration(days: 1)), lapses: 2),
    };

    test('weak topics only: due, then missed, then unseen, then the rest', () {
      final picked = pickWeakSpots(pool, cards, {'percentage'}, now: now, count: 10, random: Random(1));
      expect(picked.map((q) => q.id), ['p_due', 'p_missed', 'p_new', 'p_known']);
    });

    test('respects count', () {
      final picked = pickWeakSpots(pool, cards, {'percentage'}, now: now, count: 2);
      expect(picked.map((q) => q.id), ['p_due', 'p_missed']);
    });

    test('with no weak topics, falls back to missed items anywhere', () {
      final picked = pickWeakSpots(pool, cards, const {}, now: now, count: 10);
      expect(picked.map((q) => q.id), unorderedEquals(['p_missed', 'w_missed']));
    });

    test('empty when nothing was ever missed and no weak topics', () {
      expect(pickWeakSpots(pool, const {}, const {}, now: now, count: 10), isEmpty);
    });
  });

  test('watchTopicTalliesSince only counts answers inside the window', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = ProgressRepository(db);
    final now = DateTime(2026, 10, 31, 12);
    final q = _q('p1', Section.numerical, 'percentage');
    await repo.recordAnswer(q, 0, now.subtract(const Duration(days: 40))); // outside
    await repo.recordAnswer(q, 1, now.subtract(const Duration(days: 5)));
    await repo.recordAnswer(q, 0, now);

    final tallies = await repo.watchTopicTalliesSince(now.subtract(readinessWindow)).first;
    expect(tallies['percentage']!.attempts, 2);
    expect(tallies['percentage']!.correct, 1);
  });
}
