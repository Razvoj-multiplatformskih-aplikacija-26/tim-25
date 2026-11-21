import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' show ServerException;
import 'package:relic/relic.dart' hide Result;

import '../auth/sessions.dart';
import '../data/queue_store.dart';

final class Api {
  Api(this.queue, this.sessions, {required this.origin, required this.devHttp});
  final QueueStore queue;
  final Sessions sessions;
  final String origin;
  final bool devHttp;
  static const _cookieName = 'frizeraj_session';

  RelicApp routes() {
    final app = RelicApp();
    app.get(
      '/health',
      _handle((request) async {
        await queue.pool.execute('SELECT 1');
        return _json(request, 200, {'ready': true});
      }),
    );
    app.post(loginPath, _handle(_login));
    app.get(
      sessionPath,
      _authenticated(
        (request, session, token) async =>
            _json(request, 200, session.toJson()),
      ),
    );
    app.post(
      logoutPath,
      _authenticated((request, session, token) async {
        await sessions.revoke(token);
        return _json(request, 200, {}, cookie: _cookie('', age: 0));
      }, clearExpired: true),
    );
    app.get(
      queuePath,
      _authenticated((request, session, token) async {
        final params = request.url.queryParameters;
        final limit = int.parse(params['limit'] ?? '50');
        if (limit < 1 || limit > 100) throw const FormatException();
        final dto = await queue.read(
          userFromDto(session.user),
          limit,
          QueueStore.decodeCursor(params['cursor']),
        );
        return _json(request, 200, dto.toJson());
      }),
    );
    app.get(
      '$entriesPath/:id',
      _authenticated((request, session, token) async {
        final result = await queue.detail(
          userFromDto(session.user),
          _id(request),
        );
        return switch (result) {
          Success(:final value) => _json(
            request,
            200,
            entryToDto(value).toJson(),
          ),
          Failure(:final error) => _error(request, error),
        };
      }),
    );
    app.post(
      entriesPath,
      _authenticated(
        (request, session, token) async => _mutation(
          request,
          await queue.join(
            userFromDto(session.user),
            JoinDto.fromJson(await _body(request)),
          ),
        ),
      ),
    );
    app.patch(
      '$entriesPath/:id',
      _authenticated(
        (request, session, token) async => _mutation(
          request,
          await queue.transition(
            userFromDto(session.user),
            _id(request),
            TransitionDto.fromJson(await _body(request)),
          ),
        ),
      ),
    );
    app.patch(
      '$barbersPath/:id',
      _authenticated(
        (request, session, token) async => _mutation(
          request,
          await queue.availability(
            userFromDto(session.user),
            _id(request),
            AvailabilityDto.fromJson(await _body(request)),
          ),
        ),
      ),
    );
    for (final path in [
      loginPath,
      sessionPath,
      logoutPath,
      queuePath,
      entriesPath,
      '$entriesPath/:id',
      '$barbersPath/:id',
    ]) {
      app.options(
        path,
        _handle((request) async => Response(204, headers: _headers(request))),
      );
    }
    return app;
  }

  Handler _handle(Future<Response> Function(Request) run) => (request) async {
    if (_header(request, 'origin') case final String value
        when value != origin) {
      return _error(request, const Forbidden());
    }
    try {
      return await run(request);
    } on FormatException {
      return _error(request, const InvalidRequest());
    } on TypeError {
      return _error(request, const InvalidRequest());
    } on ArgumentError {
      return _error(request, const InvalidRequest());
    } on ServerException catch (error) {
      if (error.constraintName == 'one_active_entry_per_salon') {
        return _error(request, const ActiveEntryAlreadyExists());
      }
      if (error.constraintName == 'one_active_entry_per_barber') {
        return _error(request, const Conflict());
      }
      stderr.writeln('Database request failed: ${error.code}');
      return _error(request, const RepositoryUnavailable());
    } catch (error) {
      stderr.writeln('Request failed: ${error.runtimeType}');
      return _error(request, const RepositoryUnavailable());
    }
  };

  Handler _authenticated(
    Future<Response> Function(Request, SessionDto, String) run, {
    bool clearExpired = false,
  }) => _handle((request) async {
    final bearer = _header(request, 'authorization');
    final browser = bearer == null;
    final token = browser
        ? _cookieToken(request)
        : (bearer.startsWith('Bearer ') ? bearer.substring(7) : '');
    if (token.isEmpty) return _error(request, const SessionExpired());
    final session = await sessions.find(token, browser);
    if (session == null) {
      return _error(
        request,
        const SessionExpired(),
        cookie: clearExpired ? _cookie('', age: 0) : null,
      );
    }
    if (browser &&
        request.method != Method.get &&
        (_header(request, 'origin') != origin ||
            _header(request, 'x-csrf-token') != session.csrf)) {
      return _error(request, const Forbidden());
    }
    return run(request, session, token);
  });

  Future<Response> _login(Request request) async {
    final browser = _header(request, 'origin') == origin;
    final input = LoginDto.fromJson(await _body(request));
    final result = await sessions.login(input, browser);
    return switch (result) {
      Success(:final value) => _json(
        request,
        200,
        value.session.toJson(),
        cookie: browser
            ? _cookie(value.token, age: sessions.ttl.inSeconds)
            : null,
      ),
      Failure(:final error) => _error(request, error),
    };
  }

  Future<Json> _body(Request request) async {
    if (!(_header(request, 'content-type') ?? '').startsWith(
      'application/json',
    )) {
      throw const FormatException();
    }
    return jsonObject(jsonDecode(await request.readAsString(maxLength: 16384)));
  }

  static String _id(Request request) => request.rawPathParameters[#id]!;
  static String? _header(Request request, String name) =>
      request.headers[name]?.firstOrNull;
  static String _cookieToken(Request request) {
    for (final value in request.headers['cookie'] ?? const <String>[]) {
      for (final part in value.split(';')) {
        final cookie = part.trim();
        if (cookie.startsWith('$_cookieName='))
          return cookie.substring(_cookieName.length + 1);
      }
    }
    return '';
  }

  String _cookie(String value, {required int age}) =>
      '$_cookieName=$value; Path=$apiPath; Max-Age=$age; HttpOnly; SameSite=Lax${devHttp ? '' : '; Secure'}';

  Headers _headers(Request request, {String? cookie}) => Headers.fromMap({
    'content-type': ['application/json; charset=utf-8'],
    'cache-control': ['no-store'],
    'vary': ['Origin'],
    if (cookie != null) 'set-cookie': [cookie],
    if (_header(request, 'origin') == origin) ...{
      'access-control-allow-origin': [origin],
      'access-control-allow-credentials': ['true'],
      'access-control-allow-headers': ['content-type, x-csrf-token'],
      'access-control-allow-methods': ['GET, POST, PATCH, OPTIONS'],
    },
  });

  Response _json(Request request, int status, Json body, {String? cookie}) =>
      Response(
        status,
        headers: _headers(request, cookie: cookie),
        body: Body.fromString(jsonEncode(body)),
      );

  Response _error(Request request, DomainError error, {String? cookie}) {
    final status = switch (error) {
      SessionExpired() || InvalidCredentials() => 401,
      Forbidden() || WrongApplication() => 403,
      NotFound() => 404,
      Conflict() || ActiveEntryAlreadyExists() => 409,
      RepositoryUnavailable() => 503,
      InvalidRequest() => 400,
      _ => 422,
    };
    return _json(request, status, errorToDto(error).toJson(), cookie: cookie);
  }

  Response _mutation(Request request, Result<void> result) => switch (result) {
    Success() => _json(request, 200, {}),
    Failure(:final error) => _error(request, error),
  };
}
