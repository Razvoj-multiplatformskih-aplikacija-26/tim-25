import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

String randomToken([int length = 32]) {
  final random = Random.secure();
  return base64Url.encode(List.generate(length, (_) => random.nextInt(256)));
}

Future<String> tokenHash(String token) async =>
    base64Url.encode((await Sha256().hash(utf8.encode(token))).bytes);

Future<List<int>> _derive(String password, String salt) =>
    Isolate.run(() async {
      final key =
          await Pbkdf2(
            macAlgorithm: Hmac.sha256(),
            iterations: 600000,
            bits: 256,
          ).deriveKey(
            secretKey: SecretKey(utf8.encode(password)),
            nonce: base64Url.decode(salt),
          );
      return key.extractBytes();
    });

Future<String> hashPassword(String password) async {
  final salt = randomToken(16);
  final hash = base64Url.encode(await _derive(password, salt));
  return 'pbkdf2-sha256:600000:$salt:$hash';
}

Future<bool> matchesPassword(String password, String encoded) async {
  final parts = encoded.split(':');
  if (parts.length != 4 ||
      parts[0] != 'pbkdf2-sha256' ||
      parts[1] != '600000') {
    return false;
  }
  final expected = base64Url.decode(parts[3]);
  final actual = await _derive(password, parts[2]);
  if (expected.length != actual.length) return false;
  var difference = 0;
  for (var index = 0; index < actual.length; index++) {
    difference |= expected[index] ^ actual[index];
  }
  return difference == 0;
}
