abstract final class Strings {
  static const appName = 'CSEasy';
  static const tagline = 'Civil Service Exam reviewer';
  static const loadError = 'Could not load the question bank.';
  static const retry = 'Retry';
  static const mixedPractice = 'Mixed';
  static const next = 'Next';
  static const seeResults = 'See results';
  static const explanation = 'Explanation';
  static const source = 'Source';
  static const practiceAgain = 'Practice again';
  static const backToTopics = 'Back to topics';
  static const yourAnswer = 'Your answer';
  static const correctAnswer = 'Correct answer';
  static const reviewMistakes = 'Review your mistakes';
  static const review = 'Review';
  static const reviewDue = 'Due for review';
  static const nothingDue = 'Nothing due right now. Questions you miss come back here, and ones you get right return on a schedule.';
  static const startReview = 'Start review';
  static const dayStreak = 'day streak';
  static const answeredToday = 'answered today';
  static const perfectRound = 'Perfect round. No mistakes to review.';
  static const passedRound = 'Passing score. The CSE needs at least 80%.';
  static const failedRound = 'Below passing. The CSE needs at least 80%.';

  static String questionCount(int n) => n == 1 ? '1 question' : '$n questions';
  static String topicProgress(int seen, int total, int accuracyPct) =>
      seen == 0 ? '$total questions' : '$seen of $total seen · $accuracyPct% correct';
  static String progress(int current, int total) => 'Question $current of $total';
}
