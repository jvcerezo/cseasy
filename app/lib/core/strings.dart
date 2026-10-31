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
  static const miniMock = 'Mini';
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

  static const weakSpotDrill = 'Drill weak spots';
  static const noWeakSpots =
      'No weak spots yet. A topic counts as weak once you have answered at least 5 of its questions '
      'in the last 30 days and scored below 80%.';
  static const yourReadiness = 'Your readiness';
  static const estimatedScore = 'estimated score';
  static const estimateBasis =
      'The average of your section scores over the last 30 days. It is a guide, not a guarantee; '
      'take a full mock exam for the real test of readiness.';
  static const seeProgress = 'See progress';
  static const progressTitle = 'Progress';
  static const bySectionRecent = 'By section, last 30 days';
  static const weakestTopics = 'Weakest topics';
  static const noWeakTopics = 'No weak topics right now. Every topic you have practiced lately is at 80% or better.';
  static const mockHistory = 'Mock exam history';
  static const coverage = 'Coverage';
  static const setExamDate = 'Set exam date';
  static const change = 'Change';
  static const todaysGoal = "today's goal";
  static const goalMet = 'Daily goal met. Nice work!';
  static const settings = 'Settings';
  static const examLevel = 'Exam level';
  static const examDate = 'Exam date';
  static const notSet = 'Not set';
  static const clear = 'Clear';
  static const dailyGoal = 'Daily goal';
  static const dailyGoalHint = 'Questions to answer each day.';
  static const appearance = 'Appearance';
  static const theme = 'Theme';
  static const themeSystem = 'System';
  static const themeLight = 'Light';
  static const themeDark = 'Dark';
  static const textSize = 'Text size';
  static const textSizeHint = "Applied on top of your phone's font size.";
  static const about = 'About';
  static const version = 'Version';
  static const privacyPolicy = 'Privacy policy';
  static const privacyPolicyUrl = 'https://cseasy.jettimothycerezo.dev/privacy';
  static const examDateHelp = 'When is your exam?';
  static const textPreview = 'Which word is closest in meaning to DILIGENT?';

  static String estimateNeeds(int n) =>
      'Answer $n more ${n == 1 ? 'question' : 'questions'} across all sections to see your estimated score.';
  static String sectionNeeds(int n) => '$n more ${n == 1 ? 'answer' : 'answers'} needed';
  static String sectionTally(int correct, int attempts) => '$correct / $attempts correct';
  static String weakest(String topic, int pct) => 'Weakest: $topic ($pct%)';
  static String topicAccuracy(int pct, int attempts) => '$pct% of $attempts recent answers';
  static String examCountdown(int days) => switch (days) {
        < 0 => 'Your exam date has passed',
        0 => 'Exam day. Good luck!',
        1 => 'Exam is tomorrow',
        _ => '$days days to your exam',
      };
  static String goalProgress(int answered, int goal) => '$answered / $goal';
  static String seenOf(int seen, int total) => '$seen of $total questions seen';
  static String masteredCount(int n) => '$n learned (answered right across spaced reviews)';
  static String pace(int perDay) =>
      'See about $perDay new ${perDay == 1 ? 'question' : 'questions'} a day to cover everything before exam day.';
  static String mockLabel(bool full, int items) => full ? 'Full mock · $items items' : 'Mini mock · $items items';
  static String percent(double ratio) => '${(ratio * 100).round()}%';

  static String questionCount(int n) => n == 1 ? '1 question' : '$n questions';
  static String topicProgress(int seen, int total, int accuracyPct) =>
      seen == 0 ? '$total questions' : '$seen of $total seen · $accuracyPct% correct';
  static String unansweredWarning(int n) => n == 0
      ? 'You have answered every item.'
      : 'You have $n unanswered ${n == 1 ? 'item' : 'items'}. Unanswered items count as wrong.';
  /// Two short lines, so the label fits a half-width button on a small phone.
  static String mockButton(String name, int items, Duration d) =>
      '$name ($items)\n${d.inHours > 0 ? '${d.inHours}h ' : ''}${d.inMinutes % 60}m';
  static String unlockCta(String price) => 'Unlock for $price';
  static String unlockBanner(int total) => 'Unlock all $total questions';
  static String freeTopicProgress(int seen, int free, int total, int accuracyPct) => seen == 0
      ? '$free of $total questions free'
      : '$seen of $free free seen · $accuracyPct% correct';
  static String moreWithFullAccess(int n) => '$n more questions with full access';
  static const freeTopicDone = "You've practiced every free question here. Unlock the rest to keep seeing new ones.";
  static String progress(int current, int total) => 'Question $current of $total';
}
