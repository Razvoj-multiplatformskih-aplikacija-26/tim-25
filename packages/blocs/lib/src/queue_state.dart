import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

enum LoadPhase { loading, failure, data }

final class QueueState extends Equatable {
  const QueueState({
    this.phase = LoadPhase.loading,
    this.snapshot,
    this.error,
    this.busy = false,
    this.selectedId,
    this.joinedId,
  });
  final LoadPhase phase;
  final QueueSnapshot? snapshot;
  final DomainError? error;
  final bool busy;
  final QueueEntryId? selectedId;
  final QueueEntryId? joinedId;
  @override
  List<Object?> get props => [
    phase,
    snapshot,
    error,
    busy,
    selectedId,
    joinedId,
  ];
}
