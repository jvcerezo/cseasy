import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/content/content_providers.dart';
import '../core/content/question.dart';
import '../core/content/question_bank.dart';

/// Overridden in main() with the instance loaded before runApp.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

const _levelKey = 'exam_level';

/// The exam level the user is reviewing for; null until they pick one.
final examLevelProvider = NotifierProvider<ExamLevelController, ExamLevel?>(
  ExamLevelController.new,
);

class ExamLevelController extends Notifier<ExamLevel?> {
  @override
  ExamLevel? build() =>
      ExamLevel.tryFromKey(ref.watch(sharedPreferencesProvider).getString(_levelKey));

  Future<void> set(ExamLevel level) async {
    state = level;
    await ref.read(sharedPreferencesProvider).setString(_levelKey, level.key);
  }
}

/// The question bank narrowed to the chosen level's exam coverage.
final examBankProvider = FutureProvider<QuestionBank>((ref) async {
  final bank = await ref.watch(questionBankProvider.future);
  final level = ref.watch(examLevelProvider) ?? ExamLevel.professional;
  return bank.forLevel(level);
});
