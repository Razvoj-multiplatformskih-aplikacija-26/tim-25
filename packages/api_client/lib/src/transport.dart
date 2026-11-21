import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;

import 'transport_native.dart'
    if (dart.library.js_interop) 'transport_web.dart';

final class RemoteTransport {
  RemoteTransport(this.baseUrl, {http.Client? client})
    : _client = client ?? createClient();
  final Uri baseUrl;
  final http.Client _client;
  String? token;
  String? csrf;
  bool get usesCookies => browserTransport;
  String get _sessionMarker => 'frizeraj-session:${baseUrl.origin}';
  bool get hadSession => hadBrowserSession(_sessionMarker);
  void markSession(bool value) => markBrowserSession(_sessionMarker, value);

  void close() => _client.close();

  Future<Result<Json>> request(
    String method,
    String path, {
    Json? body,
    Map<String, String>? query,
  }) async {
    try {
      final url = baseUrl.resolve(path).replace(queryParameters: query);
      final request = http.Request(method, url);
      request.headers['accept'] = 'application/json';
      if (token case final value?)
        request.headers['authorization'] = 'Bearer $value';
      if (csrf case final value? when method != 'GET') {
        request.headers['x-csrf-token'] = value;
      }
      if (body != null) {
        request.headers['content-type'] = 'application/json; charset=utf-8';
        request.body = jsonEncode(body);
      }
      final response = await _send(request).timeout(const Duration(seconds: 8));
      if (response.statusCode == 401 && path != loginPath) {
        return const Failure(SessionExpired());
      }
      final json = jsonObject(jsonDecode(utf8.decode(response.bodyBytes)));
      return response.statusCode >= 200 && response.statusCode < 300
          ? Success(json)
          : Failure(errorFromDto(ErrorDto.fromJson(json)));
    } catch (_) {
      return const Failure(RepositoryUnavailable());
    }
  }

  Future<http.Response> _send(http.Request request) async =>
      http.Response.fromStream(await _client.send(request));
}
