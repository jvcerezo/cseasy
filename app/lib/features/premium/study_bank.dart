import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content/question_bank.dart';
import '../../data/progress_providers.dart';
import '../../data/settings_providers.dart';
import 'entitlement_controller.dart';
import 'premium_gate.dart';

/// The questions this user can study: the whole level bank with full access,
/// otherwise the free tier. Practice, review and mocks all draw from it.
final studyBankProvider = FutureProvider<QuestionBank>((ref) async {
  final bank = await ref.watch(examBankProvider.future);
  return ref.watch(isPremiumProvider) ? bank : freeTier(bank);
});

/// Reviews due now among questions in the study bank. Cards for the other
/// level, locked items, or retired content are excluded, so this always
/// matches what a review round will actually contain.
final dueCountProvider = Provider<int>((ref) {
  final cards = ref.watch(cardsProvider).valueOrNull ?? const {};
  final bank = ref.watch(studyBankProvider).valueOrNull;
  ref.watch(clockProvider);
  if (bank == null) return 0;
  final now = DateTime.now();
  return cards.values.where((c) => c.isDue(now) && bank.byId.containsKey(c.questionId)).length;
});
