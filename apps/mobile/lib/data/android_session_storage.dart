import 'package:domain/domain.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class AndroidSessionStorage implements SessionStorage {
  AndroidSessionStorage(String namespace)
    : _key = 'frizeraj_session_$namespace';

  final String _key;
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
