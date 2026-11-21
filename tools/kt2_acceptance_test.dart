import 'dart:convert';
import 'dart:io';

import 'package:api_client/api_client.dart';
import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';
import 'package:http/http.dart' as http;

final class MemoryToken implements SessionStorage {
  String? token;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async => token = value;
  @override
  Future<void> clear() async => token = null;
}

void main() {
  test('Serverov limit ostaje vidljiv u starom klijentu', () {
    final error = errorFromDto(
      const ErrorDto(code: 'invalid_note', details: {'maxLength': 60}),
    );
    expect(errorMessage(error), 'Napomena može imati najviše 60 znakova.');
    expect(
      errorFromDto(const ErrorDto(code: 'future_error', details: {})),
      isA<RepositoryUnavailable>(),
    );
  });

  final address = Platform.environment['FRIZERAJ_TEST_URL'];
  final offlineAddress = Platform.environment['FRIZERAJ_OFFLINE_URL'];
  test(
    'Ugašen server vraća čitljivu grešku u konačnom roku',
    skip: offlineAddress == null,
    () async {
      final transport = RemoteTransport(Uri.parse(offlineAddress!));
      addTearDown(transport.close);
      final elapsed = Stopwatch()..start();
      final result =
          await RemoteQueueRepository(transport).load()
              as Failure<QueueSnapshot>;
      expect(result.error, isA<RepositoryUnavailable>());
      expect(
        errorMessage(result.error),
        'Podaci trenutno nisu dostupni. Pokušaj ponovo.',
      );
      expect(elapsed.elapsed, lessThan(const Duration(seconds: 16)));
    },
  );
  final expiryAddress = Platform.environment['FRIZERAJ_EXPIRY_URL'];
  test(
    'Server odbija sesiju po isteku konfigurisanog TTL-a',
    skip: expiryAddress == null,
    () async {
      final transport = RemoteTransport(Uri.parse(expiryAddress!));
      addTearDown(transport.close);
      final storage = MemoryToken();
      final auth = RemoteAuthRepository(
        transport,
        Role.staff,
        storage: storage,
      );
      final login =
          await auth.login('osoblje', 'FrizerajDemo26') as Success<AuthSession>;
      expect(await transport.request('GET', sessionPath), isA<Success<Json>>());
      final untilExpiry = login.value.expiresAt.difference(
        DateTime.now().toUtc(),
      );
      expect(untilExpiry, lessThan(const Duration(seconds: 15)));
      await Future<void>.delayed(
        untilExpiry + const Duration(milliseconds: 300),
      );
      expect(
        await transport.request('GET', queuePath),
        isA<Failure<Json>>().having(
          (value) => value.error,
          'error',
          isA<SessionExpired>(),
        ),
      );
      expect(
        await auth.restore(),
        isA<Failure<AuthSession?>>().having(
          (value) => value.error,
          'error',
          isA<SessionExpired>(),
        ),
      );
      expect(storage.token, isNull);
    },
  );

  final newerAddress = Platform.environment['FRIZERAJ_COMPAT_URL'];
  test(
    'KT2 klijent sa limitom 120 primi novi serverski limit 60',
    skip: newerAddress == null,
    () async {
      final transport = RemoteTransport(Uri.parse(newerAddress!));
      addTearDown(transport.close);
      final auth = RemoteAuthRepository(
        transport,
        Role.client,
        storage: MemoryToken(),
      );
      final login =
          await auth.login('boris', 'FrizerajDemo26') as Success<AuthSession>;
      final note = 'x' * 80;
      expect(validateNote(note), isA<Success<String>>());
      final result = await RemoteQueueRepository(transport).join(
        actor: login.value.user,
        salonId: const SalonId('s3'),
        serviceId: const ServiceId('cut3'),
        note: note,
      ) as Failure<QueueSnapshot>;
      expect(
        errorMessage(result.error),
        'Napomena može imati najviše 60 znakova.',
      );
    },
  );
  test(
    'KT2 HTTP i stvarne PostgreSQL transakcije',
    skip: address == null,
    () async {
      final root = Uri.parse(address!);
      final password =
          Platform.environment['FRIZERAJ_TEST_PASSWORD'] ?? 'FrizerajDemo26';
      final staff = RemoteTransport(root);
      final boris = RemoteTransport(root);
      final secondBoris = RemoteTransport(root);
      final filip = RemoteTransport(root);
      for (final transport in [staff, boris, secondBoris, filip]) {
        addTearDown(transport.close);
      }
      final tokenStore = MemoryToken();
      final auth = RemoteAuthRepository(
        boris,
        Role.client,
        storage: tokenStore,
      );
      expect(await auth.login('boris', password), isA<Success<AuthSession>>());
      expect(
        await RemoteAuthRepository(
          secondBoris,
          Role.client,
          storage: MemoryToken(),
        ).login('boris', password),
        isA<Success<AuthSession>>(),
      );
      expect(
        await RemoteAuthRepository(
          filip,
          Role.client,
          storage: MemoryToken(),
        ).login('filip', password),
        isA<Success<AuthSession>>(),
      );
      final staffAuth = RemoteAuthRepository(
        staff,
        Role.staff,
        storage: MemoryToken(),
      );
      expect(
        await staffAuth.login('boris', password),
        isA<Failure<AuthSession>>().having(
          (value) => value.error,
          'error',
          isA<WrongApplication>(),
        ),
      );
      expect(
        await staffAuth.login('osoblje', password),
        isA<Success<AuthSession>>(),
      );

      final staffRepo = RemoteQueueRepository(staff);
      final mobileRepo = RemoteQueueRepository(boris);
      final seed = (await staffRepo.load() as Success<QueueSnapshot>).value;
      expect(seed.entries.length, greaterThanOrEqualTo(17));
      expect(
        seed.entries.map((e) => e.status).toSet(),
        QueueStatus.values.toSet(),
      );
      final private = (await mobileRepo.load() as Success<QueueSnapshot>).value;
      expect(private.entries.every((e) => e.clientId.value == 'boris'), isTrue);
      expect(private.waitingCounts![const SalonId('s0')], 6);
      expect(private.positions![const QueueEntryId('active-0')], 1);
      final firstPage = (await staff.request(
        'GET',
        queuePath,
        query: {'limit': '2'},
      ) as Success<Json>).value;
      final next = QueueDto.fromJson(firstPage).nextCursor;
      expect(next, isNotNull);
      final nextPage = (await staff.request(
        'GET',
        queuePath,
        query: {'limit': '2', 'cursor': next!},
      ) as Success<Json>).value;
      expect(
        QueueDto.fromJson(firstPage).entries
            .map((e) => e.id)
            .toSet()
            .intersection(
              QueueDto.fromJson(nextPage).entries.map((e) => e.id).toSet(),
            ),
        isEmpty,
      );

      for (final action in ['inProgress', 'completed']) {
        expect(
          await boris.request(
            'PATCH',
            '$entriesPath/active-1',
            body: {'status': action, 'revision': 0, 'actor': 'staff'},
          ),
          isA<Failure<Json>>().having(
            (value) => value.error,
            'error',
            isA<Forbidden>(),
          ),
        );
      }
      expect(
        await filip.request('GET', '$entriesPath/active-0'),
        isA<Failure<Json>>().having(
          (value) => value.error,
          'error',
          isA<NotFound>(),
        ),
      );
      expect(
        await filip.request(
          'PATCH',
          '$entriesPath/active-0',
          body: {'status': 'cancelled', 'revision': 0},
        ),
        isA<Failure<Json>>().having(
          (value) => value.error,
          'error',
          isA<Forbidden>(),
        ),
      );

      final invalid = await boris.request(
        'POST',
        entriesPath,
        body: {'salonId': 's3', 'serviceId': 'cut3', 'note': 'x' * 121},
      );
      expect(
        invalid,
        isA<Failure<Json>>().having(
          (value) => value.error,
          'error',
          isA<InvalidNote>().having((value) => value.maxLength, 'limit', 120),
        ),
      );
      final writes = await Future.wait([
        for (final transport in [boris, secondBoris, filip])
          transport.request(
            'POST',
            entriesPath,
            body: {'salonId': 's3', 'serviceId': 'cut3', 'note': ''},
          ),
      ]);
      expect(writes.whereType<Success<Json>>(), hasLength(2));
      expect(
        writes.whereType<Failure<Json>>().single.error,
        isA<ActiveEntryAlreadyExists>(),
      );
      final updated = (await staffRepo.load() as Success<QueueSnapshot>).value;
      final atSalon = updated.entries.where(
        (entry) => entry.salonId.value == 's3' && entry.status.isActive,
      );
      expect(atSalon, hasLength(2));
      expect(
        atSalon.where((entry) => entry.status == QueueStatus.called),
        hasLength(1),
      );
      expect(
        atSalon.where((entry) => entry.status == QueueStatus.waiting),
        hasLength(1),
      );

      final concurrent = await Future.wait(
        List.generate(
          2,
          (_) => staff.request(
            'PATCH',
            '$entriesPath/active-1',
            body: {'status': 'inProgress', 'revision': 0},
          ),
        ),
      );
      expect(concurrent.whereType<Success<Json>>(), hasLength(1));
      expect(
        concurrent.whereType<Failure<Json>>().single.error,
        isA<Conflict>(),
      );
      expect(
        await staff.request(
          'PATCH',
          '$entriesPath/active-1',
          body: {'status': 'completed', 'revision': 1},
        ),
        isA<Success<Json>>(),
      );
      final refreshed =
          (await mobileRepo.load() as Success<QueueSnapshot>).value;
      expect(
        refreshed.entries
            .singleWhere((entry) => entry.id.value == 'active-1')
            .status,
        QueueStatus.completed,
      );

      final restored = RemoteTransport(root);
      addTearDown(restored.close);
      final restoreAuth = RemoteAuthRepository(
        restored,
        Role.client,
        storage: tokenStore,
      );
      expect(
        await restoreAuth.restore(),
        isA<Success<AuthSession?>>().having(
          (value) => value.value?.user.id.value,
          'user',
          'boris',
        ),
      );
      expect(await restoreAuth.logout(), isA<Success<void>>());
      expect(tokenStore.token, isNull);
      expect(
        await boris.request('GET', queuePath),
        isA<Failure<Json>>().having(
          (value) => value.error,
          'error',
          isA<SessionExpired>(),
        ),
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'Browser cookie i zaštita promene reda',
    skip: address == null,
    () async {
      final root = Uri.parse(address!);
      final client = http.Client();
      addTearDown(client.close);
      const origin = 'http://localhost:7357';
      final cors = await client.send(
        http.Request('OPTIONS', root.resolve(loginPath))
          ..headers.addAll({
            'origin': origin,
            'access-control-request-method': 'POST',
          }),
      );
      expect(cors.statusCode, 204);
      expect(cors.headers['access-control-allow-origin'], origin);
      expect(cors.headers['access-control-allow-credentials'], 'true');
      await cors.stream.drain<void>();
      final login = await client.post(
        root.resolve(loginPath),
        headers: {'origin': origin, 'content-type': 'application/json'},
        body: jsonEncode({
          'username': 'osoblje',
          'password':
              Platform.environment['FRIZERAJ_TEST_PASSWORD'] ??
              'FrizerajDemo26',
          'role': 'staff',
        }),
      );
      expect(login.statusCode, 200);
      expect(login.headers['set-cookie'], contains('HttpOnly'));
      final session = SessionDto.fromJson(jsonObject(jsonDecode(login.body)));
      expect(session.token, isNull);
      final cookie = login.headers['set-cookie']!.split(';').first;
      final headers = {
        'origin': origin,
        'cookie': cookie,
        'content-type': 'application/json',
      };
      final restored = await client.get(
        root.resolve(sessionPath),
        headers: headers,
      );
      expect(restored.statusCode, 200);
      expect(
        (await client.post(
          root.resolve(logoutPath),
          headers: headers,
          body: '{}',
        )).statusCode,
        403,
      );
      headers['x-csrf-token'] = session.csrf!;
      final logout = await client.post(
        root.resolve(logoutPath),
        headers: headers,
        body: '{}',
      );
      expect(logout.statusCode, 200);
      expect(logout.headers['set-cookie'], contains('Max-Age=0'));
      expect(
        (await client.get(
          root.resolve(sessionPath),
          headers: headers,
        )).statusCode,
        401,
      );
    },
  );
}
