import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';

import 'transport.dart';

final class RemoteQueueRepository implements QueueRepository {
  RemoteQueueRepository(this.transport);
  final RemoteTransport transport;

  @override
  Future<Result<QueueSnapshot>> load() => _loadPages().timeout(
    const Duration(seconds: 15),
    onTimeout: () => const Failure(RepositoryUnavailable()),
  );

  Future<Result<QueueSnapshot>> _loadPages() async {
    try {
      final entries = <EntryDto>[];
      final positions = <String, int>{};
      final cursors = <String>{};
      String? cursor;
      QueueDto? first;
      do {
        final response = await transport.request(
          'GET',
          queuePath,
          query: {if (cursor != null) 'cursor': cursor},
        );
        if (response case Failure(:final error)) return Failure(error);
        final page = QueueDto.fromJson((response as Success<Json>).value);
        first ??= page;
        entries.addAll(page.entries);
        positions.addAll(page.positions);
        cursor = page.nextCursor;
        if (cursor != null && !cursors.add(cursor))
          return const Failure(RepositoryUnavailable());
      } while (cursor != null);
      return Success(
        queueFromDto(first, allEntries: entries, allPositions: positions),
      );
    } catch (_) {
      return const Failure(RepositoryUnavailable());
    }
  }

  Future<Result<QueueSnapshot>> _change(
    String method,
    String path,
    Json body,
  ) async {
    final response = await transport.request(method, path, body: body);
    return switch (response) {
      Success() => load(),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<QueueSnapshot>> join({
    required User actor,
    required SalonId salonId,
    required ServiceId serviceId,
    required String note,
  }) => _change(
    'POST',
    entriesPath,
    JoinDto(
      salonId: salonId.value,
      serviceId: serviceId.value,
      note: note,
    ).toJson(),
  );

  @override
  Future<Result<QueueSnapshot>> transition({
    required User actor,
    required QueueEntryId entryId,
    required int expectedRevision,
    required QueueStatus target,
  }) => _change(
    'PATCH',
    '$entriesPath/${Uri.encodeComponent(entryId.value)}',
    TransitionDto(status: target.name, revision: expectedRevision).toJson(),
  );

  @override
  Future<Result<QueueSnapshot>> setAvailability({
    required User actor,
    required BarberId barberId,
    required BarberAvailability availability,
  }) => _change(
    'PATCH',
    '$barbersPath/${Uri.encodeComponent(barberId.value)}',
    AvailabilityDto(availability: availability.name).toJson(),
  );
}
