import 'identifiers.dart';
import 'models.dart';
import 'result.dart';

const maxNoteLength = 120;
Result<String> validateNote(String note) => note.trim().length > maxNoteLength
    ? const Failure(InvalidNote())
    : Success(note.trim());
Result<void> validateJoinQueue({
  required QueueSnapshot snapshot,
  required SalonId salonId,
  required ServiceId serviceId,
  required User actor,
  required DateTime now,
  String note = '',
}) {
  if (actor.role != Role.client) return const Failure(Forbidden());
  final salons = snapshot.salons.where((s) => s.id == salonId);
  if (salons.isEmpty) return const Failure(NotFound());
  if (!salons.first.hours.contains(now)) return const Failure(SalonClosed());
  if (!snapshot.services.any(
        (s) => s.id == serviceId && s.salonId == salonId,
      ) ||
      !snapshot.barbers.any(
        (b) => b.salonId == salonId && b.services.contains(serviceId),
      )) {
    return const Failure(UnsupportedService());
  }
  if (snapshot.entries.any(
    (e) => e.salonId == salonId && e.clientId == actor.id && e.status.isActive,
  )) {
    return const Failure(ActiveEntryAlreadyExists());
  }
  if (validateNote(note) case Failure<String>(:final error)) {
    return Failure(error);
  }
  return const Success(null);
}

bool canTransition(QueueStatus from, QueueStatus to) => switch ((from, to)) {
  (QueueStatus.waiting, QueueStatus.called || QueueStatus.cancelled) => true,
  (QueueStatus.called, QueueStatus.inProgress || QueueStatus.noShow) => true,
  (QueueStatus.inProgress, QueueStatus.completed) => true,
  _ => false,
};
Result<void> validateTransition(
  QueueEntry entry,
  QueueStatus target,
  User actor,
) {
  if (actor.role == Role.client &&
      (actor.id != entry.clientId || target != QueueStatus.cancelled)) {
    return const Failure(Forbidden());
  }
  if (target == QueueStatus.called || !canTransition(entry.status, target)) {
    return const Failure(InvalidTransition());
  }
  return const Success(null);
}

int compareQueueEntries(QueueEntry a, QueueEntry b) {
  final time = a.joinedAt.compareTo(b.joinedAt);
  if (time != 0) return time;
  final order = a.sequence.compareTo(b.sequence);
  return order != 0 ? order : a.id.value.compareTo(b.id.value);
}

QueueSnapshot assignAvailableBarbers(QueueSnapshot snapshot) {
  final entries = snapshot.entries.toList();
  final barbers = snapshot.barbers.toList()
    ..sort((a, b) => a.id.value.compareTo(b.id.value));
  for (final barber in barbers) {
    if (barber.availability != BarberAvailability.working ||
        entries.any(
          (e) => e.barberId == barber.id && e.status.occupiesBarber,
        )) {
      continue;
    }
    final compatible =
        entries
            .where(
              (e) =>
                  e.salonId == barber.salonId &&
                  e.status == QueueStatus.waiting &&
                  barber.services.contains(e.serviceId),
            )
            .toList()
          ..sort(compareQueueEntries);
    if (compatible.isEmpty) continue;
    final entry = compatible.first;
    entries[entries.indexOf(entry)] = entry.transitioned(
      QueueStatus.called,
      assignedBarber: barber.id,
    );
  }
  return snapshot.copyWith(entries: entries);
}

int? queuePosition(QueueEntry entry, Iterable<QueueEntry> entries) {
  if (entry.status != QueueStatus.waiting) return null;
  final waiting =
      entries
          .where(
            (e) =>
                e.salonId == entry.salonId && e.status == QueueStatus.waiting,
          )
          .toList()
        ..sort(compareQueueEntries);
  final index = waiting.indexWhere((e) => e.id == entry.id);
  return index < 0 ? null : index + 1;
}
