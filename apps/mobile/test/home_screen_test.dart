import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/widgets/discovery_salon_card.dart';
import 'package:use_cases/use_cases.dart';

Future<void> openHome(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    FrizerajMobile(
      minimumSplashDuration: Duration.zero,
      initialLocation: '/',
      repository: MemoryQueueStore(
        seed: demoSeed(),
        clock: demoClock,
        latency: Duration.zero,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Home pretraga, oba sortiranja i prazan rezultat', (
    tester,
  ) async {
    await openHome(tester);
    expect(find.text('Beograd'), findsOneWidget);
    expect(
      tester
          .widgetList<DiscoverySalonCard>(find.byType(DiscoverySalonCard))
          .first
          .salon
          .name,
      'Frizeraj Dorćol',
    );
    await tester.tap(find.text('Najkraće čekanje'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<DiscoverySalonCard>(find.byType(DiscoverySalonCard))
          .first
          .salon
          .name,
      'Studio Vračar',
    );
    await tester.ensureVisible(find.text('Najbolje ocenjeni'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Najbolje ocenjeni'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<DiscoverySalonCard>(find.byType(DiscoverySalonCard))
          .first
          .salon
          .name,
      'Salon Zemun',
    );
    await tester.enterText(find.byType(TextField), 'njegoseva');
    await tester.pumpAndSettle();
    expect(find.text('Studio Vračar'), findsOneWidget);
    expect(find.byType(DiscoverySalonCard), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'nema takvog salona');
    await tester.pumpAndSettle();
    expect(find.text('Nema salona za ovu pretragu.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Zvono otvara stvarnu prijavu, a Profil i Moj red imaju rute', (
    tester,
  ) async {
    await openHome(tester);
    await tester.tap(find.byTooltip('Obaveštenja'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pozvan si — tvoj frizer je spreman.'));
    await tester.pumpAndSettle();
    expect(find.text('ID: active-1'), findsOneWidget);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Boris Bošković'), findsOneWidget);
    await tester.tap(find.text('Moj red'));
    await tester.pumpAndSettle();
    expect(find.text('Tvoje posete'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Uži telefon ne preliva sadržaj i dozvoljava dolazak do poslednjeg salona',
    (tester) async {
      await openHome(tester, size: const Size(320, 640));
      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Frizeraj Novi Beograd'));
      await tester.pumpAndSettle();
      expect(find.text('Prijavi se u red'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
