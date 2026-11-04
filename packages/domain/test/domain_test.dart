import 'package:domain/domain.dart';
import 'package:test/test.dart';

const client = User(id: ClientId('c'), name: 'Klijent', role: Role.client);
const staff = User(id: ClientId('staff'), name: 'Osoblje', role: Role.staff);
final now = DateTime(2026, 10, 31, 12);
QueueEntry entry(
  String id,
  ServiceId service, {
  QueueStatus status = QueueStatus.waiting,
  BarberId? barber,
  ClientId? clientId,
  int sequence = 1,
}) => QueueEntry(
  id: QueueEntryId(id),
  salonId: const SalonId('s'),
  clientId: clientId ?? ClientId(id),
  clientName: id,
  serviceId: service,
  joinedAt: now,
  sequence: sequence,
  status: status,
  barberId: barber,
);
QueueSnapshot snapshot({
  List<QueueEntry> entries = const [],
  List<Barber>? barbers,
}) => QueueSnapshot(
  salons: [
    Salon(
      id: const SalonId('s'),
      name: 'Salon',
      address: 'Adresa',
      hours: OpeningHours(
        weekdays: [6],
        opensAtMinute: 540,
        closesAtMinute: 1200,
      ),
    ),
  ],
  services: [
    const Service(
      id: ServiceId('cut'),
      salonId: SalonId('s'),
      name: 'Šišanje',
      priceRsd: 1000,
      durationMinutes: 30,
    ),
    const Service(
      id: ServiceId('color'),
      salonId: SalonId('s'),
      name: 'Farbanje',
      priceRsd: 3000,
      durationMinutes: 90,
    ),
  ],
  barbers:
      barbers ??
      [
        Barber(
          id: const BarberId('b'),
          salonId: const SalonId('s'),
          name: 'Frizer',
          services: [const ServiceId('cut')],
        ),
      ],
  entries: entries,
);
void main() {
  test('Dodeljeno aktivno stanje zahteva frizera i izvan debug režima', () {
    expect(
      () =>
          entry('invalid', const ServiceId('cut'), status: QueueStatus.called),
      throwsArgumentError,
    );
    expect(
      () => entry(
        'invalid',
        const ServiceId('cut'),
        status: QueueStatus.inProgress,
      ),
      throwsArgumentError,
    );
  });
  test(
    'Bira najranijeg kompatibilnog; jednako vreme razrešava rednim brojem',
    () {
      final first = entry('first', const ServiceId('color'), sequence: 1);
      final second = entry('second', const ServiceId('cut'), sequence: 2);
      final third = entry('third', const ServiceId('cut'), sequence: 3);
      final result = assignAvailableBarbers(
        snapshot(entries: [third, first, second]),
      );
      expect(
        result.entries.singleWhere((e) => e.id == second.id).status,
        QueueStatus.called,
      );
      expect(
        result.entries.singleWhere((e) => e.id == first.id).status,
        QueueStatus.waiting,
      );
      expect(
        result.entries.singleWhere((e) => e.id == third.id).status,
        QueueStatus.waiting,
      );
    },
  );
  test('Pozvan klijent već zauzima frizera; ponovljena dodela je stabilna', () {
    final result = assignAvailableBarbers(
      snapshot(
        entries: [
          entry('a', const ServiceId('cut')),
          entry('b', const ServiceId('cut'), sequence: 2),
        ],
      ),
    );
    final again = assignAvailableBarbers(result);
    expect(
      again.entries.where((e) => e.status == QueueStatus.called).length,
      1,
    );
    expect(again.entries.first.revision, result.entries.first.revision);
  });
  test('Više frizera ne poziva istog klijenta', () {
    final result = assignAvailableBarbers(
      snapshot(
        entries: [entry('a', const ServiceId('cut'))],
        barbers: [
          for (final id in ['b2', 'b1'])
            Barber(
              id: BarberId(id),
              salonId: const SalonId('s'),
              name: id,
              services: [const ServiceId('cut')],
            ),
        ],
      ),
    );
    expect(result.entries.single.barberId, const BarberId('b1'));
  });
  test('Pauza i odsustvo sprečavaju novu dodelu', () {
    for (final availability in [
      BarberAvailability.paused,
      BarberAvailability.away,
    ]) {
      final result = assignAvailableBarbers(
        snapshot(
          entries: [entry('a', const ServiceId('cut'))],
          barbers: [
            Barber(
              id: const BarberId('b'),
              salonId: const SalonId('s'),
              name: 'B',
              services: [const ServiceId('cut')],
              availability: availability,
            ),
          ],
        ),
      );
      expect(result.entries.single.status, QueueStatus.waiting);
    }
  });
  test('Jedna aktivna prijava u salonu za sva tri aktivna stanja', () {
    for (final status in QueueStatus.values.where((s) => s.isActive)) {
      final result = validateJoinQueue(
        snapshot: snapshot(
          entries: [
            entry(
              'a',
              const ServiceId('cut'),
              status: status,
              barber: status.occupiesBarber ? const BarberId('b') : null,
              clientId: client.id,
            ),
          ],
        ),
        salonId: const SalonId('s'),
        serviceId: const ServiceId('cut'),
        actor: client,
        now: now,
      );
      expect((result as Failure<void>).error, isA<ActiveEntryAlreadyExists>());
    }
  });
  test('Radno vreme uključuje otvaranje i isključuje zatvaranje', () {
    Result<void> validate(DateTime time) => validateJoinQueue(
      snapshot: snapshot(),
      salonId: const SalonId('s'),
      serviceId: const ServiceId('cut'),
      actor: client,
      now: time,
    );
    expect(validate(DateTime(2026, 10, 31, 9)), isA<Success<void>>());
    expect(
      (validate(DateTime(2026, 10, 31, 20)) as Failure<void>).error,
      isA<SalonClosed>(),
    );
    expect(
      (validate(DateTime(2026, 11, 1, 12)) as Failure<void>).error,
      isA<SalonClosed>(),
    );
  });
  test('Nepostojeća usluga i preduga napomena imaju tipizovane greške', () {
    final result = validateJoinQueue(
      snapshot: snapshot(),
      salonId: const SalonId('s'),
      serviceId: const ServiceId('x'),
      actor: client,
      now: now,
    );
    expect((result as Failure<void>).error, isA<UnsupportedService>());
    expect(validateNote('a' * maxNoteLength), isA<Success<String>>());
    expect(
      (validateNote('a' * (maxNoteLength + 1)) as Failure<String>).error,
      isA<InvalidNote>(),
    );
  });
  test('Cela matrica prelaza i vlasništvo', () {
    const allowed = {
      QueueStatus.waiting: {QueueStatus.called, QueueStatus.cancelled},
      QueueStatus.called: {QueueStatus.inProgress, QueueStatus.noShow},
      QueueStatus.inProgress: {QueueStatus.completed},
    };
    for (final from in QueueStatus.values) {
      for (final to in QueueStatus.values) {
        expect(
          canTransition(from, to),
          allowed[from]?.contains(to) ?? false,
          reason: '$from → $to',
        );
      }
    }
    final own = entry('a', const ServiceId('cut'), clientId: client.id);
    expect(
      validateTransition(own, QueueStatus.cancelled, client),
      isA<Success<void>>(),
    );
    expect(
      (validateTransition(
        own,
        QueueStatus.called,
        staff,
      ) as Failure<void>).error,
      isA<InvalidTransition>(),
    );
    expect(
      (validateTransition(
        entry('other', const ServiceId('cut')),
        QueueStatus.cancelled,
        client,
      ) as Failure<void>).error,
      isA<Forbidden>(),
    );
  });
  test('Pozicija koristi sve klijente i kolekcije su nepromenljive', () {
    final a = entry('a', const ServiceId('color'));
    final b = entry('b', const ServiceId('cut'), sequence: 2);
    final data = snapshot(entries: [b, a]);
    expect(queuePosition(b, data.entries), 2);
    expect(() => data.entries.clear(), throwsUnsupportedError);
    expect(() => data.barbers.first.services.clear(), throwsUnsupportedError);
  });
}
