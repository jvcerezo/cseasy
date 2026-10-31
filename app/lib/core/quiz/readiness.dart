import '../content/question.dart';
import '../content/question_bank.dart';

/// Answers counted toward readiness: only recent ones, so early mistakes
/// stop dragging the estimate down once a topic has been learned.
const readinessWindow = Duration(days: 30);

/// Recent answers a section needs before its accuracy counts toward the
/// score estimate. Fewer than this is too noisy to show as a prediction.
const minAttemptsPerSection = 20;

/// Recent answers a topic needs before it can be called a weak spot.
const minAttemptsPerWeakTopic = 5;

/// The CSE passing mark: a general rating of at least 80%.
const passingRatio = 0.8;

/// Correct and total recent answers for one topic or section.
class Tally {
  final int attempts;
  final int correct;

  const Tally(this.attempts, this.correct);

  static const zero = Tally(0, 0);

  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  Tally operator +(Tally other) => Tally(attempts + other.attempts, correct + other.correct);
}

class SectionReadiness {
  final Section section;
  final Tally tally;

  const SectionReadiness(this.section, this.tally);

  bool get counted => tally.attempts >= minAttemptsPerSection;

  /// Answers still needed before this section counts toward the estimate.
  int get attemptsNeeded =>
      counted ? 0 : minAttemptsPerSection - tally.attempts;
}

class WeakTopic {
  final Section section;
  final String topic;
  final Tally tally;

  const WeakTopic(this.section, this.topic, this.tally);
}

class Readiness {
  /// Every section of the level's exam, in exam order.
  final List<SectionReadiness> sections;

  /// Weakest first, at most [maxWeakTopics].
  final List<WeakTopic> weakTopics;

  const Readiness({required this.sections, required this.weakTopics});

  static const maxWeakTopics = 3;

  /// Predicted score ratio: the mean of section accuracies, since the mock
  /// exam (and our best reading of the CSE) weighs sections evenly. Null
  /// until every section has enough recent answers to be meaningful.
  double? get estimate {
    if (sections.isEmpty || sections.any((s) => !s.counted)) return null;
    final sum = sections.fold<double>(0, (acc, s) => acc + s.tally.accuracy);
    return sum / sections.length;
  }

  /// Answers still needed across all sections before an estimate appears.
  int get attemptsNeeded => sections.fold(0, (acc, s) => acc + s.attemptsNeeded);
}

/// [recent] is per-topic tallies over [readinessWindow]. Topics outside
/// [bank] (the other exam level, retired content) are ignored.
Readiness computeReadiness(QuestionBank bank, Map<String, Tally> recent) {
  final sections = <SectionReadiness>[];
  final weak = <WeakTopic>[];
  for (final section in bank.sections) {
    var sectionTally = Tally.zero;
    for (final topic in bank.topicsBySection[section]!) {
      final t = recent[topic];
      if (t == null) continue;
      sectionTally += t;
      if (t.attempts >= minAttemptsPerWeakTopic && t.accuracy < passingRatio) {
        weak.add(WeakTopic(section, topic, t));
      }
    }
    sections.add(SectionReadiness(section, sectionTally));
  }
  // Weakest first; among equals, the topic with more evidence first.
  weak.sort((a, b) {
    final byAccuracy = a.tally.accuracy.compareTo(b.tally.accuracy);
    return byAccuracy != 0 ? byAccuracy : b.tally.attempts.compareTo(a.tally.attempts);
  });
  return Readiness(
    sections: List.unmodifiable(sections),
    weakTopics: List.unmodifiable(weak.take(Readiness.maxWeakTopics)),
  );
}

/// Whole calendar days from [now] to [examDate]; 0 on exam day, negative after.
int daysUntil(DateTime examDate, DateTime now) {
  // UTC dates avoid DST-length days skewing the count.
  final a = DateTime.utc(now.year, now.month, now.day);
  final b = DateTime.utc(examDate.year, examDate.month, examDate.day);
  return b.difference(a).inDays;
}

/// New questions per day needed to see every unseen question by exam day
/// (rounded up). Null when the exam is today or past.
int? newPerDayToFinish({required int unseen, required int daysLeft}) {
  if (daysLeft <= 0) return null;
  return (unseen / daysLeft).ceil();
}
