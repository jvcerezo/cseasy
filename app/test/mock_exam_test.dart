import 'package:cseasy/core/content/question.dart';
import 'package:cseasy/core/content/question_bank.dart';
import 'package:cseasy/core/quiz/mock_exam.dart';
import 'package:cseasy/data/app_database.dart';
import 'package:cseasy/data/progress_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Question _q(String id, Section section) => Question(
      id: id,
      levels: const {'professional'},
      section: section,
      topic: section.key,
      stem: id,
      choices: const ['a', 'b', 'c', 'd'],
      answer: 2,
      explanation: 'e',
      source: null,
      difficulty: 1,
    );

QuestionBank _bank(Map<Section, int> sizes) => QuestionBank('v', [
      for (final MapEntry(key: s, value: n) in sizes.entries)
        for (var i = 0; i < n; i++) _q('${s.key}-$i', s),
    ]);

const _spec = MockExamSpec(label: 'test', itemCount: 10, duration: Duration(minutes: 10));

void main() {
  group('assembleMockExam', () {
    test('splits items evenly and groups them by section in exam order', () {
      final bank = _bank({Section.verbal: 20, Section.numerical: 20, Section.generalInfo: 20});
      final exam = assembleMockExam(bank, _spec);
      final counts = <Section, int>{};
      for (final q in exam) {
        counts[q.section] = (counts[q.section] ?? 0) + 1;
      }
      expect(exam, hasLength(10));
      expect(counts, {Section.verbal: 4, Section.numerical: 3, Section.generalInfo: 3});
      // Grouped: once a section ends, it never reappears.
      final order = exam.map((q) => q.section).toList();
      expect(order.indexOf(Section.numerical), greaterThan(order.lastIndexOf(Section.verbal)));
    });

    test('a short section gives its unused quota to the others', () {
      final bank = _bank({Section.verbal: 2, Section.numerical: 20});
      final exam = assembleMockExam(bank, _spec);
      expect(exam.where((q) => q.section == Section.verbal), hasLength(2));
      expect(exam.where((q) => q.section == Section.numerical), hasLength(8));
    });

    test('never asks the same question twice and caps at the bank size', () {
      final bank = _bank({Section.verbal: 3, Section.numerical: 3});
      final exam = assembleMockExam(bank, _spec);
      expect(exam, hasLength(6));
      expect(exam.map((q) => q.id).toSet(), hasLength(6));
    });
  });

  test('mini mock keeps the full exam pace per item', () {
    final full = MockExamSpec.full(ExamLevel.professional);
    final mini = MockExamSpec.mini(ExamLevel.professional);
    expect(full.itemCount, 170);
    expect(full.duration, const Duration(minutes: 190));
    expect(mini.itemCount, 50);
    expect(
      mini.duration.inSeconds / mini.itemCount,
      closeTo(full.duration.inSeconds / full.itemCount, 1),
    );
  });

  group('MockSession', () {
    final start = DateTime(2026, 10, 27, 9);
    final questions = [
      _q('v1', Section.verbal),
      _q('v2', Section.verbal),
      _q('n1', Section.numerical),
    ];

    test('answers can be changed until submission', () {
      final s = MockSession.start(_spec, questions, start).select(0).select(2);
      expect(s.selections.first, 2);
    });

    test('flags toggle per item', () {
      var s = MockSession.start(_spec, questions, start).toggleFlag();
      expect(s.flagged, {0});
      s = s.toggleFlag();
      expect(s.flagged, isEmpty);
    });

    test('scores overall and per section; unanswered counts as wrong', () {
      var s = MockSession.start(_spec, questions, start);
      s = s.select(2).goTo(1).select(0).goTo(2).select(2); // right, wrong, right
      s = s.submit(start.add(const Duration(minutes: 5)));
      expect(s.correctCount, 2);
      expect(s.sectionScores, {Section.verbal: (1, 2), Section.numerical: (1, 1)});
      expect(s.select(1).selections, s.selections, reason: 'locked after submit');
    });

    test('remaining time counts down to zero, never negative', () {
      final s = MockSession.start(_spec, questions, start);
      expect(s.remaining(start.add(const Duration(minutes: 4))), const Duration(minutes: 6));
      expect(s.remaining(start.add(const Duration(hours: 1))), Duration.zero);
    });
  });

  test('recordMockExam saves the result and schedules answered items', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = ProgressRepository(db);
    final start = DateTime(2026, 10, 27, 9);
    final questions = [_q('v1', Section.verbal), _q('n1', Section.numerical)];

    final s = MockSession.start(_spec, questions, start)
        .select(2) // right
        .submit(start.add(const Duration(minutes: 3))); // n1 left blank

    await repo.recordMockExam(s, ExamLevel.professional);

    final results = await repo.watchMockResults(ExamLevel.professional).first;
    expect(results.single.correct, 1);
    expect(results.single.itemCount, 2);
    expect((await repo.watchCards().first).keys, ['v1'], reason: 'blank items are not scheduled');
    expect(await repo.watchMockResults(ExamLevel.subprofessional).first, isEmpty);
  });
}
