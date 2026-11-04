import 'package:backoffice/app.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:use_cases/use_cases.dart';

final class ReplacementRepository implements QueueRepository {
  final store = MemoryQueueStore(
    seed: demoSeed(),
    clock: demoClock,
    latency: Duration.zero,
  );
  int loads = 0;
  @override
  Future<Result<QueueSnapshot>> load() {
    loads++;
    return store.load();
  }

  @override
  Future<Result<QueueSnapshot>> join({
    required User actor,
    required SalonId salonId,
    required ServiceId serviceId,
    required String note,
  }) => store.join(
    actor: actor,
    salonId: salonId,
    serviceId: serviceId,
    note: note,
  );
  @override
  Future<Result<QueueSnapshot>> transition({
    required User actor,
    required QueueEntryId entryId,
    required int expectedRevision,
    required QueueStatus target,
  }) => store.transition(
    actor: actor,
    entryId: entryId,
    expectedRevision: expectedRevision,
    target: target,
  );
  @override
  Future<Result<QueueSnapshot>> setAvailability({
    required User actor,
    required BarberId barberId,
    required BarberAvailability availability,
  }) => store.setAvailability(
    actor: actor,
    barberId: barberId,
    availability: availability,
  );
}

void main() {
  setUpWidgets(WidgetTester tester) {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  for (final mobile in [true, false]) {
    final clientName = mobile ? 'mobile' : 'backoffice';
    testWidgets('Zamena porta bez izmene ekrana: $clientName', (tester) async {
      setUpWidgets(tester);
      final repo = ReplacementRepository();
      await tester.pumpWidget(
        mobile
            ? FrizerajMobile(
                repository: repo,
                minimumSplashDuration: Duration.zero,
                initialLocation: '/entries/active-1',
              )
            : FrizerajBackoffice(
                repository: repo,
                minimumSplashDuration: Duration.zero,
                initialLocation: '/entries/active-1',
              ),
      );
      await tester.pumpAndSettle();
      expect(repo.loads, 1);
      expect(find.text('ID: active-1'), findsOneWidget);
      expect(find.text('Frizer: Ana'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Domensko pravilo kontroliše akciju: $clientName', (
      tester,
    ) async {
      setUpWidgets(tester);
      final repo = ReplacementRepository();
      await tester.pumpWidget(
        mobile
            ? FrizerajMobile(
                repository: repo,
                minimumSplashDuration: Duration.zero,
                initialLocation: '/entries/active-0',
              )
            : FrizerajBackoffice(
                repository: repo,
                minimumSplashDuration: Duration.zero,
                initialLocation: '/entries/active-0',
              ),
      );
      await tester.pumpAndSettle();
      const allowed = bool.fromEnvironment(
        'KT1_CANCEL_ALLOWED',
        defaultValue: true,
      );
      expect(
        find.text('Otkaži prijavu'),
        allowed ? findsOneWidget : findsNothing,
      );
      expect(find.text('ID: active-0'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('Backoffice prazan odgovor i povratak podataka', (tester) async {
    setUpWidgets(tester);
    final repo = ReplacementRepository()..store.emptyNextLoad = true;
    await tester.pumpWidget(
      FrizerajBackoffice(
        repository: repo,
        minimumSplashDuration: Duration.zero,
        initialLocation: '/',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nema prijava za prikaz.'), findsOneWidget);
    await tester.tap(find.byTooltip('Osveži (Ctrl+R)'));
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('17 ukupno'), findsOneWidget);
    expect(repo.loads, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Backoffice nedolazak zahteva potvrdu', (tester) async {
    setUpWidgets(tester);
    final repo = ReplacementRepository();
    await tester.pumpWidget(
      FrizerajBackoffice(
        repository: repo,
        minimumSplashDuration: Duration.zero,
        initialLocation: '/entries/active-1',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evidentiraj nedolazak'));
    await tester.pumpAndSettle();
    expect(find.text('Ovu promenu nije moguće poništiti.'), findsOneWidget);
    await tester.tap(find.text('Odustani'));
    await tester.pumpAndSettle();
    var data =
        (await tester.runAsync(repo.load) as Success<QueueSnapshot>).value;
    expect(
      data.entries
          .singleWhere((entry) => entry.id == const QueueEntryId('active-1'))
          .status,
      QueueStatus.called,
    );
    await tester.tap(find.text('Evidentiraj nedolazak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Potvrdi'));
    await tester.pumpAndSettle();
    data = (await tester.runAsync(repo.load) as Success<QueueSnapshot>).value;
    expect(
      data.entries
          .singleWhere((entry) => entry.id == const QueueEntryId('active-1'))
          .status,
      QueueStatus.noShow,
    );
    expect(find.text('Evidentiraj nedolazak'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
