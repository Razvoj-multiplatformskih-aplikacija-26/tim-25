import 'package:backoffice/app.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  testWidgets('Backoffice detalj radi iz direktne rute', (tester) async {
    final repo = MemoryQueueStore(
      seed: demoSeed(),
      clock: demoClock,
      latency: Duration.zero,
    );
    await tester.pumpWidget(
      FrizerajBackoffice(
        minimumSplashDuration: Duration.zero,
        repository: repo,
        initialLocation: '/entries/active-1',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ID: active-1'), findsOneWidget);
    expect(find.text('Frizer: Ana'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'Tastatura započinje i završava; izbor ostaje posle promene širine',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = MemoryQueueStore(
        seed: demoSeed(),
        clock: demoClock,
        latency: const Duration(milliseconds: 30),
      );
      await tester.pumpWidget(
        FrizerajBackoffice(
          minimumSplashDuration: Duration.zero,
          repository: repo,
          initialLocation: '/',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DataTable), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('ID: active-0'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('ID: active-1'), findsOneWidget);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.text('Završi uslugu (Ctrl+Enter)'), findsOneWidget);
      tester.view.physicalSize = const Size(600, 1000);
      await tester.pumpAndSettle();
      expect(find.byType(DataTable), findsNothing);
      expect(find.text('ID: active-1'), findsOneWidget);
      tester.view.physicalSize = const Size(1440, 1000);
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.text('Završi uslugu (Ctrl+Enter)'), findsNothing);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.text('ID: active-1'), findsOneWidget);
      final data = (await tester.runAsync(
        () => repo.load(),
      ) as Success<QueueSnapshot>).value;
      expect(
        data.entries
            .singleWhere((e) => e.id == const QueueEntryId('active-1'))
            .status,
        QueueStatus.completed,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('Greška i retry rade i u backoffice-u', (tester) async {
    final repo = MemoryQueueStore(
      seed: demoSeed(),
      clock: demoClock,
      latency: Duration.zero,
    )..failNextRequest = true;
    await tester.pumpWidget(
      FrizerajBackoffice(
        minimumSplashDuration: Duration.zero,
        repository: repo,
        initialLocation: '/',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pokušaj ponovo'), findsOneWidget);
    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pumpAndSettle();
    expect(find.text('Frizeri • 8'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
