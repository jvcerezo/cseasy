import '../../core/content/question.dart';
import '../../core/content/question_bank.dart';

/// Play Console in-app product (non-consumable, one-time).
const fullAccessProductId = 'cseasy_full_access';

/// Free users get the first N questions of every topic. With ~30 topics per
/// level that is enough for one complete full-length mock from free items.
const freeQuestionsPerTopic = 10;

/// Free users can sit this many full-length mocks; mini mocks are unlimited.
const freeFullMocks = 1;

/// The free slice of [bank]: the first [freeQuestionsPerTopic] items of each
/// topic in id order, so the free set is stable across content updates that
/// only append items.
QuestionBank freeTier(QuestionBank bank) {
  final free = <Question>[];
  for (final section in bank.sections) {
    for (final topic in bank.topicsBySection[section]!) {
      final items = [...bank.byTopic(topic)]..sort((a, b) => a.id.compareTo(b.id));
      free.addAll(items.take(freeQuestionsPerTopic));
    }
  }
  return QuestionBank(bank.version, free);
}

bool canStartFullMock({required bool isPremium, required int fullMocksTaken}) =>
    isPremium || fullMocksTaken < freeFullMocks;
