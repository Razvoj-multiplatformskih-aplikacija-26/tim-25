import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

UserDto userToDto(User value) =>
    UserDto(id: value.id.value, name: value.name, role: value.role.name);

User userFromDto(UserDto value) => User(
  id: ClientId(value.id),
  name: value.name,
  role: Role.values.byName(value.role),
);

SalonDto salonToDto(Salon value) => SalonDto(
  id: value.id.value,
  name: value.name,
  address: value.address,
  weekdays: value.hours.weekdays.toList(),
  opensAtMinute: value.hours.opensAtMinute,
  closesAtMinute: value.hours.closesAtMinute,
);

Salon salonFromDto(SalonDto value) => Salon(
  id: SalonId(value.id),
  name: value.name,
  address: value.address,
  hours: OpeningHours(
    weekdays: value.weekdays,
    opensAtMinute: value.opensAtMinute,
    closesAtMinute: value.closesAtMinute,
  ),
);

ServiceDto serviceToDto(Service value) => ServiceDto(
  id: value.id.value,
  salonId: value.salonId.value,
  name: value.name,
  priceRsd: value.priceRsd,
  durationMinutes: value.durationMinutes,
);

Service serviceFromDto(ServiceDto value) => Service(
  id: ServiceId(value.id),
  salonId: SalonId(value.salonId),
  name: value.name,
  priceRsd: value.priceRsd,
  durationMinutes: value.durationMinutes,
);

BarberDto barberToDto(Barber value) => BarberDto(
  id: value.id.value,
  salonId: value.salonId.value,
  name: value.name,
  services: value.services.map((id) => id.value).toList(),
  availability: value.availability.name,
);

Barber barberFromDto(BarberDto value) => Barber(
  id: BarberId(value.id),
  salonId: SalonId(value.salonId),
  name: value.name,
  services: value.services.map(ServiceId.new),
  availability: BarberAvailability.values.byName(value.availability),
);

EntryDto entryToDto(QueueEntry value) => EntryDto(
  id: value.id.value,
  salonId: value.salonId.value,
  clientId: value.clientId.value,
  clientName: value.clientName,
  serviceId: value.serviceId.value,
  joinedAt: value.joinedAt.toUtc().toIso8601String(),
  sequence: value.sequence,
  status: value.status.name,
  barberId: value.barberId?.value,
  note: value.note,
  revision: value.revision,
);

QueueEntry entryFromDto(EntryDto value) => QueueEntry(
  id: QueueEntryId(value.id),
  salonId: SalonId(value.salonId),
  clientId: ClientId(value.clientId),
  clientName: value.clientName,
  serviceId: ServiceId(value.serviceId),
  joinedAt: DateTime.parse(value.joinedAt),
  sequence: value.sequence,
  status: QueueStatus.values.byName(value.status),
  barberId: value.barberId == null ? null : BarberId(value.barberId!),
  note: value.note,
  revision: value.revision,
);

QueueSnapshot queueFromDto(
  QueueDto value, {
  Iterable<EntryDto>? allEntries,
  Map<String, int>? allPositions,
}) => QueueSnapshot(
  salons: value.salons.map(salonFromDto),
  services: value.services.map(serviceFromDto),
  barbers: value.barbers.map(barberFromDto),
  entries: (allEntries ?? value.entries).map(entryFromDto),
  positions: (allPositions ?? value.positions).map(
    (id, position) => MapEntry(QueueEntryId(id), position),
  ),
  waitingCounts: value.waitingCounts.map(
    (id, count) => MapEntry(SalonId(id), count),
  ),
  businessTime: value.businessTime == null
      ? null
      : DateTime.parse(value.businessTime!),
);

QueueDto queueToDto(QueueSnapshot value, {String? nextCursor}) => QueueDto(
  salons: value.salons.map(salonToDto).toList(),
  services: value.services.map(serviceToDto).toList(),
  barbers: value.barbers.map(barberToDto).toList(),
  entries: value.entries.map(entryToDto).toList(),
  positions:
      value.positions?.map((id, position) => MapEntry(id.value, position)) ??
      {},
  waitingCounts:
      value.waitingCounts?.map((id, count) => MapEntry(id.value, count)) ?? {},
  nextCursor: nextCursor,
  businessTime: value.businessTime?.toIso8601String(),
);

ErrorDto errorToDto(DomainError error) {
  final (code, details) = switch (error) {
    SalonClosed() => ('salon_closed', const <String, Object?>{}),
    ActiveEntryAlreadyExists() => (
      'active_entry_exists',
      const <String, Object?>{},
    ),
    UnsupportedService() => ('unsupported_service', const <String, Object?>{}),
    InvalidTransition() => ('invalid_transition', const <String, Object?>{}),
    Forbidden() => ('forbidden', const <String, Object?>{}),
    NotFound() => ('not_found', const <String, Object?>{}),
    Conflict() => ('conflict', const <String, Object?>{}),
    InvalidNote(:final maxLength) => (
      'invalid_note',
      <String, Object?>{'maxLength': maxLength},
    ),
    RepositoryUnavailable() => ('unavailable', const <String, Object?>{}),
    SessionExpired() => ('session_expired', const <String, Object?>{}),
    InvalidCredentials() => ('invalid_credentials', const <String, Object?>{}),
    WrongApplication() => ('wrong_application', const <String, Object?>{}),
    InvalidRequest() => ('invalid_request', const <String, Object?>{}),
  };
  return ErrorDto(code: code, details: details);
}

DomainError errorFromDto(ErrorDto value) => switch (value.code) {
  'salon_closed' => const SalonClosed(),
  'active_entry_exists' => const ActiveEntryAlreadyExists(),
  'unsupported_service' => const UnsupportedService(),
  'invalid_transition' => const InvalidTransition(),
  'forbidden' => const Forbidden(),
  'not_found' => const NotFound(),
  'conflict' => const Conflict(),
  'invalid_note' => InvalidNote(switch (value.details['maxLength']) {
    final int limit when limit > 0 => limit,
    _ => maxNoteLength,
  }),
  'session_expired' => const SessionExpired(),
  'invalid_credentials' => const InvalidCredentials(),
  'wrong_application' => const WrongApplication(),
  'invalid_request' => const InvalidRequest(),
  _ => const RepositoryUnavailable(),
};
