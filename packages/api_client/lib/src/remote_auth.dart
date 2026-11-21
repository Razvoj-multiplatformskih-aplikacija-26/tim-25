import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';

import 'transport.dart';

final class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this.transport, this.role, {this.storage});
  final RemoteTransport transport;
  final Role role;
  final SessionStorage? storage;

  @override
  Future<Result<AuthSession?>> restore() async {
    try {
      if (!transport.usesCookies) {
        transport.token = await storage?.read();
        if (transport.token == null) return const Success(null);
      }
      final result = await transport.request('GET', sessionPath);
      if (result case Failure(:final error)) {
        if (error is SessionExpired) {
          final hadSession = !transport.usesCookies || transport.hadSession;
          await forget();
          return hadSession
              ? const Failure(SessionExpired())
              : const Success(null);
        }
        return Failure(error);
      }
      final session = await _accept((result as Success<Json>).value);
      return switch (session) {
        Success(:final value) => Success(value),
        Failure(:final error) => Failure(error),
      };
    } catch (_) {
      return const Failure(RepositoryUnavailable());
    }
  }

  @override
  Future<Result<AuthSession>> login(String username, String password) async {
    final result = await transport.request(
      'POST',
      loginPath,
      body: LoginDto(
        username: username,
        password: password,
        role: role.name,
      ).toJson(),
    );
    return switch (result) {
      Success(:final value) => _accept(value),
      Failure(:final error) => Failure(error),
    };
  }

  Future<Result<AuthSession>> _accept(Json value) async {
    try {
      final dto = SessionDto.fromJson(value);
      final user = userFromDto(dto.user);
      if (!canUseApplication(user, role))
        return const Failure(WrongApplication());
      final expires = DateTime.parse(dto.expiresAt);
      if (!expires.isAfter(DateTime.now())) {
        await forget();
        return const Failure(SessionExpired());
      }
      transport.csrf = dto.csrf;
      if (transport.usesCookies) {
        transport.markSession(true);
      } else {
        final token = dto.token;
        if (token == null || storage == null)
          return const Failure(RepositoryUnavailable());
        transport.token = token;
        await storage!.write(token);
      }
      return Success(AuthSession(user: user, expiresAt: expires));
    } catch (_) {
      return const Failure(RepositoryUnavailable());
    }
  }

  @override
  Future<Result<void>> logout() async {
    final result = await transport.request('POST', logoutPath, body: const {});
    if (result case Failure(:final error) when error is! SessionExpired) {
      return Failure(error);
    }
    await forget();
    return const Success(null);
  }

  @override
  Future<void> forget() async {
    transport.token = null;
    transport.csrf = null;
    transport.markSession(false);
    await storage?.clear();
  }
}
