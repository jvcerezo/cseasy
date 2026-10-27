import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'question_bank.dart';

const _contentAsset = 'assets/content/cse.json';

final questionBankProvider = FutureProvider<QuestionBank>((ref) async {
  final raw = await rootBundle.loadString(_contentAsset);
  return compute(parseQuestionBank, raw);
});
