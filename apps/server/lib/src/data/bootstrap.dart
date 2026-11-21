import 'dart:convert';
import 'dart:io';

import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:use_cases/use_cases.dart';

import '../auth/passwords.dart';
import 'database.dart';

Future<void> bootstrap(
  Pool pool,
  String demoPassword,
  Directory migrations,
) async {
  final scripts =
      migrations
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.sql'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  if (scripts.isEmpty) throw StateError('Nema SQL migracija.');
  await pool.runTx((db) async {
    await db.execute('SELECT pg_advisory_xact_lock(420025)');
    await db.execute(
      'CREATE TABLE IF NOT EXISTS schema_migrations (id text PRIMARY KEY)',
    );
    for (final script in scripts) {
      final id = script.uri.pathSegments.last;
      if ((await query(db, 'SELECT id FROM schema_migrations WHERE id=@id', {
        'id': id,
      })).isNotEmpty)
        continue;
      final sql = await script.readAsString();
      for (final statement
          in sql.split(';').where((part) => part.trim().isNotEmpty)) {
        await db.execute(statement, queryMode: QueryMode.simple);
      }
      await query(db, 'INSERT INTO schema_migrations VALUES (@id)', {'id': id});
    }
    if ((await query(db, 'SELECT id FROM schema_migrations WHERE id=@id', {
      'id': 'demo_seed_v1',
    })).isNotEmpty)
      return;
    await _seed(db, demoPassword);
    await query(db, 'INSERT INTO schema_migrations VALUES (@id)', {
      'id': 'demo_seed_v1',
    });
  });
}

Future<void> _seed(Session db, String demoPassword) async {
  final snapshot = demoSeed();
  final names = <String, String>{
    for (final entry in snapshot.entries)
      entry.clientId.value: entry.clientName,
    demoStaff.id.value: demoStaff.name,
  };
  const accounts = {'boris': 'boris', 'other-0': 'filip', 'staff': 'osoblje'};
  for (final user in names.entries) {
    final username = accounts[user.key];
    await query(
      db,
      '''
      INSERT INTO users (id, name, role, username, password_hash)
      VALUES (@id, @name, @role, @username, @hash)
    ''',
      {
        'id': user.key,
        'name': user.value,
        'role': user.key == demoStaff.id.value
            ? Role.staff.name
            : Role.client.name,
        'username': username,
        'hash': username == null ? null : await hashPassword(demoPassword),
      },
    );
  }
  for (final salon in snapshot.salons) {
    await query(db, 'INSERT INTO salons VALUES (@id, CAST(@data AS jsonb))', {
      'id': salon.id.value,
      'data': jsonEncode(salonToDto(salon).toJson()),
    });
  }
  for (final service in snapshot.services) {
    await query(
      db,
      'INSERT INTO services VALUES (@id, @salon, CAST(@data AS jsonb))',
      {
        'id': service.id.value,
        'salon': service.salonId.value,
        'data': jsonEncode(serviceToDto(service).toJson()),
      },
    );
  }
  for (final barber in snapshot.barbers) {
    await query(
      db,
      'INSERT INTO barbers VALUES (@id, @salon, CAST(@data AS jsonb), @availability)',
      {
        'id': barber.id.value,
        'salon': barber.salonId.value,
        'data': jsonEncode(barberToDto(barber).toJson()),
        'availability': barber.availability.name,
      },
    );
  }
  final belgrade = tz.getLocation('Europe/Belgrade');
  for (final entry in snapshot.entries) {
    final time = entry.joinedAt;
    await query(
      db,
      '''
      INSERT INTO queue_entries
        (id, salon_id, client_id, service_id, joined_at, sequence, status, barber_id, note, revision)
      VALUES (@id, @salon, @client, @service, @time, @sequence, @status, @barber, @note, @revision)
    ''',
      {
        'id': entry.id.value,
        'salon': entry.salonId.value,
        'client': entry.clientId.value,
        'service': entry.serviceId.value,
        'time': tz.TZDateTime(
          belgrade,
          time.year,
          time.month,
          time.day,
          time.hour,
          time.minute,
        ).toUtc(),
        'sequence': entry.sequence,
        'status': entry.status.name,
        'barber': entry.barberId?.value,
        'note': entry.note,
        'revision': entry.revision,
      },
    );
  }
}
