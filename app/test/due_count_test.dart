import 'dart:io';

import 'package:cseasy/core/content/content_providers.dart';
import 'package:cseasy/core/content/question.dart';
import 'package:cseasy/core/content/question_bank.dart';
import 'package:cseasy/data/app_database.dart';
import 'package:cseasy/data/progress_providers.dart';
import 'package:cseasy/data/progress_repository.dart';
import 'package:cseasy/data/settings_providers.dart';
import 'package:cseasy/features/premium/entitlement_controller.dart';
import 'package:cseasy/features/premium/study_bank.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The home "Due for review" count must match what a review round can
/// actually contain: only questions in the current level's study bank.
void main() {
  final bank = parseQuestionBank(File('assets/content/cse.json').readAsStringSync());
  final analytical = bank.questions.firstWhere((q) => q.section == Section.analytical);
  final clerical = bank.questions.firstWhere((q) => q.section == Section.clerical);

  test('due count ignores cards from the other exam level', () async {
    SharedPreferences.setMockInitialValues({'exam_level': 'professional', 'has_full_access': true});
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
      questionBankProvider.overrideWith((ref) async => bank),
      appDatabaseProvider.overrideWithValue(db),
      isPremiumProvider.overrideWithValue(true),
    ]);
    addTearDown(container.dispose);

    // Two misses (due immediately): one Professional-only, one Sub-Professional-only.
    final repo = ProgressRepository(db);
    final now = DateTime.now().subtract(const Duration(minutes: 1));
    await repo.recordAnswer(analytical, (analytical.answer + 1) % 4, now);
    await repo.recordAnswer(clerical, (clerical.answer + 1) % 4, now);

    container.listen(dueCountProvider, (_, _) {});
    await container.read(studyBankProvider.future);
    await container.read(cardsProvider.future);
    expect(container.read(dueCountProvider), 1);

    await container.read(examLevelProvider.notifier).set(ExamLevel.subprofessional);
    await container.read(studyBankProvider.future);
    expect(container.read(dueCountProvider), 1, reason: 'now only the clerical card counts');
  });

  test('QuestionBank filters keep ids consistent', () {
    final pro = bank.forLevel(ExamLevel.professional);
    expect(pro.byId.containsKey(analytical.id), isTrue);
    expect(pro.byId.containsKey(clerical.id), isFalse);
  });
}
