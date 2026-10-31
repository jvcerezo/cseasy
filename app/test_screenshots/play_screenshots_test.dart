// Renders raw Play Store phone screenshots (1080x1920) with real fonts.
// Not part of `flutter test`; run it explicitly, then frame the output:
//   flutter test test_screenshots/play_screenshots_test.dart
//   python ../pipeline/render_store_graphics.py

// Lives outside test/, so the analyzer doesn't treat it as a test file.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:io';
import 'dart:ui' as ui;

import 'package:cseasy/core/content/content_providers.dart';
import 'package:cseasy/core/content/question.dart';
import 'package:cseasy/core/content/question_bank.dart';
import 'package:cseasy/core/strings.dart';
import 'package:cseasy/core/theme/app_theme.dart';
import 'package:cseasy/data/app_database.dart';
import 'package:cseasy/data/progress_providers.dart';
import 'package:cseasy/data/settings_providers.dart';
import 'package:cseasy/features/home/home_screen.dart';
import 'package:cseasy/features/mock/mock_controller.dart';
import 'package:cseasy/features/premium/entitlement_controller.dart';
import 'package:cseasy/features/premium/store.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
final _outDir = Directory('build/play_screenshots')..createSync(recursive: true);
final _boundaryKey = GlobalKey();

/// Mock exam clock, advanced by hand so results show a realistic time used.
var _mockNow = DateTime.now();

Future<void> _loadFonts() async {
  final cache = '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('$cache/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await load('Roboto', ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf', 'roboto-italic.ttf']);
  await load('MaterialIcons', ['materialicons-regular.otf']);
}

Future<void> _pumpApp(WidgetTester tester, {String level = 'professional'}) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'exam_level': level});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));

  await tester.pumpWidget(RepaintBoundary(
    key: _boundaryKey,
    child: ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        questionBankProvider.overrideWith((ref) async => _bank),
        appDatabaseProvider.overrideWithValue(db),
        storeProvider.overrideWithValue(_OfflineStore()),
        mockNowProvider.overrideWithValue(() => _mockNow),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        home: const HomeScreen(),
      ),
    ),
  ));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();
  }
}

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

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary = _boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.625);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('${_outDir.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

/// The question currently on screen, found by its stem.
Question _onScreen(WidgetTester tester) {
  final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().toSet();
  return _bank.questions.firstWhere((q) => texts.contains(q.stem));
}

Future<void> _answer(WidgetTester tester, {required bool correct}) async {
  final q = _onScreen(tester);
  final pick = correct ? q.answer : (q.answer + 1) % q.choices.length;
  await _tapText(tester, q.choices[pick]);
}

Future<void> _back(WidgetTester tester) async {
  await tester.pageBack();
  await _settle(tester);
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('play screenshots', (tester) async {
    await _pumpApp(tester);

    // A short round first, so home shows a streak and topic progress.
    await _tapText(tester, '1987 Constitution');
    // Answer a few, stopping on a short item so question and explanation fit.
    for (var i = 0; i < 9 && (i < 4 || _onScreen(tester).stem.length > 110); i++) {
      await _answer(tester, correct: i != 2);
      await tester.tap(find.text(Strings.next));
      await _settle(tester);
    }
    await _answer(tester, correct: true);
    await _capture(tester, '02-explanation');
    await _back(tester);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    await _capture(tester, '01-home');

    await _tapText(tester, 'Data Interpretation');
    await _capture(tester, '03-data-interpretation');
    await _back(tester);

    await tester.scrollUntilVisible(find.textContaining('Mini ('), -200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.textContaining('Mini ('));
    await _settle(tester);
    // 43 of 50 right, so the results read as a pass.
    var mockCaptured = false;
    for (var i = 0; i < 50; i++) {
      await _answer(tester, correct: i % 7 != 3);
      // Capture a mid-exam item short enough to fit without scrolling.
      if (!mockCaptured && i >= 8 && _onScreen(tester).stem.length < 160) {
        await _capture(tester, '04-mock');
        mockCaptured = true;
      }
      if (i < 49) {
        await tester.tap(find.text(Strings.next));
        await tester.pumpAndSettle();
      }
    }
    _mockNow = _mockNow.add(const Duration(minutes: 41));
    await tester.tap(find.byTooltip('All items'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Submit').last);
    await _settle(tester);
    await _capture(tester, '05-results');
    await _back(tester);

    await _tapText(tester, 'Sawikain (Filipino)');
    await _answer(tester, correct: true);
    await _capture(tester, '06-filipino');

    await tester.pumpWidget(const SizedBox());
    await _settle(tester);
  });
}
