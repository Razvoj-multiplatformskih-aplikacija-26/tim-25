import 'package:domain/domain.dart';

sealed class QueueEvent {
  const QueueEvent();
}

final class LoadQueue extends QueueEvent {
  const LoadQueue();
}

final class SelectEntry extends QueueEvent {
  const SelectEntry(this.id);
  final QueueEntryId? id;
}

final class JoinQueue extends QueueEvent {
  const JoinQueue(this.salonId, this.serviceId, this.note);
  final SalonId salonId;
  final ServiceId serviceId;
  final String note;
}

final class ChangeEntry extends QueueEvent {
  const ChangeEntry(this.entry, this.target);
  final QueueEntry entry;
  final QueueStatus target;
}

final class ChangeAvailability extends QueueEvent {
  const ChangeAvailability(this.barberId, this.availability);
  final BarberId barberId;
  final BarberAvailability availability;
}
