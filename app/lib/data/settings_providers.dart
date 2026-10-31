import 'package:flutter/material.dart' show ThemeMode;
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

const _examDateKey = 'exam_date';
const _dailyGoalKey = 'daily_goal';
const _themeModeKey = 'theme_mode';
const _textScaleKey = 'text_scale';

/// The user's exam day (date only); null until they set one.
final examDateProvider = NotifierProvider<ExamDateController, DateTime?>(ExamDateController.new);

class ExamDateController extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_examDateKey);
    final parsed = raw == null ? null : DateTime.tryParse(raw);
    return parsed == null ? null : DateTime(parsed.year, parsed.month, parsed.day);
  }

  Future<void> set(DateTime? date) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (date == null) {
      state = null;
      await prefs.remove(_examDateKey);
      return;
    }
    final day = DateTime(date.year, date.month, date.day);
    state = day;
    // yyyy-mm-dd only: a date, not an instant, so time zones can't shift it.
    await prefs.setString(_examDateKey, day.toIso8601String().substring(0, 10));
  }
}

/// Choices offered for the daily goal, in answers per day.
const dailyGoalOptions = [10, 20, 30, 50];
const defaultDailyGoal = 20;

final dailyGoalProvider = NotifierProvider<DailyGoalController, int>(DailyGoalController.new);

class DailyGoalController extends Notifier<int> {
  @override
  int build() {
    final stored = ref.watch(sharedPreferencesProvider).getInt(_dailyGoalKey);
    return dailyGoalOptions.contains(stored) ? stored! : defaultDailyGoal;
  }

  Future<void> set(int goal) async {
    if (!dailyGoalOptions.contains(goal)) throw ArgumentError.value(goal, 'goal');
    state = goal;
    await ref.read(sharedPreferencesProvider).setInt(_dailyGoalKey, goal);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_themeModeKey);
    return ThemeMode.values.firstWhere((m) => m.name == stored, orElse: () => ThemeMode.system);
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_themeModeKey, mode.name);
  }
}

/// In-app text size, applied on top of the phone's own font size setting.
enum TextSize {
  normal(1.0, 'Normal'),
  large(1.15, 'Large'),
  larger(1.3, 'Larger');

  final double factor;
  final String label;
  const TextSize(this.factor, this.label);
}

final textSizeProvider = NotifierProvider<TextSizeController, TextSize>(TextSizeController.new);

class TextSizeController extends Notifier<TextSize> {
  @override
  TextSize build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_textScaleKey);
    return TextSize.values.firstWhere((s) => s.name == stored, orElse: () => TextSize.normal);
  }

  Future<void> set(TextSize size) async {
    state = size;
    await ref.read(sharedPreferencesProvider).setString(_textScaleKey, size.name);
  }
}
