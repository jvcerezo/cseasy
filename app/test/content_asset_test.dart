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
}
