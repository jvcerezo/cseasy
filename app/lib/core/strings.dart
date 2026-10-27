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
  static const backToHome = 'Back to home';
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
  static const pressBackToExit = 'Press back again to exit';
  static const flag = 'Flag for review';
  static const allItems = 'All items';
  static const timeUp = 'Time is up. Your exam was submitted.';
  static const timeUsed = 'Time used';
  static const bySection = 'Score by section';
  static const reviewWrongAndBlank = 'Review wrong and unanswered items';
  static const sectionWeightNote =
      'Format follows the CSC exam (item count and time limit). CSC does not publish section weights, so sections are split evenly.';
  static const unlockTitle = 'Unlock full access';
  static const unlockBenefitAll = 'Every question in every topic';
  static const unlockBenefitMocks = 'Unlimited full-length mock exams';
  static const unlockBenefitAds = 'No ads';
  static const unlockBenefitOnce = 'One-time payment. No subscription.';
  static const restorePurchase = 'Restore purchase';
  static const priceLoading = 'Loading price…';
  static const storeUnavailable = 'Google Play billing is unavailable on this device right now.';
  static const unavailable = 'Unavailable';
  static const youHaveFullAccess = 'You have full access. Salamat!';
  static const fullMockLocked = 'Free accounts include one full mock exam. Unlock full access for unlimited full mocks; mini mocks stay free.';
  static const reportProblem = 'Report a problem';
  static const reportTitle = 'What is wrong with this question?';
  static const reportWrongKey = 'The marked answer is wrong';
  static const reportTypo = 'Typo or grammar error';
  static const reportUnclear = 'The question is unclear';
  static const reportOutdated = 'Outdated information';
  static const reportOther = 'Something else';
  static const reportNoteHint = 'Details (optional)';
  static const reportSend = 'Send report by email';
  static const reportNoEmailApp = 'No email app found. Please email us the question ID shown here.';
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
  static String unlockCta(String price) => 'Unlock for $price';
  static String unlockBanner(int total) => 'Unlock all $total questions';
  static String freeTopicProgress(int seen, int free, int total, int accuracyPct) => seen == 0
      ? '$free of $total questions free'
      : '$seen of $free free seen · $accuracyPct% correct';
  static String moreWithFullAccess(int n) => '$n more questions with full access';
  static const freeTopicDone = "You've practiced every free question here. Unlock the rest to keep seeing new ones.";
  static String progress(int current, int total) => 'Question $current of $total';
}
