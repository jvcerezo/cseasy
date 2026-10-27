import 'dart:io';

import 'package:cseasy/core/content/question.dart';
import 'package:cseasy/core/content/question_bank.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the contract between pipeline/build.py and the app's parser.
void main() {
  late final QuestionBank bank;

  setUpAll(() {
    bank = parseQuestionBank(File('assets/content/cse.json').readAsStringSync());
  });

  test('the bundled asset parses and is non-empty', () {
    expect(bank.version, isNotEmpty);
    expect(bank.questions, isNotEmpty);
  });

  test('every question has four choices and an in-range key', () {
    for (final q in bank.questions) {
      expect(q.choices, hasLength(4), reason: q.id);
      expect(q.answer, inInclusiveRange(0, 3), reason: q.id);
    }
  });

  test('topics are indexed under their section', () {
    for (final section in bank.sections) {
      for (final topic in bank.topicsBySection[section]!) {
        expect(bank.byTopic(topic).every((q) => q.section == section), isTrue);
      }
    }
    expect(bank.sections, contains(Section.numerical));
  });

  test('levels split analytical and clerical coverage', () {
    final pro = bank.forLevel(ExamLevel.professional);
    final sub = bank.forLevel(ExamLevel.subprofessional);
    expect(pro.sections, containsAll([Section.numerical, Section.analytical]));
    expect(pro.sections, isNot(contains(Section.clerical)));
    expect(sub.sections, containsAll([Section.numerical, Section.clerical]));
    expect(sub.sections, isNot(contains(Section.analytical)));
  });

  test('data-interpretation tables parse with consistent row widths', () {
    final withTables = bank.questions.where((q) => q.table != null).toList();
    expect(withTables, isNotEmpty);
    for (final q in withTables) {
      final table = q.table!;
      expect(table.rows.every((r) => r.length == table.headers.length), isTrue, reason: q.id);
    }
  });
}
