sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final DomainError error;
}

sealed class DomainError {
  const DomainError();
}

final class SalonClosed extends DomainError {
  const SalonClosed();
}

final class ActiveEntryAlreadyExists extends DomainError {
  const ActiveEntryAlreadyExists();
}

final class UnsupportedService extends DomainError {
  const UnsupportedService();
}

final class InvalidTransition extends DomainError {
  const InvalidTransition();
}

final class Forbidden extends DomainError {
  const Forbidden();
}

final class NotFound extends DomainError {
  const NotFound();
}

final class Conflict extends DomainError {
  const Conflict();
}

final class InvalidNote extends DomainError {
  const InvalidNote();
}

final class RepositoryUnavailable extends DomainError {
  const RepositoryUnavailable();
}
