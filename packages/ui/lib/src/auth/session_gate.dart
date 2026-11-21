import 'package:api_client/api_client.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_theme.dart';
import 'sign_in_screen.dart';

final class SessionGate extends StatefulWidget {
  const SessionGate({
    super.key,
    required this.role,
    required this.title,
    required this.content,
    this.defaultApiUrl = 'http://localhost:8080',
    this.storage,
  });
  final Role role;
  final String title;
  final String defaultApiUrl;
  final SessionStorage Function(String namespace)? storage;
  final Widget Function(User, QueueRepository, VoidCallback) content;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

final class _SessionGateState extends State<SessionGate> {
  late final _transport = RemoteTransport(_apiUrl());
  late final _repo = RemoteQueueRepository(_transport);
  late final _auth = AuthBloc(
    RemoteAuthRepository(
      _transport,
      widget.role,
      storage: kIsWeb
          ? null
          : widget.storage?.call(
              '${widget.role.name}_${_transport.baseUrl.origin}',
            ),
    ),
  );

  Uri _apiUrl() {
    const configured = String.fromEnvironment('API_BASE_URL');
    return Uri.parse(configured.isEmpty ? widget.defaultApiUrl : configured);
  }

  @override
  void dispose() {
    _transport.close();
    _auth.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    bloc: _auth,
    builder: (context, state) {
      final session = state.session;
      if (session == null) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: widget.title,
          theme: frizerajTheme(),
          home: SignInScreen(
            title: widget.title,
            role: widget.role,
            state: state,
            onLogin: (username, password) =>
                _auth.add(SignIn(username, password)),
            onRetry: () => _auth.add(const RestoreSession()),
          ),
        );
      }
      return SessionActions(
        key: ObjectKey(session),
        onLogout: state.busy ? null : () => _auth.add(const SignOut()),
        error: state.error,
        child: widget.content(
          session.user,
          _repo,
          () => _auth.add(ExpireSession(session)),
        ),
      );
    },
  );
}

final class SessionActions extends InheritedWidget {
  const SessionActions({
    super.key,
    required this.onLogout,
    required this.error,
    required super.child,
  });
  final VoidCallback? onLogout;
  final DomainError? error;

  static SessionActions? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionActions>();

  @override
  bool updateShouldNotify(SessionActions oldWidget) =>
      onLogout != oldWidget.onLogout || error != oldWidget.error;
}
