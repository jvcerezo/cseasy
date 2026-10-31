import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/content/question.dart';
import '../core/quiz/mock_exam.dart';
import '../core/quiz/readiness.dart' show Tally;
import '../core/quiz/scheduler.dart';
import 'app_database.dart';

class TopicStats {
  final int seen;
  final int mastered;
  final int attempts;
  final int correct;

  const TopicStats({
    required this.seen,
    required this.mastered,
    required this.attempts,
    required this.correct,
  });

  double get accuracy => attempts == 0 ? 0 : correct / attempts;
}

class MockResultSummary {
  final int correct;
  final int itemCount;
  final DateTime submittedAt;

  const MockResultSummary({
    required this.correct,
    required this.itemCount,
    required this.submittedAt,
  });

  double get ratio => correct / itemCount;
}

class Activity {
  /// Consecutive days with at least one answer, ending today or yesterday
  /// (a streak is not lost until a whole day passes with no practice).
  final int streakDays;
  final int answeredToday;

  const Activity({required this.streakDays, required this.answeredToday});

  static const empty = Activity(streakDays: 0, answeredToday: 0);
}

/// All reads and writes of the user's study progress. Local only; no account needed.
class ProgressRepository {
  final AppDatabase _db;

  ProgressRepository(this._db);

  /// Logs an answer and reschedules the question, atomically.
  Future<void> recordAnswer(Question question, int choice, DateTime now) {
    _checkChoice(question, choice);
    return _db.transaction(() => _record(question, choice, now));
  }

  /// Saves a submitted mock exam and feeds every answered item into the
  /// review schedule, in one transaction.
  Future<void> recordMockExam(MockSession session, ExamLevel level) {
    final submittedAt = session.submittedAt;
    if (submittedAt == null) throw StateError('Mock exam has not been submitted');
    return _db.transaction(() async {
      for (var i = 0; i < session.length; i++) {
        final choice = session.selections[i];
        if (choice != null) await _record(session.questions[i], choice, submittedAt);
      }
      await _db
          .into(_db.mockResults)
          .insert(
            MockResultsCompanion.insert(
              level: level.key,
              itemCount: session.length,
              correct: session.correctCount,
              startedAt: session.startedAt,
              submittedAt: submittedAt,
              sectionScores: jsonEncode({
                for (final e in session.sectionScores.entries) e.key.key: [e.value.$1, e.value.$2],
              }),
            ),
          );
    });
  }

  /// Most recent first.
  Stream<List<MockResultSummary>> watchMockResults(ExamLevel level) {
    final query = _db.select(_db.mockResults)
      ..where((r) => r.level.equals(level.key))
      ..orderBy([(r) => OrderingTerm.desc(r.submittedAt)])
      ..limit(20);
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          MockResultSummary(correct: r.correct, itemCount: r.itemCount, submittedAt: r.submittedAt),
      ],
    );
  }

  static void _checkChoice(Question question, int choice) {
    if (choice < 0 || choice >= question.choices.length) {
      throw RangeError.index(choice, question.choices, 'choice');
    }
  }

  /// Must run inside a transaction.
  Future<void> _record(Question question, int choice, DateTime now) async {
    _checkChoice(question, choice);
    final correct = question.isCorrect(choice);
    final row = await (_db.select(
      _db.cards,
    )..where((c) => c.questionId.equals(question.id))).getSingleOrNull();
    final next = schedule(
      questionId: question.id,
      topic: question.topic,
      previous: row == null ? null : _toCardState(row),
      correct: correct,
      now: now,
    );
    await _db
        .into(_db.attempts)
        .insert(
          AttemptsCompanion.insert(
            questionId: question.id,
            topic: question.topic,
            choice: choice,
            correct: correct,
            answeredAt: now,
          ),
        );
    await _db
        .into(_db.cards)
        .insertOnConflictUpdate(
          CardsCompanion.insert(
            questionId: next.questionId,
            topic: next.topic,
            intervalDays: next.intervalDays,
            dueAt: next.dueAt,
            reps: next.reps,
            lapses: next.lapses,
          ),
        );
  }

  Stream<Map<String, CardState>> watchCards() => _db
      .select(_db.cards)
      .watch()
      .map((rows) => {for (final r in rows) r.questionId: _toCardState(r)});

  Stream<Map<String, TopicStats>> watchTopicStats() {
    return _db
        .customSelect(
          'SELECT c.topic, c.seen, c.mastered, a.attempts, a.correct '
          'FROM (SELECT topic, COUNT(*) AS seen, '
          '        SUM(CASE WHEN interval_days >= ? THEN 1 ELSE 0 END) AS mastered '
          '      FROM cards GROUP BY topic) c '
          'JOIN (SELECT topic, COUNT(*) AS attempts, SUM(correct) AS correct '
          '      FROM attempts GROUP BY topic) a USING (topic)',
          variables: [Variable.withInt(masteredIntervalDays)],
          readsFrom: {_db.cards, _db.attempts},
        )
        .watch()
        .map(
          (rows) => {
            for (final r in rows)
              r.read<String>('topic'): TopicStats(
                seen: r.read<int>('seen'),
                mastered: r.read<int>('mastered'),
                attempts: r.read<int>('attempts'),
                correct: r.read<int>('correct'),
              ),
          },
        );
  }

  /// Per-topic tallies of answers given at or after [since].
  Stream<Map<String, Tally>> watchTopicTalliesSince(DateTime since) {
    return _db
        .customSelect(
          'SELECT topic, COUNT(*) AS attempts, SUM(correct) AS correct '
          'FROM attempts WHERE answered_at >= ? GROUP BY topic',
          variables: [Variable.withDateTime(since)],
          readsFrom: {_db.attempts},
        )
        .watch()
        .map(
          (rows) => {
            for (final r in rows) r.read<String>('topic'): Tally(r.read<int>('attempts'), r.read<int>('correct')),
          },
        );
  }

  /// [today] is read on every emission so the streak rolls over at midnight
  /// on the next database change.
  Stream<Activity> watchActivity({DateTime Function() today = DateTime.now}) {
    return _db
        .customSelect(
          "SELECT date(answered_at, 'unixepoch', 'localtime') AS day, COUNT(*) AS n "
          'FROM attempts GROUP BY day ORDER BY day DESC LIMIT 400',
          readsFrom: {_db.attempts},
        )
        .watch()
        .map(
          (rows) => computeActivity({
            for (final r in rows) DateTime.parse(r.read<String>('day')): r.read<int>('n'),
          }, today()),
        );
  }

  static CardState _toCardState(Card row) => CardState(
    questionId: row.questionId,
    topic: row.topic,
    intervalDays: row.intervalDays,
    dueAt: row.dueAt,
    reps: row.reps,
    lapses: row.lapses,
  );
}

/// [answersPerDay] maps local calendar days (midnight) to answer counts.
Activity computeActivity(Map<DateTime, int> answersPerDay, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final answeredToday = answersPerDay[today] ?? 0;

  // Calendar arithmetic on y/m/d avoids DST-length days skewing the walk.
  var day = answeredToday > 0 ? today : DateTime(today.year, today.month, today.day - 1);
  var streak = 0;
  while ((answersPerDay[day] ?? 0) > 0) {
    streak++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return Activity(streakDays: streak, answeredToday: answeredToday);
}
