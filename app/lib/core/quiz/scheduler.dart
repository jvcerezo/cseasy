/// Spaced-repetition state for one question the user has answered at least once.
class CardState {
  final String questionId;
  final String topic;

  /// Days until the next review. 0 means "review again soon" (last answer wrong).
  final int intervalDays;
  final DateTime dueAt;
  final int reps;
  final int lapses;

  const CardState({
    required this.questionId,
    required this.topic,
    required this.intervalDays,
    required this.dueAt,
    required this.reps,
    required this.lapses,
  });

  bool isDue(DateTime now) => !dueAt.isAfter(now);

  /// Answered correctly across enough spaced reviews to count as learned.
  bool get isMastered => intervalDays >= masteredIntervalDays;
}

const masteredIntervalDays = 7;

/// Review gaps, in days, after each consecutive correct answer.
const _ladder = [1, 3, 7, 14, 30, 60];

/// Leitner-style scheduling: a correct answer climbs one rung of [_ladder],
/// a wrong answer drops the card to 0 so it comes back in the next review.
CardState schedule({
  required String questionId,
  required String topic,
  required CardState? previous,
  required bool correct,
  required DateTime now,
}) {
  final reps = (previous?.reps ?? 0) + 1;
  final lapses = (previous?.lapses ?? 0) + (correct ? 0 : 1);

  if (!correct) {
    return CardState(
      questionId: questionId,
      topic: topic,
      intervalDays: 0,
      dueAt: now,
      reps: reps,
      lapses: lapses,
    );
  }

  final current = previous?.intervalDays ?? 0;
  final interval = _ladder.firstWhere((d) => d > current, orElse: () => _ladder.last);
  return CardState(
    questionId: questionId,
    topic: topic,
    intervalDays: interval,
    dueAt: now.add(Duration(days: interval)),
    reps: reps,
    lapses: lapses,
  );
}
