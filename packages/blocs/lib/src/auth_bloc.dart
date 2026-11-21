import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';

sealed class AuthEvent {
  const AuthEvent();
}

final class RestoreSession extends AuthEvent {
  const RestoreSession();
}

final class SignIn extends AuthEvent {
  const SignIn(this.username, this.password);
  final String username;
  final String password;
}

final class SignOut extends AuthEvent {
  const SignOut();
}

final class ExpireSession extends AuthEvent {
  const ExpireSession(this.session);
  final AuthSession session;
}

final class AuthState {
  const AuthState({
    this.session,
    this.busy = false,
    this.error,
    this.restoreFailed = false,
  });
  final AuthSession? session;
  final bool busy;
  final DomainError? error;
  final bool restoreFailed;
}

final class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this.repository) : super(const AuthState(busy: true)) {
    on<AuthEvent>(
      _handle,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
    add(const RestoreSession());
  }
  final AuthRepository repository;
  Timer? _expiry;

  Future<void> _handle(AuthEvent event, Emitter<AuthState> emit) async {
    final current = state.session;
    try {
      switch (event) {
        case RestoreSession():
          if (current != null) return;
          emit(const AuthState(busy: true));
          switch (await repository.restore()) {
            case Success(:final value):
              _present(value, emit);
            case Failure(:final error):
              emit(
                AuthState(
                  error: error,
                  restoreFailed: error is! SessionExpired,
                ),
              );
          }
        case SignIn(:final username, :final password):
          if (current != null) return;
          emit(const AuthState(busy: true));
          switch (await repository.login(username, password)) {
            case Success(:final value):
              _present(value, emit);
            case Failure(:final error):
              emit(AuthState(error: error));
          }
        case SignOut():
          if (current == null) return;
          emit(AuthState(session: current, busy: true));
          switch (await repository.logout()) {
            case Success():
              _present(null, emit);
            case Failure(:final error):
              emit(AuthState(session: current, error: error));
          }
        case ExpireSession(:final session):
          if (!identical(session, current)) return;
          _expiry?.cancel();
          try {
            await repository.forget();
          } finally {
            emit(const AuthState(error: SessionExpired()));
          }
      }
    } catch (_) {
      if (event is! ExpireSession) {
        emit(AuthState(session: current, error: const RepositoryUnavailable()));
      }
    }
  }

  void _present(AuthSession? session, Emitter<AuthState> emit) {
    _expiry?.cancel();
    if (session != null) {
      _expiry = Timer(session.expiresAt.difference(DateTime.now()), () {
        if (!isClosed) add(ExpireSession(session));
      });
    }
    emit(AuthState(session: session));
  }

  @override
  Future<void> close() async {
    _expiry?.cancel();
    await super.close();
  }
}
