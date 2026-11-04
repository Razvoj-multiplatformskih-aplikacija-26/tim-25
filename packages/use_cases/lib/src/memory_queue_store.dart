import 'package:domain/domain.dart';

class MemoryQueueStore implements QueueRepository {
  MemoryQueueStore({
    required QueueSnapshot seed,
    required this.clock,
    this.latency = const Duration(milliseconds: 550),
  }) : _snapshot = seed;
  QueueSnapshot _snapshot;
  final Clock clock;
  final Duration latency;
  bool failNextRequest = false;
  bool emptyNextLoad = false;
  int _serial = 100;

  Future<bool> _delayAndFail() async {
    await Future<void>.delayed(latency);
    if (!failNextRequest) return false;
    failNextRequest = false;
    return true;
  }

  @override
  Future<Result<QueueSnapshot>> load() async {
    if (await _delayAndFail()) return const Failure(RepositoryUnavailable());
    if (emptyNextLoad) {
      emptyNextLoad = false;
      return Success(_snapshot.copyWith(entries: []));
    }
    return Success(_snapshot);
  }

  @override
  Future<Result<QueueSnapshot>> join({
    required User actor,
    required SalonId salonId,
    required ServiceId serviceId,
    required String note,
  }) async {
    if (await _delayAndFail()) return const Failure(RepositoryUnavailable());
    final now = clock();
    final validation = validateJoinQueue(
      snapshot: _snapshot,
      salonId: salonId,
      serviceId: serviceId,
      actor: actor,
      now: now,
      note: note,
    );
    if (validation case Failure<void>(:final error)) return Failure(error);
    final serial = ++_serial;
    final entry = QueueEntry(
      id: QueueEntryId('new-$serial'),
      salonId: salonId,
      clientId: actor.id,
      clientName: actor.name,
      serviceId: serviceId,
      joinedAt: now,
      sequence: serial,
      note: note.trim(),
    );
    _snapshot = assignAvailableBarbers(
      _snapshot.copyWith(entries: [..._snapshot.entries, entry]),
    );
    return Success(_snapshot);
  }

  @override
  Future<Result<QueueSnapshot>> transition({
    required User actor,
    required QueueEntryId entryId,
    required int expectedRevision,
    required QueueStatus target,
  }) async {
    if (await _delayAndFail()) return const Failure(RepositoryUnavailable());
    final index = _snapshot.entries.indexWhere((e) => e.id == entryId);
    if (index < 0) return const Failure(NotFound());
    final entry = _snapshot.entries[index];
    if (entry.revision != expectedRevision) return const Failure(Conflict());
    final validation = validateTransition(entry, target, actor);
    if (validation case Failure<void>(:final error)) return Failure(error);
    final entries = _snapshot.entries.toList();
    entries[index] = entry.transitioned(target);
    _snapshot = assignAvailableBarbers(_snapshot.copyWith(entries: entries));
    return Success(_snapshot);
  }

  @override
  Future<Result<QueueSnapshot>> setAvailability({
    required User actor,
    required BarberId barberId,
    required BarberAvailability availability,
  }) async {
    if (await _delayAndFail()) return const Failure(RepositoryUnavailable());
    if (actor.role != Role.staff) return const Failure(Forbidden());
    if (!_snapshot.barbers.any((b) => b.id == barberId)) {
      return const Failure(NotFound());
    }
    _snapshot = assignAvailableBarbers(
      _snapshot.copyWith(
        barbers: _snapshot.barbers.map(
          (b) => b.id == barberId ? b.withAvailability(availability) : b,
        ),
      ),
    );
    return Success(_snapshot);
  }
}
