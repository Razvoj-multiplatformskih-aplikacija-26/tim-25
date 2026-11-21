import 'dart:io';

import 'package:frizeraj_server/src/auth/passwords.dart';
import 'package:frizeraj_server/src/auth/sessions.dart';
import 'package:frizeraj_server/src/data/bootstrap.dart';
import 'package:frizeraj_server/src/data/queue_store.dart';
import 'package:frizeraj_server/src/http/api.dart';
import 'package:frizeraj_server/src/integrations/notifications.dart';
import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> main(List<String> args) async {
  if (args.contains('--healthcheck')) {
    final http = HttpClient()..connectionTimeout = const Duration(seconds: 1);
    try {
      final request = await http.getUrl(
        Uri.parse('http://127.0.0.1:8080/health'),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 1),
      );
      exitCode = response.statusCode == HttpStatus.ok ? 0 : 1;
      await response.drain<void>();
    } catch (_) {
      exitCode = 1;
    } finally {
      http.close(force: true);
    }
    return;
  }

  final env = Platform.environment;
  String requiredEnv(String name) {
    final value = env[name];
    if (value == null || value.isEmpty) throw StateError('Nedostaje $name.');
    return value;
  }

  tz.initializeTimeZones();
  final ttl = int.parse(env['SESSION_SECONDS'] ?? '3600');
  if (ttl < 1 || ttl > 604800)
    throw StateError('SESSION_SECONDS mora biti od 1 do 604800.');
  final demoTime = env['DEMO_BUSINESS_TIME'];
  final fixedTime = demoTime == null || demoTime.isEmpty
      ? null
      : DateTime.parse(demoTime).toUtc();
  final pool = Pool.withEndpoints(
    [
      Endpoint(
        host: env['DB_HOST'] ?? 'localhost',
        port: int.parse(env['DB_PORT'] ?? '5432'),
        database: requiredEnv('POSTGRES_DB'),
        username: requiredEnv('POSTGRES_USER'),
        password: requiredEnv('POSTGRES_PASSWORD'),
      ),
    ],
    settings: const PoolSettings(
      sslMode: SslMode.disable,
      maxConnectionCount: 8,
      queryTimeout: Duration(seconds: 5),
      connectTimeout: Duration(seconds: 5),
    ),
  );
  try {
    await bootstrap(
      pool,
      requiredEnv('DEMO_PASSWORD'),
      Directory(env['SQL_DIR'] ?? 'sql'),
    );
    final sessions = Sessions(
      pool,
      Duration(seconds: ttl),
      await hashPassword(randomToken()),
    );
    final app = Api(
      QueueStore(
        pool,
        () => fixedTime ?? DateTime.now().toUtc(),
        DemoCallNotifications(),
      ),
      sessions,
      origin: env['WEB_ORIGIN'] ?? 'http://localhost:7357',
      devHttp: env['DEV_HTTP'] == 'true',
    ).routes();
    await app.serve(address: InternetAddress.anyIPv4);
    stdout.writeln('Frizeraj API je spreman na portu 8080.');
  } catch (_) {
    await pool.close();
    rethrow;
  }
}
