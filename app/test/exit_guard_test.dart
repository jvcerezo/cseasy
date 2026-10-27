import 'package:cseasy/core/strings.dart';
import 'package:cseasy/shared/widgets/exit_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int exits;

  setUp(() {
    exits = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exits++;
        return null;
      },
    );
  });

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(MaterialApp(
        home: ExitGuard(
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('inner'))),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));

  Future<void> pressBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  testWidgets('back from a pushed screen returns to home without exiting', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await pressBack(tester);

    expect(find.text('inner'), findsNothing);
    expect(find.text('open'), findsOneWidget);
    expect(exits, 0);
  });

  testWidgets('one back on home only shows a hint; a second press exits', (tester) async {
    await pumpApp(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text(Strings.pressBackToExit), findsOneWidget);
    expect(exits, 0);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(exits, 1);
  });

  testWidgets('a second press after the window expires only hints again', (tester) async {
    await pumpApp(tester);

    await pressBack(tester);
    await tester.pump(const Duration(seconds: 3));
    await pressBack(tester);

    expect(exits, 0);
  });
}
