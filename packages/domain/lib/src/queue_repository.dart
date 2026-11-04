import 'identifiers.dart';
import 'models.dart';
import 'result.dart';

abstract interface class QueueRepository {
  Future<Result<QueueSnapshot>> load();
  Future<Result<QueueSnapshot>> join({
    required User actor,
    required SalonId salonId,
    required ServiceId serviceId,
    required String note,
  });
  Future<Result<QueueSnapshot>> transition({
    required User actor,
    required QueueEntryId entryId,
    required int expectedRevision,
    required QueueStatus target,
  });
  Future<Result<QueueSnapshot>> setAvailability({
    required User actor,
    required BarberId barberId,
    required BarberAvailability availability,
  });
}
