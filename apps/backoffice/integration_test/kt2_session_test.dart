import 'package:backoffice/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> _until(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  expect(
    finder,
    findsAtLeastNWidgets(1),
    reason: tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .take(12)
        .join(' | '),
  );
}

Future<void> _login(WidgetTester tester, String username) async {
  await _until(
    tester,
    find.byWidgetPredicate(
      (widget) => widget is FilledButton && widget.onPressed != null,
    ),
  );
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), username);
  await tester.enterText(fields.at(1), 'FrizerajDemo26');
  await tester.tap(find.text('Prijavi se'));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Windows: uloge, Credential Manager, obnova i odjava', (
    tester,
  ) async {
    final logout = find
        .byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == 'Odjavi se',
        )
        .hitTestable();
    app.main();
    await _until(
      tester,
      find
          .byWidgetPredicate(
            (widget) =>
                (widget is Text && widget.data == 'Prijavi se') ||
                (widget is IconButton && widget.tooltip == 'Odjavi se'),
          )
          .hitTestable(),
    );
    if (logout.evaluate().isNotEmpty) {
      await tester.tap(logout);
      await _until(tester, find.text('Prijavi se'));
    }
    await _login(tester, 'boris');
    await _until(tester, find.text('Backoffice je za osoblje salona.'));
    await _login(tester, 'osoblje');
    await _until(tester, find.text('Pregled reda'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    app.main();
    await _until(tester, logout);
    await tester.tap(logout);
    await _until(tester, find.text('Prijavi se'));
  });
}
