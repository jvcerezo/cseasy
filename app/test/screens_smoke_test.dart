// Drives every screen and modal on a small phone with large text, so
// overflows and runtime errors in real layouts fail the test.
//
// Run with the report link enabled:
//   flutter test test/screens_smoke_test.dart --dart-define=SUPPORT_EMAIL=test@example.com

import 'dart:async';
import 'dart:io';

import 'package:cseasy/core/content/content_providers.dart';
import 'package:cseasy/core/content/question.dart';
import 'package:cseasy/core/content/question_bank.dart';
import 'package:cseasy/core/quiz/mock_exam.dart';
import 'package:cseasy/core/strings.dart';
import 'package:cseasy/core/theme/app_theme.dart';
import 'package:cseasy/data/app_database.dart';
import 'package:cseasy/data/progress_providers.dart';
import 'package:cseasy/data/settings_providers.dart';
import 'package:cseasy/features/ads/ads.dart';
import 'package:cseasy/features/home/home_screen.dart';
import 'package:cseasy/features/onboarding/level_picker_screen.dart';
import 'package:cseasy/features/premium/entitlement_controller.dart';
import 'package:cseasy/features/premium/paywall_screen.dart';
import 'package:cseasy/features/premium/store.dart';
import 'package:cseasy/features/report/report_sheet.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OfflineStore implements Store {
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<ProductDetails?> queryProduct(String id) async => null;
  @override
  Future<bool> buyNonConsumable(ProductDetails product) async => false;
  @override
  Future<void> restorePurchases() async {}
  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}
}

final _bank = parseQuestionBank(File('assets/content/cse.json').readAsStringSync());

Future<void> _pumpApp(
  WidgetTester tester,
  Widget home, {
  String level = 'professional',
  bool premium = false,
}) async {
  tester.view.physicalSize = const Size(320 * 3, 568 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  SharedPreferences.setMockInitialValues({
    'exam_level': level,
    if (premium) 'has_full_access': true,
  });
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));

  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      questionBankProvider.overrideWith((ref) async => _bank),
      appDatabaseProvider.overrideWithValue(db),
      storeProvider.overrideWithValue(_OfflineStore()),
      adsReadyProvider.overrideWith((ref) async => false),
    ],
    child: MaterialApp(theme: buildTheme(Brightness.light), home: home),
  ));
  await _settle(tester);
}

/// Lets drift's background work and Riverpod futures complete.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();
  }
}

/// Scrolls the screen's list until [text] is built and visible, then taps it.
Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await _settle(tester);
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await _settle(tester);
}

final _mini = MockExamSpec.mini(ExamLevel.professional);
final _miniLabel = '${Strings.miniMock}\n${Strings.mockMeta(_mini.itemCount, _mini.duration)}';

void main() {
  testWidgets('level picker (first launch)', (tester) async {
    await _pumpApp(tester, const LevelPickerScreen());
    expect(find.text('Which exam are you taking?'), findsOneWidget);
    await _unmount(tester);
  });

  for (final level in ['professional', 'subprofessional']) {
    testWidgets('home renders for $level, free and premium', (tester) async {
      await _pumpApp(tester, const HomeScreen(), level: level);
      await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      await _unmount(tester);

      await _pumpApp(tester, const HomeScreen(), level: level, premium: true);
      await _unmount(tester);
    });
  }

  testWidgets('practice round: answer, explanation, results, practice again', (tester) async {
    await _pumpApp(tester, const HomeScreen());
    await _tapText(tester, 'Data Interpretation'); // has a table
    for (var i = 0; i < 10; i++) {
      await _tapText(tester, 'A'); // choices can sit below a tall table
      final next = find.text(i == 9 ? 'See results' : 'Next');
      await tester.tap(next);
      await _settle(tester);
    }
    expect(find.textContaining(' / 10'), findsOneWidget);
    // All 10 free items in the topic are now seen, so results offer the unlock.
    await tester.scrollUntilVisible(find.text(Strings.freeTopicDone), 300, scrollable: find.byType(Scrollable).first);
    await _tapText(tester, 'Practice again'); // scrolls past every mistake card
    expect(find.textContaining('Question 1 of'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('mini mock: answer, grid sheet, submit dialog, results', (tester) async {
    await _pumpApp(tester, const HomeScreen());
    await _tapText(tester, _miniLabel);
    await _tapText(tester, 'A');
    await tester.tap(find.byTooltip('Flag for review'));
    await tester.pump();
    await tester.tap(find.byTooltip('All items'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit').last);
    await tester.pumpAndSettle();
    expect(find.text('Submit exam?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Submit').last);
    await _settle(tester);
    expect(find.text('Score by section'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    await _unmount(tester);
  });

  testWidgets('leaving a mock asks for confirmation', (tester) async {
    await _pumpApp(tester, const HomeScreen());
    await _tapText(tester, _miniLabel);
    final NavigatorState navigator = tester.state(find.byType(Navigator).first);
    unawaited(navigator.maybePop());
    await tester.pumpAndSettle();
    expect(find.text('Leave the exam?'), findsOneWidget);
    await tester.tap(find.text('Leave'));
    await _settle(tester);
    expect(find.text('Mock exams'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('paywall with the store offline', (tester) async {
    await _pumpApp(tester, const PaywallScreen());
    expect(find.text('Unlock full access'), findsWidgets);
    await tester.scrollUntilVisible(find.text(Strings.unavailable), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text(Strings.priceLoading), findsNothing, reason: 'not stuck on loading');
    await _unmount(tester);
  });

  testWidgets('report sheet with the keyboard open', (tester) async {
    if (supportEmail.isEmpty) return; // needs --dart-define=SUPPORT_EMAIL
    await _pumpApp(tester, Scaffold(body: ReportButton(question: _bank.questions.first)));
    await tester.tap(find.text('Report a problem'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
    await tester.pumpAndSettle();
    expect(find.text('Send report by email'), findsOneWidget);
    tester.view.resetViewInsets();
    await _unmount(tester);
  });
}
