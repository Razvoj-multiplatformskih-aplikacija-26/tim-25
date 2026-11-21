import 'models.dart';
import 'result.dart';

final class AuthSession {
  const AuthSession({required this.user, required this.expiresAt});
  final User user;
  final DateTime expiresAt;
}

abstract interface class AuthRepository {
  Future<Result<AuthSession?>> restore();
  Future<Result<AuthSession>> login(String username, String password);
  Future<Result<void>> logout();
  Future<void> forget();
}

abstract interface class SessionStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}
