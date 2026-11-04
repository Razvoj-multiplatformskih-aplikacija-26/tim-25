import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';
import 'package:mobile/app.dart';
import 'package:use_cases/use_cases.dart';

MemoryQueueStore store() => MemoryQueueStore(
  seed: demoSeed(),
  clock: demoClock,
  latency: const Duration(milliseconds: 50),
);
void main() {
  testWidgets('Osvežavanje posle ulaska čuva rutu i ne vraća splash', (
    tester,
  ) async {
    await tester.pumpWidget(
      FrizerajMobile(
        minimumSplashDuration: Duration.zero,
        repository: store(),
        initialLocation: '/entries/active-1',
      ),
    );
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('ID: active-1'), findsOneWidget);
    await tester.tap(find.byTooltip('Osveži'));
    await tester.pump();
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('ID: active-1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Detalj se obnavlja samo iz ID-a rute', (tester) async {
    await tester.pumpWidget(
      FrizerajMobile(
        minimumSplashDuration: Duration.zero,
        repository: store(),
        initialLocation: '/entries/active-1',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ID: active-1'), findsOneWidget);
    expect(find.text('Frizer: Ana'), findsOneWidget);
    expect(find.text('Pozvan'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Loading, error, retry, lista, detalj i potvrda otkazivanja', (
    tester,
  ) async {
    final repo = store()..failNextRequest = true;
    await tester.pumpWidget(
      FrizerajMobile(
        minimumSplashDuration: Duration.zero,
        repository: repo,
        initialLocation: '/',
      ),
    );
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Pokušaj ponovo'), findsOneWidget);
    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pumpAndSettle();
    expect(find.text('Frizeraj Dorćol'), findsOneWidget);
    await tester.tap(find.text('Moj red'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Frizeraj Dorćol').first);
    await tester.pumpAndSettle();
    expect(find.text('Pozicija u redu: 1'), findsOneWidget);
    await tester.tap(find.text('Otkaži prijavu'));
    await tester.pumpAndSettle();
    expect(find.text('Ovu promenu nije moguće poništiti.'), findsOneWidget);
    await tester.tap(find.text('Odustani'));
    await tester.pumpAndSettle();
    expect(find.text('Na čekanju'), findsOneWidget);
    await tester.tap(find.text('Otkaži prijavu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Potvrdi'));
    await tester.pumpAndSettle();
    expect(find.text('Otkazan'), findsOneWidget);
    expect(find.text('Otkaži prijavu'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Forma prikazuje zajedničko pravilo napomene i kreira prijavu', (
    tester,
  ) async {
    final repo = store();
    await tester.pumpWidget(
      FrizerajMobile(
        minimumSplashDuration: Duration.zero,
        repository: repo,
        initialLocation: '/',
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Frizeraj Novi Beograd'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prijavi se u red'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<ServiceId>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Šišanje • 1400 RSD').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      'x' * (maxNoteLength + 1),
    );
    await tester.ensureVisible(find.text('Potvrdi prijavu'));
    await tester.tap(find.text('Potvrdi prijavu'));
    await tester.pumpAndSettle();
    expect(
      find.text('Napomena može imati najviše $maxNoteLength znakova.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), 'Kratko sa strane');
    await tester.ensureVisible(find.text('Potvrdi prijavu'));
    await tester.tap(find.text('Potvrdi prijavu'));
    await tester.pumpAndSettle();
    expect(find.text('Pozvan'), findsOneWidget);
    expect(find.text('Frizer: Mina'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Prazne prijave imaju osvežavanje', (tester) async {
    final repo = store()..emptyNextLoad = true;
    await tester.pumpWidget(
      FrizerajMobile(
        minimumSplashDuration: Duration.zero,
        repository: repo,
        initialLocation: '/',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moj red'));
    await tester.pumpAndSettle();
    expect(find.text('Nema prijava za prikaz.'), findsOneWidget);
    await tester.tap(find.text('Osveži'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
