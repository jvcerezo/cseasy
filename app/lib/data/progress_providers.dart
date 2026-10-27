import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/quiz/scheduler.dart';
import 'app_database.dart';
import 'progress_repository.dart';

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

final activityProvider = StreamProvider<Activity>(
  (ref) => ref.watch(progressRepositoryProvider).watchActivity(),
);

/// Number of cards due now. Re-evaluated whenever the cards change.
final dueCountProvider = Provider<int>((ref) {
  final cards = ref.watch(cardsProvider).valueOrNull ?? const {};
  final now = DateTime.now();
  return cards.values.where((c) => c.isDue(now)).length;
});
