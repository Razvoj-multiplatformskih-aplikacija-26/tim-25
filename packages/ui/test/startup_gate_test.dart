import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';

void main() {
  testWidgets('Brzi podaci ne preskaču uvod od 1600 ms', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: frizerajTheme(),
        home: StartupGate(
          ready: true,
          onRetry: () {},
          child: const Scaffold(body: Text('Sadržaj aplikacije')),
        ),
      ),
    );
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 950));
    expect(
      tester
          .widget<SplashBackground>(find.byType(SplashBackground))
          .exitProgress,
      1,
    );
    final contentClip = find.ancestor(
      of: find.text('Sadržaj aplikacije'),
      matching: find.byType(ClipPath),
    );
    expect(
      tester
          .widget<ClipPath>(contentClip)
          .clipper!
          .getClip(const Size(800, 600))
          .getBounds()
          .isEmpty,
      isTrue,
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      tester
          .widget<ClipPath>(contentClip)
          .clipper!
          .getClip(const Size(800, 600))
          .getBounds()
          .isEmpty,
      isFalse,
    );
    await tester.pumpAndSettle();
    expect(find.text('Sadržaj aplikacije'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Otkrivanje čuva stanje sadržaja i blokira prerani dodir', (
    tester,
  ) async {
    var taps = 0;
    var builds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StartupGate(
          ready: true,
          minimumDisplayDuration: const Duration(milliseconds: 1),
          onRetry: () {},
          child: StatefulBuilder(
            builder: (context, setState) {
              builds++;
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => taps++,
                    child: const Text('Otvori salon'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 425));
    final button = find.text('Otvori salon');
    final elementDuringReveal = tester.element(button);
    await tester.tap(button, warnIfMissed: false);
    expect(taps, 0);
    await tester.pumpAndSettle();
    expect(tester.element(button), same(elementDuringReveal));
    expect(builds, greaterThan(0));
    await tester.tap(button);
    expect(taps, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Smanjene animacije preskaču prelaz posle učitavanja', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: StartupGate(
          ready: true,
          minimumDisplayDuration: const Duration(milliseconds: 1),
          onRetry: () {},
          child: const Text('Sadržaj aplikacije'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('Sadržaj aplikacije'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Prvo čeka podatke, a kasnije učitavanje ne vraća splash', (
    tester,
  ) async {
    final ready = ValueNotifier(false);
    addTearDown(ready.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: frizerajTheme(),
        home: ValueListenableBuilder<bool>(
          valueListenable: ready,
          builder: (_, value, _) => StartupGate(
            ready: value,
            onRetry: () {},
            child: const Scaffold(body: Text('Sadržaj aplikacije')),
          ),
        ),
      ),
    );
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    expect(find.byType(SplashScreen), findsOneWidget);
    ready.value = true;
    await tester.pumpAndSettle();
    expect(find.text('Sadržaj aplikacije'), findsOneWidget);
    ready.value = false;
    await tester.pumpAndSettle();
    expect(find.text('Sadržaj aplikacije'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Početna greška daje retry bez otvaranja aplikacije', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: frizerajTheme(),
        home: StartupGate(
          ready: false,
          error: const RepositoryUnavailable(),
          onRetry: () => retries++,
          child: const Scaffold(body: Text('Sadržaj aplikacije')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sadržaj aplikacije'), findsNothing);
    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pumpAndSettle();
    expect(retries, 1);
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
