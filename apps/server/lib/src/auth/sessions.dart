import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' hide Result;

import '../data/database.dart';
import 'passwords.dart';

final class Sessions {
  Sessions(this.pool, this.ttl, this.dummyHash);
  final Pool pool;
  final Duration ttl;
  final String dummyHash;
  int _checking = 0;

  Future<Result<({String token, SessionDto session})>> login(
    LoginDto input,
    bool browser,
  ) async {
    if (input.username.length > 100 ||
        input.password.isEmpty ||
        input.password.length > 256) {
      return const Failure(InvalidCredentials());
    }
    if (_checking >= 4) return const Failure(RepositoryUnavailable());
    _checking++;
    try {
      final rows = await query(
        pool,
        '''
        SELECT id, name, role, password_hash FROM users WHERE username=@username
      ''',
        {'username': input.username.trim().toLowerCase()},
      );
      final row = rows.firstOrNull;
      final valid = await matchesPassword(
        input.password,
        row?['password_hash'] as String? ?? dummyHash,
      );
      if (!valid || row == null) return const Failure(InvalidCredentials());
      final user = _user(row);
      final role = Role.values.byName(input.role);
      if (!canUseApplication(user, role) || (browser && role != Role.staff)) {
        return const Failure(WrongApplication());
      }
      final token = randomToken();
      final expiry = DateTime.now().toUtc().add(ttl);
      await query(
        pool,
        '''
        INSERT INTO sessions (token_hash, user_id, expires_at, browser)
        VALUES (@hash, @user, @expires, @browser)
      ''',
        {
          'hash': await tokenHash(token),
          'user': user.id.value,
          'expires': expiry,
          'browser': browser,
        },
      );
      return Success((
        token: token,
        session: await _dto(user, expiry, token, browser),
      ));
    } finally {
      _checking--;
    }
  }

  Future<SessionDto?> find(String token, bool browser) async {
    if (!RegExp(r'^[A-Za-z0-9_-]{43}=$').hasMatch(token)) return null;
    final rows = await query(
      pool,
      '''
      SELECT u.id, u.name, u.role, s.expires_at FROM sessions s
      JOIN users u ON u.id=s.user_id
      WHERE s.token_hash=@hash AND s.browser=@browser AND s.expires_at > CURRENT_TIMESTAMP
    ''',
      {'hash': await tokenHash(token), 'browser': browser},
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return _dto(_user(row), row['expires_at'] as DateTime, token, browser);
  }

  Future<void> revoke(String token) async {
    await query(pool, 'DELETE FROM sessions WHERE token_hash=@hash', {
      'hash': await tokenHash(token),
    });
  }

  static User _user(Map<String, Object?> row) => userFromDto(
    UserDto(
      id: row['id'] as String,
      name: row['name'] as String,
      role: row['role'] as String,
    ),
  );

  static Future<SessionDto> _dto(
    User user,
    DateTime expiry,
    String token,
    bool browser,
  ) async => SessionDto(
    user: userToDto(user),
    expiresAt: expiry.toUtc().toIso8601String(),
    token: browser ? null : token,
    csrf: browser ? await tokenHash('csrf:$token') : null,
  );
}
