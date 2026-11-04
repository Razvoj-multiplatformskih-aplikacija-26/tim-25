import 'identifiers.dart';

typedef Clock = DateTime Function();

enum QueueStatus {
  waiting,
  called,
  inProgress,
  completed,
  cancelled,
  noShow;

  bool get isActive => this == waiting || this == called || this == inProgress;
  bool get occupiesBarber => this == called || this == inProgress;
}

enum BarberAvailability { working, paused, away }

enum Role { client, staff }

final class User {
  const User({required this.id, required this.name, required this.role});
  final ClientId id;
  final String name;
  final Role role;
}

final class OpeningHours {
  OpeningHours({
    required Iterable<int> weekdays,
    required this.opensAtMinute,
    required this.closesAtMinute,
  }) : weekdays = Set.unmodifiable(weekdays);
  final Set<int> weekdays;
  final int opensAtMinute;
  final int closesAtMinute;
  bool contains(DateTime salonLocalTime) =>
      weekdays.contains(salonLocalTime.weekday) &&
      salonLocalTime.hour * 60 + salonLocalTime.minute >= opensAtMinute &&
      salonLocalTime.hour * 60 + salonLocalTime.minute < closesAtMinute;
}

final class Salon {
  const Salon({
    required this.id,
    required this.name,
    required this.address,
    required this.hours,
  });
  final SalonId id;
  final String name;
  final String address;
  final OpeningHours hours;
}

final class Service {
  const Service({
    required this.id,
    required this.salonId,
    required this.name,
    required this.priceRsd,
    required this.durationMinutes,
  });
  final ServiceId id;
  final SalonId salonId;
  final String name;
  final int priceRsd;
  final int durationMinutes;
}

final class Barber {
  Barber({
    required this.id,
    required this.salonId,
    required this.name,
    required Iterable<ServiceId> services,
    this.availability = BarberAvailability.working,
  }) : services = Set.unmodifiable(services);
  final BarberId id;
  final SalonId salonId;
  final String name;
  final Set<ServiceId> services;
  final BarberAvailability availability;
  Barber withAvailability(BarberAvailability value) => Barber(
    id: id,
    salonId: salonId,
    name: name,
    services: services,
    availability: value,
  );
}

final class QueueEntry {
  QueueEntry({
    required this.id,
    required this.salonId,
    required this.clientId,
    required this.clientName,
    required this.serviceId,
    required this.joinedAt,
    required this.sequence,
    this.status = QueueStatus.waiting,
    this.barberId,
    this.note = '',
    this.revision = 0,
  }) {
    if (status.occupiesBarber && barberId == null) {
      throw ArgumentError('Pozvan klijent i usluga u toku zahtevaju frizera.');
    }
  }
  final QueueEntryId id;
  final SalonId salonId;
  final ClientId clientId;
  final String clientName;
  final ServiceId serviceId;
  final DateTime joinedAt;
  final int sequence;
  final QueueStatus status;
  final BarberId? barberId;
  final String note;
  final int revision;
  QueueEntry transitioned(QueueStatus next, {BarberId? assignedBarber}) =>
      QueueEntry(
        id: id,
        salonId: salonId,
        clientId: clientId,
        clientName: clientName,
        serviceId: serviceId,
        joinedAt: joinedAt,
        sequence: sequence,
        status: next,
        barberId: assignedBarber ?? barberId,
        note: note,
        revision: revision + 1,
      );
}

final class QueueSnapshot {
  QueueSnapshot({
    required Iterable<Salon> salons,
    required Iterable<Service> services,
    required Iterable<Barber> barbers,
    required Iterable<QueueEntry> entries,
  }) : salons = List.unmodifiable(salons),
       services = List.unmodifiable(services),
       barbers = List.unmodifiable(barbers),
       entries = List.unmodifiable(entries);
  final List<Salon> salons;
  final List<Service> services;
  final List<Barber> barbers;
  final List<QueueEntry> entries;
  QueueSnapshot copyWith({
    Iterable<Barber>? barbers,
    Iterable<QueueEntry>? entries,
  }) => QueueSnapshot(
    salons: salons,
    services: services,
    barbers: barbers ?? this.barbers,
    entries: entries ?? this.entries,
  );
}
