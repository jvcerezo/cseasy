import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content/content_providers.dart';
import '../../core/content/question.dart';
import '../../core/content/topic_labels.dart';
import '../../core/quiz/quiz_session.dart';

const practiceRoundSize = 10;

/// What a practice round draws from: one topic, or a whole section when [topic] is null.
class PracticeScope {
  final Section section;
  final String? topic;

  const PracticeScope.topic(this.section, String this.topic);
  const PracticeScope.section(this.section) : topic = null;

  String get title => switch (topic) {
        final t? => topicLabel(t),
        null => section.label,
      };

  @override
  bool operator ==(Object other) =>
      other is PracticeScope && other.section == section && other.topic == topic;

  @override
  int get hashCode => Object.hash(section, topic);
}

final practiceControllerProvider =
    NotifierProvider.autoDispose.family<PracticeController, QuizSession, PracticeScope>(
  PracticeController.new,
);

class PracticeController extends AutoDisposeFamilyNotifier<QuizSession, PracticeScope> {
  @override
  QuizSession build(PracticeScope scope) {
    // Practice is only reachable from the home screen after the bank has loaded.
    final bank = ref.watch(questionBankProvider).requireValue;
    final pool = switch (scope.topic) {
      final t? => bank.byTopic(t),
      null => bank.bySection(scope.section),
    };
    return QuizSession.start(pool, count: practiceRoundSize);
  }

  void select(int choice) => state = state.select(choice);

  void advance() => state = state.advance();

  void restart() => ref.invalidateSelf();
}
