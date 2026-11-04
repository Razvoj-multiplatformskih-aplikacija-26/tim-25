import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

MemoryQueueStore store() => MemoryQueueStore(
  seed: demoSeed(),
  clock: demoClock,
  latency: Duration.zero,
);
Future<QueueSnapshot> load(MemoryQueueStore repo) async =>
    (await repo.load() as Success<QueueSnapshot>).value;
void main() {
  test('Seed: 12 mojih prijava, šest stanja, jedna aktivna po salonu', () {
    final data = demoSeed();
    final mine = data.entries
        .where((e) => e.clientId == demoClient.id)
        .toList();
    expect(mine.length, greaterThanOrEqualTo(10));
    expect(mine.map((e) => e.status).toSet(), QueueStatus.values.toSet());
    for (final salon in data.salons) {
      expect(
        mine.where((e) => e.salonId == salon.id && e.status.isActive).length,
        lessThanOrEqualTo(1),
      );
    }
  });
  test('Paralelne prijave: jedna uspeva, druga vidi novo stanje', () async {
    final repo = store();
    final results = await Future.wait(
      List.generate(
        2,
        (_) => repo.join(
          actor: demoClient,
          salonId: const SalonId('s3'),
          serviceId: const ServiceId('cut3'),
          note: '',
        ),
      ),
    );
    expect(results.whereType<Success<QueueSnapshot>>().length, 1);
    expect(
      (results.whereType<Failure<QueueSnapshot>>().single).error,
      isA<ActiveEntryAlreadyExists>(),
    );
    final data = await load(repo);
    expect(
      data.entries
          .where(
            (e) => e.salonId == const SalonId('s3') && e.status.occupiesBarber,
          )
          .length,
      1,
    );
  });
  test('Istovremena promena revizije: zastareli zahtev se odbija', () async {
    final repo = store();
    final called = (await load(repo)).entries
        .singleWhere((e) => e.id == const QueueEntryId('active-1'));
    final results = await Future.wait([
      repo.transition(
        actor: demoStaff,
        entryId: called.id,
        expectedRevision: called.revision,
        target: QueueStatus.inProgress,
      ),
      repo.transition(
        actor: demoStaff,
        entryId: called.id,
        expectedRevision: called.revision,
        target: QueueStatus.noShow,
      ),
    ]);
    expect(results.whereType<Success<QueueSnapshot>>().length, 1);
    expect(
      results.whereType<Failure<QueueSnapshot>>().single.error,
      isA<Conflict>(),
    );
  });
  test(
    'Povratak na rad, početak, završetak i nedolazak automatski oslobađaju red',
    () async {
      final repo = store();
      await repo.setAvailability(
        actor: demoStaff,
        barberId: const BarberId('cut-b0'),
        availability: BarberAvailability.working,
      );
      var data = await load(repo);
      expect(
        data.entries
            .singleWhere((e) => e.id == const QueueEntryId('active-0'))
            .status,
        QueueStatus.waiting,
      );
      var called = data.entries.singleWhere(
        (e) => e.id == const QueueEntryId('other-0'),
      );
      expect(called.status, QueueStatus.called);
      await repo.transition(
        actor: demoStaff,
        entryId: called.id,
        expectedRevision: called.revision,
        target: QueueStatus.inProgress,
      );
      data = await load(repo);
      called = data.entries.singleWhere((e) => e.id == called.id);
      await repo.transition(
        actor: demoStaff,
        entryId: called.id,
        expectedRevision: called.revision,
        target: QueueStatus.completed,
      );
      data = await load(repo);
      called = data.entries.singleWhere(
        (e) => e.id == const QueueEntryId('other-1'),
      );
      expect(called.status, QueueStatus.called);
      await repo.transition(
        actor: demoStaff,
        entryId: called.id,
        expectedRevision: called.revision,
        target: QueueStatus.noShow,
      );
      data = await load(repo);
      expect(
        data.entries
            .singleWhere((e) => e.id == const QueueEntryId('other-2'))
            .status,
        QueueStatus.called,
      );
      expect(
        data.entries
            .where(
              (e) =>
                  e.barberId == const BarberId('cut-b0') &&
                  e.status.occupiesBarber,
            )
            .length,
        1,
      );
    },
  );
  test(
    'Greška mutacije ne upisuje podatke; prazan odgovor ne briše memoriju',
    () async {
      final repo = store()..failNextRequest = true;
      expect(
        await repo.join(
          actor: demoClient,
          salonId: const SalonId('s3'),
          serviceId: const ServiceId('cut3'),
          note: '',
        ),
        isA<Failure<QueueSnapshot>>(),
      );
      expect((await load(repo)).entries.length, 17);
      repo.emptyNextLoad = true;
      expect((await load(repo)).entries, isEmpty);
      expect((await load(repo)).entries.length, 17);
    },
  );
  test('Nezavisne instance i serverska granica repozitorijuma', () async {
    final a = store();
    final b = store();
    await a.join(
      actor: demoClient,
      salonId: const SalonId('s3'),
      serviceId: const ServiceId('cut3'),
      note: '',
    );
    expect((await load(a)).entries.length, 18);
    expect((await load(b)).entries.length, 17);
    final missing = await b.transition(
      actor: demoStaff,
      entryId: const QueueEntryId('missing'),
      expectedRevision: 0,
      target: QueueStatus.cancelled,
    );
    expect((missing as Failure<QueueSnapshot>).error, isA<NotFound>());
    final forbidden = await b.setAvailability(
      actor: demoClient,
      barberId: const BarberId('cut-b0'),
      availability: BarberAvailability.working,
    );
    expect((forbidden as Failure<QueueSnapshot>).error, isA<Forbidden>());
  });
}
