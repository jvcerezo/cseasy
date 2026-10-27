import 'dart:convert';

import 'question.dart';

/// The full bundled question set, indexed once at load time.
class QuestionBank {
  final String version;
  final List<Question> questions;
  final Map<String, List<Question>> _byTopic;
  final Map<Section, List<String>> topicsBySection;
  final Map<String, Question> byId;

  QuestionBank._(this.version, this.questions, this._byTopic, this.topicsBySection)
      : byId = {for (final q in questions) q.id: q};

  factory QuestionBank(String version, List<Question> questions) {
    final byTopic = <String, List<Question>>{};
    final topicsBySection = <Section, List<String>>{};
    for (final q in questions) {
      final bucket = byTopic.putIfAbsent(q.topic, () => []);
      if (bucket.isEmpty) {
        topicsBySection.putIfAbsent(q.section, () => []).add(q.topic);
      }
      bucket.add(q);
    }
    return QuestionBank._(
      version,
      List.unmodifiable(questions),
      {for (final e in byTopic.entries) e.key: List.unmodifiable(e.value)},
      {for (final e in topicsBySection.entries) e.key: List.unmodifiable(e.value)},
    );
  }

  List<Question> byTopic(String topic) => _byTopic[topic] ?? const [];

  /// The subset of questions that appear on [level]'s exam.
  QuestionBank forLevel(ExamLevel level) =>
      QuestionBank(version, questions.where((q) => q.isForLevel(level)).toList());

  List<Question> bySection(Section section) => [
        for (final topic in topicsBySection[section] ?? const <String>[]) ...byTopic(topic),
      ];

  /// Sections in exam order that have at least one question.
  List<Section> get sections =>
      Section.values.where(topicsBySection.containsKey).toList(growable: false);
}

/// Top-level so it can run in a background isolate via `compute`.
QuestionBank parseQuestionBank(String raw) {
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final questions = (json['questions'] as List)
      .map((q) => Question.fromJson(q as Map<String, dynamic>))
      .toList();
  return QuestionBank(json['version'] as String, questions);
}
