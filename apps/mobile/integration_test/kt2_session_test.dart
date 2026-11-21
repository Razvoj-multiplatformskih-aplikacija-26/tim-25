import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/main.dart' as app;

Future<void> _until(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  expect(finder, findsAtLeastNWidgets(1));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final profile = find.text('Profil').hitTestable();
  final loginButton = find.byWidgetPredicate(
    (widget) => widget is FilledButton && widget.onPressed != null,
  );
  Future<void> login(WidgetTester tester) async {
    app.main();
    await _until(
      tester,
      find
          .byWidgetPredicate(
            (widget) =>
                (widget is Text && widget.data == 'Profil') ||
                (widget is FilledButton && widget.onPressed != null),
          )
          .hitTestable(),
    );
    if (profile.evaluate().isNotEmpty) {
      await tester.tap(profile.first);
      await _until(tester, find.text('Odjavi se'));
      await tester.tap(find.text('Odjavi se'));
      await _until(tester, loginButton);
    }
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'boris');
    await tester.enterText(fields.at(1), 'FrizerajDemo26');
    await tester.tap(find.text('Prijavi se'));
    await _until(tester, find.text('Profil'));
  }

  testWidgets('Android: stvarna sesija, obnova i odjava', (tester) async {
    await login(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    app.main();
    await _until(tester, profile);
    await tester.tap(profile.first);
    await _until(tester, find.text('Boris Bošković'));
    await tester.tap(find.text('Odjavi se'));
    await _until(tester, find.text('Prijavi se'));
  });

  testWidgets(
    'Android: stari limit prikaže novo odbijanje sa servera',
    skip: !const bool.fromEnvironment('KT2_CHANGED_RULE'),
    (tester) async {
      await login(tester);
      await _until(tester, profile);
      final search = find.byType(TextField);
      await tester.enterText(search, 'Novi Beograd');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      final salon = find.text('Frizeraj Novi Beograd').hitTestable();
      await _until(tester, salon);
      await tester.tap(salon);
      final openForm = find.text('Prijavi se u red').hitTestable();
      await _until(tester, openForm);
      await tester.tap(openForm);
      final services = find
          .byType(DropdownButtonFormField<ServiceId>)
          .hitTestable();
      await _until(tester, services);
      await tester.tap(services);
      final haircut = find.text('Šišanje • 1400 RSD').hitTestable();
      await _until(tester, haircut);
      await tester.tap(haircut.last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'x' * 80);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      final submit = find.text('Potvrdi prijavu');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await _until(
        tester,
        find.text('Napomena može imati najviše 60 znakova.'),
      );
    },
  );
}
