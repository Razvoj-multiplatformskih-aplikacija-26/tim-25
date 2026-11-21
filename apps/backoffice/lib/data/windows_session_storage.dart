import 'package:domain/domain.dart';
import 'package:flutter/services.dart';

final class WindowsSessionStorage implements SessionStorage {
  const WindowsSessionStorage(this.namespace);
  final String namespace;
  static const _channel = MethodChannel('frizeraj/session_storage');

  @override
  Future<String?> read() =>
      _channel.invokeMethod<String>('read', {'key': namespace});

  @override
  Future<void> write(String token) =>
      _channel.invokeMethod<void>('write', {'key': namespace, 'token': token});

  @override
  Future<void> clear() =>
      _channel.invokeMethod<void>('clear', {'key': namespace});
}
