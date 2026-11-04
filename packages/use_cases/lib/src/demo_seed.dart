import 'package:domain/domain.dart';

const demoClient = User(
  id: ClientId('boris'),
  name: 'Boris Bošković',
  role: Role.client,
);
const demoStaff = User(
  id: ClientId('staff'),
  name: 'Osoblje',
  role: Role.staff,
);
DateTime demoClock() => DateTime(2026, 10, 31, 12);

QueueSnapshot demoSeed() {
  final salons = List.generate(
    4,
    (i) => Salon(
      id: SalonId('s$i'),
      name: [
        'Frizeraj Dorćol',
        'Studio Vračar',
        'Salon Zemun',
        'Frizeraj Novi Beograd',
      ][i],
      address: [
        'Cara Dušana 24',
        'Njegoševa 18',
        'Glavna 12',
        'Bulevar umetnosti 8',
      ][i],
      hours: OpeningHours(
        weekdays: [1, 2, 3, 4, 5, 6],
        opensAtMinute: 540,
        closesAtMinute: 1200,
      ),
    ),
  );
  final services = <Service>[];
  final barbers = <Barber>[];
  for (var i = 0; i < 4; i++) {
    services.addAll([
      Service(
        id: ServiceId('cut$i'),
        salonId: salons[i].id,
        name: 'Šišanje',
        priceRsd: 1400,
        durationMinutes: 30,
      ),
      Service(
        id: ServiceId('color$i'),
        salonId: salons[i].id,
        name: 'Farbanje',
        priceRsd: 3600,
        durationMinutes: 90,
      ),
    ]);
    barbers.addAll([
      Barber(
        id: BarberId('cut-b$i'),
        salonId: salons[i].id,
        name: ['Marko', 'Ana', 'Petar', 'Mina'][i],
        services: [ServiceId('cut$i')],
        availability: i == 0
            ? BarberAvailability.paused
            : BarberAvailability.working,
      ),
      Barber(
        id: BarberId('color-b$i'),
        salonId: salons[i].id,
        name: ['Jelena', 'Luka', 'Iva', 'Nikola'][i],
        services: [ServiceId('cut$i'), ServiceId('color$i')],
        availability: BarberAvailability.away,
      ),
    ]);
  }
  final entries = <QueueEntry>[];
  for (var i = 0; i < 9; i++) {
    entries.add(
      QueueEntry(
        id: QueueEntryId('history-$i'),
        salonId: salons[i % 4].id,
        clientId: demoClient.id,
        clientName: demoClient.name,
        serviceId: ServiceId('cut${i % 4}'),
        joinedAt: demoClock().subtract(Duration(days: i + 1)),
        sequence: i,
        status: [
          QueueStatus.completed,
          QueueStatus.cancelled,
          QueueStatus.noShow,
        ][i % 3],
        barberId: BarberId('cut-b${i % 4}'),
      ),
    );
  }
  for (var i = 0; i < 3; i++) {
    entries.add(
      QueueEntry(
        id: QueueEntryId('active-$i'),
        salonId: salons[i].id,
        clientId: demoClient.id,
        clientName: demoClient.name,
        serviceId: ServiceId(i == 0 ? 'color0' : 'cut$i'),
        joinedAt: demoClock().subtract(Duration(minutes: 30 - i)),
        sequence: 10 + i,
        status: [
          QueueStatus.waiting,
          QueueStatus.called,
          QueueStatus.inProgress,
        ][i],
        barberId: i == 0 ? null : BarberId('cut-b$i'),
      ),
    );
  }
  for (var i = 0; i < 5; i++) {
    entries.add(
      QueueEntry(
        id: QueueEntryId('other-$i'),
        salonId: salons[0].id,
        clientId: ClientId('other-$i'),
        clientName: ['Filip', 'Milica', 'Stefan', 'Jovana', 'Uroš'][i],
        serviceId: const ServiceId('cut0'),
        joinedAt: demoClock().subtract(Duration(minutes: 20 - i)),
        sequence: 20 + i,
      ),
    );
  }
  return QueueSnapshot(
    salons: salons,
    services: services,
    barbers: barbers,
    entries: entries,
  );
}
