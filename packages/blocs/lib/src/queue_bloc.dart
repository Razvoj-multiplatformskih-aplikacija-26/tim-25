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
        emit(
          QueueState(
            phase: loading ? LoadPhase.failure : LoadPhase.data,
            snapshot: previous,
            selectedId: selected,
            error: error,
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
              .first
              .id;
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
