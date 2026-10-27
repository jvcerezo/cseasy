import 'package:cseasy/core/content/question.dart';
import 'package:cseasy/data/app_database.dart';
import 'package:cseasy/data/progress_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Question _q(String id, String topic) => Question(
      id: id,
      levels: const {'professional'},
      section: Section.numerical,
      topic: topic,
      stem: id,
      choices: const ['a', 'b', 'c', 'd'],
      answer: 1,
      explanation: 'e',
      source: null,
      difficulty: 1,
    );

void main() {
  late AppDatabase db;
  late ProgressRepository repo;
  final now = DateTime(2026, 10, 27, 10);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ProgressRepository(db);
  });

  tearDown(() => db.close());

  test('recording answers builds cards and per-topic stats', () async {
    await repo.recordAnswer(_q('p1', 'percentage'), 1, now); // right
    await repo.recordAnswer(_q('p2', 'percentage'), 0, now); // wrong
    await repo.recordAnswer(_q('p1', 'percentage'), 1, now.add(const Duration(days: 1)));
    await repo.recordAnswer(_q('w1', 'work'), 1, now);

    final cards = await repo.watchCards().first;
    expect(cards.keys, unorderedEquals(['p1', 'p2', 'w1']));
    expect(cards['p1']!.intervalDays, 3);
    expect(cards['p1']!.reps, 2);
    expect(cards['p2']!.intervalDays, 0);
    expect(cards['p2']!.lapses, 1);

    final stats = await repo.watchTopicStats().first;
    expect(stats['percentage']!.seen, 2);
    expect(stats['percentage']!.attempts, 3);
    expect(stats['percentage']!.correct, 2);
    expect(stats['work']!.accuracy, 1.0);
    expect(stats['percentage']!.mastered, 0);
  });

  test('activity counts today and the streak from stored answers', () async {
    final q = _q('p1', 'percentage');
    await repo.recordAnswer(q, 1, now.subtract(const Duration(days: 2)));
    await repo.recordAnswer(q, 1, now.subtract(const Duration(days: 1)));
    await repo.recordAnswer(q, 0, now);
    await repo.recordAnswer(q, 1, now);

    final activity = await repo.watchActivity(today: () => now).first;
    expect(activity.answeredToday, 2);
    expect(activity.streakDays, 3);
  });

  test('rejects an out-of-range choice without writing anything', () async {
    expect(() => repo.recordAnswer(_q('p1', 'percentage'), 7, now), throwsRangeError);
    expect(await repo.watchCards().first, isEmpty);
  });
}
