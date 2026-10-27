import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/content/question.dart';
import '../core/quiz/scheduler.dart';
import 'app_database.dart';
import 'progress_repository.dart';
import 'settings_providers.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(appDatabaseProvider)),
);

final cardsProvider = StreamProvider<Map<String, CardState>>(
  (ref) => ref.watch(progressRepositoryProvider).watchCards(),
);

final topicStatsProvider = StreamProvider<Map<String, TopicStats>>(
  (ref) => ref.watch(progressRepositoryProvider).watchTopicStats(),
);

/// "Now" for time-based views (due reviews, today's streak). Bumped when the
/// app returns to the foreground so a card that came due, or a new day,
/// shows up without needing a database change.
final clockProvider = StateProvider<DateTime>((ref) => DateTime.now());

final activityProvider = StreamProvider<Activity>((ref) {
  ref.watch(clockProvider);
  return ref.watch(progressRepositoryProvider).watchActivity();
});

/// Number of cards due now. Re-evaluated when the cards or the clock change.
final dueCountProvider = Provider<int>((ref) {
  final cards = ref.watch(cardsProvider).valueOrNull ?? const {};
  ref.watch(clockProvider);
  final now = DateTime.now();
  return cards.values.where((c) => c.isDue(now)).length;
});

/// Mock exam results for the current level, most recent first.
final mockResultsProvider = StreamProvider<List<MockResultSummary>>((ref) {
  final level = ref.watch(examLevelProvider) ?? ExamLevel.professional;
  return ref.watch(progressRepositoryProvider).watchMockResults(level);
});
