import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content/question.dart';
import '../../core/quiz/mock_exam.dart';
import '../../data/progress_providers.dart';
import '../../data/settings_providers.dart';
import '../premium/study_bank.dart';

/// Wall-clock time for exam start and submit; overridable in tests.
final mockNowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final mockControllerProvider =
    NotifierProvider.autoDispose.family<MockController, MockSession?, MockExamSpec>(
  MockController.new,
);

/// State is null only when the bank has no questions for the chosen level.
class MockController extends AutoDisposeFamilyNotifier<MockSession?, MockExamSpec> {
  @override
  MockSession? build(MockExamSpec spec) {
    // Mocks are opened from home after the bank has loaded. Read (not watch)
    // the bank and cards: a purchase, restore or answer must never rebuild,
    // and so reshuffle, an exam in progress.
    final bank = ref.read(studyBankProvider).requireValue;
    final cards = ref.read(cardsProvider).valueOrNull ?? const {};
    final questions = assembleMockExam(bank, spec, cards: cards);
    return questions.isEmpty ? null : MockSession.start(spec, questions, ref.read(mockNowProvider)());
  }

  void select(int choice) => state = state?.select(choice);

  void toggleFlag() => state = state?.toggleFlag();

  void goTo(int index) => state = state?.goTo(index);

  /// Submits once; later calls (e.g. the timer firing after a manual submit)
  /// are ignored.
  void submit() {
    final session = state;
    if (session == null || session.isSubmitted) return;
    final submitted = session.submit(ref.read(mockNowProvider)());
    state = submitted;
    final level = ref.read(examLevelProvider) ?? ExamLevel.professional;
    unawaited(
      ref
          .read(progressRepositoryProvider)
          .recordMockExam(submitted, level)
          .catchError((Object e) => debugPrint('[Mock] failed to save result: $e')),
    );
  }
}
