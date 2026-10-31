import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/content/question.dart';
import '../core/quiz/readiness.dart';
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

/// Mock exam results for the current level, most recent first.
final mockResultsProvider = StreamProvider<List<MockResultSummary>>((ref) {
  final level = ref.watch(examLevelProvider) ?? ExamLevel.professional;
  return ref.watch(progressRepositoryProvider).watchMockResults(level);
});

/// Per-topic tallies over the readiness window, ending at [clockProvider].
final recentTalliesProvider = StreamProvider<Map<String, Tally>>((ref) {
  final since = ref.watch(clockProvider).subtract(readinessWindow);
  return ref.watch(progressRepositoryProvider).watchTopicTalliesSince(since);
});

/// Readiness for the chosen level; null while the bank is loading.
final readinessProvider = Provider<Readiness?>((ref) {
  final bank = ref.watch(examBankProvider).valueOrNull;
  if (bank == null) return null;
  return computeReadiness(bank, ref.watch(recentTalliesProvider).valueOrNull ?? const {});
});
