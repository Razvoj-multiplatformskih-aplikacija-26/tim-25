import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' hide Result;
import 'package:timezone/timezone.dart' as tz;

import '../auth/passwords.dart';
import '../integrations/notifications.dart';
import 'database.dart';

final class QueueStore {
  QueueStore(this.pool, this.clock, this.notifications);
  final Pool pool;
  final Clock clock;
  final CallNotifications notifications;

  DateTime get localTime =>
      tz.TZDateTime.from(clock(), tz.getLocation('Europe/Belgrade'));

  Future<QueueDto> read(User actor, int limit, int cursor) => pool.runTx((
    db,
  ) async {
    await db.execute(
      'SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY',
    );
    final snapshot = await _snapshot(db, includeEntries: false);
    final page = (await query(
      db,
      '''
      $_entrySelect
      WHERE e.sequence>@cursor AND (@staff OR e.client_id=@client)
      ORDER BY e.sequence LIMIT @limit
    ''',
      {
        'cursor': cursor,
        'staff': canReadAllEntries(actor),
        'client': actor.id.value,
        'limit': limit + 1,
      },
    )).map(_entry).toList();
    final entries = page.take(limit).toList();
    final waitingCounts = <SalonId, int>{};
    final positions = <QueueEntryId, int>{};
    final waiting = (await query(
      db,
      "$_entrySelect WHERE e.status='waiting'",
    )).map(_entry).toList()..sort(compareQueueEntries);
    for (final entry in waiting) {
      final id = entry.salonId;
      final position = (waitingCounts[id] ?? 0) + 1;
      waitingCounts[id] = position;
      positions[entry.id] = position;
    }
    final time = localTime;
    return queueToDto(
      QueueSnapshot(
        salons: snapshot.salons,
        services: snapshot.services,
        barbers: snapshot.barbers,
        entries: entries,
        positions: {
          for (final entry in entries)
            if (positions.containsKey(entry.id)) entry.id: positions[entry.id]!,
        },
        waitingCounts: waitingCounts,
        businessTime: DateTime(
          time.year,
          time.month,
          time.day,
          time.hour,
          time.minute,
          time.second,
        ),
      ),
      nextCursor: page.length > limit
          ? encodeCursor(entries.last.sequence)
          : null,
    );
  });

  static String encodeCursor(int sequence) =>
      base64Url.encode(utf8.encode('$sequence'));
  static int decodeCursor(String? value) =>
      value == null ? -1 : int.parse(utf8.decode(base64Url.decode(value)));

  Future<Result<QueueEntry>> detail(User actor, String id) async {
    final rows = await query(pool, '$_entrySelect WHERE e.id=@id', {'id': id});
    if (rows.isEmpty) return const Failure(NotFound());
    final entry = _entry(rows.single);
    return canReadEntry(actor, entry)
        ? Success(entry)
        : const Failure(NotFound());
  }

  Future<Result<void>> join(User actor, JoinDto input) =>
      _change(input.salonId, (db, snapshot) async {
        final now = localTime;
        final result = validateJoinQueue(
          snapshot: snapshot,
          salonId: SalonId(input.salonId),
          serviceId: ServiceId(input.serviceId),
          actor: actor,
          now: now,
          note: input.note,
        );
        if (result is Failure<void>) return result;
        await query(
          db,
          '''
        INSERT INTO queue_entries (id, salon_id, client_id, service_id, joined_at, status, note, revision)
        VALUES (@id, @salon, @client, @service, @time, 'waiting', @note, 0)
      ''',
          {
            'id': randomToken(18),
            'salon': input.salonId,
            'client': actor.id.value,
            'service': input.serviceId,
            'time': now.toUtc(),
            'note': input.note.trim(),
          },
        );
        return const Success(null);
      });

  Future<Result<void>> transition(
    User actor,
    String id,
    TransitionDto input,
  ) async {
    final target = QueueStatus.values.byName(input.status);
    final rows = await query(
      pool,
      'SELECT salon_id FROM queue_entries WHERE id=@id',
      {'id': id},
    );
    if (rows.isEmpty) return const Failure(NotFound());
    return _change(rows.single['salon_id'] as String, (db, snapshot) async {
      final entry = snapshot.entries
          .where((entry) => entry.id.value == id)
          .firstOrNull;
      if (entry == null) return const Failure(NotFound());
      final validation = validateTransition(entry, target, actor);
      if (validation is Failure<void> && validation.error is Forbidden)
        return validation;
      if (entry.revision != input.revision) return const Failure(Conflict());
      if (validation is Failure<void>) return validation;
      await _update(db, entry.transitioned(target));
      return const Success(null);
    });
  }

  Future<Result<void>> availability(
    User actor,
    String id,
    AvailabilityDto input,
  ) async {
    if (!canChangeAvailability(actor)) return const Failure(Forbidden());
    final value = BarberAvailability.values.byName(input.availability);
    final rows = await query(
      pool,
      'SELECT salon_id FROM barbers WHERE id=@id',
      {'id': id},
    );
    if (rows.isEmpty) return const Failure(NotFound());
    return _change(rows.single['salon_id'] as String, (db, snapshot) async {
      await query(db, 'UPDATE barbers SET availability=@value WHERE id=@id', {
        'value': value.name,
        'id': id,
      });
      return const Success(null);
    });
  }

  Future<Result<void>> _change(
    String salonId,
    Future<Result<void>> Function(Session, QueueSnapshot) operation,
  ) async {
    final called = <QueueEntry>[];
    final result = await pool.runTx(
      (db) async {
        final locked = await query(
          db,
          'SELECT id FROM salons WHERE id=@id FOR UPDATE',
          {'id': salonId},
        );
        if (locked.isEmpty) return const Failure<void>(NotFound());
        final previous = await _snapshot(db, salon: salonId);
        final result = await operation(db, previous);
        if (result is Failure<void>) return result;
        final current = await _snapshot(db, salon: salonId);
        final assigned = assignAvailableBarbers(current);
        for (var index = 0; index < assigned.entries.length; index++) {
          final entry = assigned.entries[index];
          if (entry.revision != current.entries[index].revision) {
            await _update(db, entry);
            called.add(entry);
          }
        }
        return result;
      },
      settings: TransactionSettings(
        isolationLevel: IsolationLevel.readCommitted,
      ),
    );
    for (final entry in called) {
      try {
        await notifications.called(entry).timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
    return result;
  }

  static const _entrySelect = '''
    SELECT e.*, u.name AS client_name FROM queue_entries e JOIN users u ON u.id=e.client_id
  ''';

  Future<QueueSnapshot> _snapshot(
    Session db, {
    String? salon,
    bool includeEntries = true,
  }) async {
    final parameters = <String, Object?>{if (salon != null) 'salon': salon};
    final bySalon = salon == null ? '' : ' WHERE salon_id=@salon';
    final salons = await query(
      db,
      'SELECT data FROM salons${salon == null ? '' : ' WHERE id=@salon'} ORDER BY id',
      parameters,
    );
    final services = await query(
      db,
      'SELECT data FROM services$bySalon ORDER BY id',
      parameters,
    );
    final barbers = await query(
      db,
      'SELECT data, availability FROM barbers$bySalon ORDER BY id',
      parameters,
    );
    final entries = includeEntries
        ? await query(
            db,
            '$_entrySelect${salon == null ? '' : ' WHERE e.salon_id=@salon'} ORDER BY e.sequence',
            parameters,
          )
        : const <Map<String, Object?>>[];
    return QueueSnapshot(
      salons: salons.map(
        (row) => salonFromDto(SalonDto.fromJson(jsonObject(row['data']))),
      ),
      services: services.map(
        (row) => serviceFromDto(ServiceDto.fromJson(jsonObject(row['data']))),
      ),
      barbers: barbers.map(
        (row) => barberFromDto(
          BarberDto.fromJson({
            ...jsonObject(row['data']),
            'availability': row['availability'],
          }),
        ),
      ),
      entries: entries.map(_entry),
    );
  }

  static QueueEntry _entry(Map<String, Object?> row) => QueueEntry(
    id: QueueEntryId(row['id'] as String),
    salonId: SalonId(row['salon_id'] as String),
    clientId: ClientId(row['client_id'] as String),
    clientName: row['client_name'] as String,
    serviceId: ServiceId(row['service_id'] as String),
    joinedAt: row['joined_at'] as DateTime,
    sequence: row['sequence'] as int,
    status: QueueStatus.values.byName(row['status'] as String),
    barberId: row['barber_id'] == null
        ? null
        : BarberId(row['barber_id'] as String),
    note: row['note'] as String,
    revision: row['revision'] as int,
  );

  Future<void> _update(Session db, QueueEntry entry) async {
    await query(
      db,
      'UPDATE queue_entries SET status=@status, revision=@revision, barber_id=@barber WHERE id=@id',
      {
        'status': entry.status.name,
        'revision': entry.revision,
        'barber': entry.barberId?.value,
        'id': entry.id.value,
      },
    );
  }
}
