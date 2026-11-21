import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';

import 'queue_event.dart';
import 'queue_state.dart';

final class QueueBloc extends Bloc<QueueEvent, QueueState> {
  QueueBloc({required this.repository, required this.actor})
    : super(const QueueState()) {
    on<QueueEvent>(
      _handle,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }
  final QueueRepository repository;
  final User actor;

  Future<void> _handle(QueueEvent event, Emitter<QueueState> emit) async {
    if (event is SelectEntry) {
      emit(
        QueueState(
          phase: state.phase,
          snapshot: state.snapshot,
          selectedId: event.id,
          error: state.error,
        ),
      );
      return;
    }
    final previous = state.snapshot;
    final selected = state.selectedId;
    final loading = event is LoadQueue;
    emit(
      QueueState(
        phase: loading ? LoadPhase.loading : state.phase,
        snapshot: previous,
        selectedId: selected,
        busy: true,
      ),
    );
    Result<QueueSnapshot> result;
    try {
      result = switch (event) {
        LoadQueue() => await repository.load(),
        JoinQueue(:final salonId, :final serviceId, :final note) =>
          await repository.join(
            actor: actor,
            salonId: salonId,
            serviceId: serviceId,
            note: note,
          ),
        ChangeEntry(:final entry, :final target) => await repository.transition(
          actor: actor,
          entryId: entry.id,
          expectedRevision: entry.revision,
          target: target,
        ),
        ChangeAvailability(:final barberId, :final availability) =>
          await repository.setAvailability(
            actor: actor,
            barberId: barberId,
            availability: availability,
          ),
        SelectEntry() => throw StateError('Selection handled above'),
      };
    } catch (_) {
      result = const Failure(RepositoryUnavailable());
    }
    switch (result) {
      case Failure(:final error):
        var updated = previous;
        var failure = error;
        if (!loading &&
            error is! RepositoryUnavailable &&
            error is! SessionExpired) {
          try {
            switch (await repository.load()) {
              case Success(:final value):
                updated = value;
              case Failure(error: SessionExpired()):
                failure = const SessionExpired();
              case Failure():
                break;
            }
          } catch (_) {}
        }
        emit(
          QueueState(
            phase: loading || updated == null
                ? LoadPhase.failure
                : LoadPhase.data,
            snapshot: updated,
            selectedId:
                updated?.entries.any((entry) => entry.id == selected) == true
                ? selected
                : null,
            error: failure,
          ),
        );
      case Success(:final value):
        QueueEntryId? joined;
        if (event is JoinQueue) {
          joined = value.entries
              .where(
                (e) =>
                    e.clientId == actor.id &&
                    e.salonId == event.salonId &&
                    e.status.isActive,
              )
              .firstOrNull
              ?.id;
        }
        emit(
          QueueState(
            phase: LoadPhase.data,
            snapshot: value,
            selectedId: selected,
            joinedId: joined,
          ),
        );
    }
  }
}
