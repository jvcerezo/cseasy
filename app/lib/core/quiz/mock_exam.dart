import 'dart:math';

import '../content/question.dart';
import '../content/question_bank.dart';
import 'round_picker.dart';
import 'scheduler.dart';

/// Shape of a timed mock exam.
class MockExamSpec {
  final String label;
  final int itemCount;
  final Duration duration;

  const MockExamSpec({required this.label, required this.itemCount, required this.duration});

  @override
  bool operator ==(Object other) =>
      other is MockExamSpec &&
      other.label == label &&
      other.itemCount == itemCount &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(label, itemCount, duration);

  /// Full-length mocks follow the CSC's published format: Professional is
  /// 170 items in 3h10m, Sub-Professional 165 items in 2h40m. CSC does not
  /// publish section weights, so items are split evenly across sections.
  static MockExamSpec full(ExamLevel level) => switch (level) {
        ExamLevel.professional =>
          const MockExamSpec(label: 'Full mock exam', itemCount: 170, duration: Duration(minutes: 190)),
        ExamLevel.subprofessional =>
          const MockExamSpec(label: 'Full mock exam', itemCount: 165, duration: Duration(minutes: 160)),
      };

  /// A 50-item version at the same pace per item, for shorter sittings.
  static MockExamSpec mini(ExamLevel level) {
    final full = MockExamSpec.full(level);
    const items = 50;
    return MockExamSpec(
      label: 'Mini mock exam',
      itemCount: items,
      duration: Duration(seconds: (full.duration.inSeconds * items / full.itemCount).round()),
    );
  }
}

/// Picks [spec.itemCount] questions split evenly across the bank's sections
/// (remainder to the earliest sections; a short section's shortfall goes to
/// the others), grouped by section in exam order. Unseen questions come first.
List<Question> assembleMockExam(
  QuestionBank bank,
  MockExamSpec spec, {
  Map<String, CardState> cards = const {},
  Random? random,
}) {
  final sections = bank.sections;
  if (sections.isEmpty) return const [];

  final pools = {for (final s in sections) s: bank.bySection(s)};
  final quota = {for (final s in sections) s: 0};
  var remaining = min(spec.itemCount, bank.questions.length);

  // Hand out one item at a time round-robin so shortfalls redistribute.
  while (remaining > 0) {
    var progressed = false;
    for (final s in sections) {
      if (remaining == 0) break;
      if (quota[s]! < pools[s]!.length) {
        quota[s] = quota[s]! + 1;
        remaining--;
        progressed = true;
      }
    }
    if (!progressed) break;
  }

  return [
    for (final s in sections)
      ...pickRound(pools[s]!, cards, count: quota[s]!, random: random),
  ];
}

/// An in-progress mock exam. Unlike practice, answers can be changed and
/// nothing is revealed until submission.
class MockSession {
  final MockExamSpec spec;
  final List<Question> questions;
  final List<int?> selections;
  final Set<int> flagged;
  final int index;
  final DateTime startedAt;
  final DateTime? submittedAt;

  const MockSession._({
    required this.spec,
    required this.questions,
    required this.selections,
    required this.flagged,
    required this.index,
    required this.startedAt,
    required this.submittedAt,
  });

  factory MockSession.start(MockExamSpec spec, List<Question> questions, DateTime now) {
    if (questions.isEmpty) throw ArgumentError('Cannot start a mock exam with no questions');
    return MockSession._(
      spec: spec,
      questions: List.unmodifiable(questions),
      selections: List.filled(questions.length, null),
      flagged: const {},
      index: 0,
      startedAt: now,
      submittedAt: null,
    );
  }

  int get length => questions.length;
  Question get current => questions[index];
  bool get isSubmitted => submittedAt != null;
  DateTime get endsAt => startedAt.add(spec.duration);
  int get answeredCount => selections.where((s) => s != null).length;
  int get unansweredCount => length - answeredCount;

  Duration remaining(DateTime now) {
    final left = endsAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  bool isCorrect(int i) {
    final s = selections[i];
    return s != null && questions[i].isCorrect(s);
  }

  int get correctCount => [for (var i = 0; i < length; i++) if (isCorrect(i)) i].length;
  double get scoreRatio => correctCount / length;

  /// (correct, total) per section, in exam order.
  Map<Section, (int, int)> get sectionScores {
    final scores = <Section, (int, int)>{};
    for (var i = 0; i < length; i++) {
      final (c, t) = scores[questions[i].section] ?? (0, 0);
      scores[questions[i].section] = (c + (isCorrect(i) ? 1 : 0), t + 1);
    }
    return scores;
  }

  MockSession _copy({List<int?>? selections, Set<int>? flagged, int? index, DateTime? submittedAt}) =>
      MockSession._(
        spec: spec,
        questions: questions,
        selections: selections ?? this.selections,
        flagged: flagged ?? this.flagged,
        index: index ?? this.index,
        startedAt: startedAt,
        submittedAt: submittedAt ?? this.submittedAt,
      );

  MockSession select(int choice) {
    if (isSubmitted) return this;
    if (choice < 0 || choice >= current.choices.length) {
      throw RangeError.index(choice, current.choices, 'choice');
    }
    return _copy(selections: List.unmodifiable([...selections]..[index] = choice));
  }

  MockSession toggleFlag() {
    if (isSubmitted) return this;
    final next = {...flagged};
    if (!next.remove(index)) next.add(index);
    return _copy(flagged: Set.unmodifiable(next));
  }

  MockSession goTo(int i) => isSubmitted ? this : _copy(index: i.clamp(0, length - 1));

  MockSession submit(DateTime now) => isSubmitted ? this : _copy(submittedAt: now);
}
