import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content/question_bank.dart';
import '../../data/settings_providers.dart';
import 'entitlement_controller.dart';
import 'premium_gate.dart';

/// The questions this user can study: the whole level bank with full access,
/// otherwise the free tier. Practice, review and mocks all draw from it.
final studyBankProvider = FutureProvider<QuestionBank>((ref) async {
  final bank = await ref.watch(examBankProvider.future);
  return ref.watch(isPremiumProvider) ? bank : freeTier(bank);
});
