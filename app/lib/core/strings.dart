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
  static const whichLevel = 'Which exam are you taking?';
  static const professionalDescription =
      'For second-level (technical and supervisory) government posts. Covers Verbal, Numerical, '
      'Analytical and General Information.';
  static const subprofessionalDescription =
      'For first-level (clerical, custodial and trades) government posts. Covers Verbal, Numerical, '
      'Clerical and General Information.';
  static const levelChangeLater = 'You can switch levels anytime from the home screen.';
  static const switchLevel = 'Switch exam level';
  static const noAnswer = 'No answer';
  static const mockExams = 'Mock exams';
  static const mockDescription = 'Timed, full-format practice. Answers are revealed after you submit.';
  static const fullMock = 'Full';
  static const miniMock = 'Mini (50)';
  static const lastScore = 'Last score';
  static const noMockYet = 'No mock exam taken yet';
  static const previous = 'Previous';
  static const submit = 'Submit';
  static const submitExam = 'Submit exam?';
  static const keepAnswering = 'Keep answering';
  static const leaveExam = 'Leave the exam?';
  static const leaveExamBody = 'Your answers in this mock exam will be lost.';
  static const leave = 'Leave';
  static const stay = 'Stay';
  static const flag = 'Flag for review';
  static const allItems = 'All items';
  static const timeUp = 'Time is up. Your exam was submitted.';
  static const timeUsed = 'Time used';
  static const bySection = 'Score by section';
  static const reviewWrongAndBlank = 'Review wrong and unanswered items';
  static const sectionWeightNote =
      'Format follows the CSC exam (item count and time limit). CSC does not publish section weights, so sections are split evenly.';
  static const perfectRound = 'Perfect round. No mistakes to review.';
  static const passedRound = 'Passing score. The CSE needs at least 80%.';
  static const failedRound = 'Below passing. The CSE needs at least 80%.';

  static String questionCount(int n) => n == 1 ? '1 question' : '$n questions';
  static String topicProgress(int seen, int total, int accuracyPct) =>
      seen == 0 ? '$total questions' : '$seen of $total seen · $accuracyPct% correct';
  static String unansweredWarning(int n) => n == 0
      ? 'You have answered every item.'
      : 'You have $n unanswered ${n == 1 ? 'item' : 'items'}. Unanswered items count as wrong.';
  static String mockMeta(int items, Duration d) =>
      '$items items · ${d.inHours > 0 ? '${d.inHours}h ' : ''}${d.inMinutes % 60}m';
  static String progress(int current, int total) => 'Question $current of $total';
}
