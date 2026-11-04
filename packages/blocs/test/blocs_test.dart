import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  test('Loading → greška → retry → data → empty', () async {
    final repo = MemoryQueueStore(
      seed: demoSeed(),
      clock: demoClock,
      latency: Duration.zero,
    )..failNextRequest = true;
    final bloc = QueueBloc(repository: repo, actor: demoClient);
    final states = <QueueState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(const LoadQueue());
    await bloc.stream.firstWhere((s) => s.phase == LoadPhase.failure);
    expect(bloc.state.error, isA<RepositoryUnavailable>());
    bloc.add(const LoadQueue());
    await bloc.stream.firstWhere((s) => s.phase == LoadPhase.data && !s.busy);
    expect(bloc.state.snapshot!.entries.length, 17);
    repo.emptyNextLoad = true;
    bloc.add(const LoadQueue());
    await bloc.stream.firstWhere(
      (s) => s.phase == LoadPhase.data && s.snapshot!.entries.isEmpty,
    );
    expect(states.any((s) => s.phase == LoadPhase.loading), isTrue);
    await sub.cancel();
    await bloc.close();
  });
  test(
    'Sekvencijalni događaji čuvaju izbor i sprečavaju star odgovor',
    () async {
      final repo = MemoryQueueStore(
        seed: demoSeed(),
        clock: demoClock,
        latency: Duration.zero,
      );
      final bloc = QueueBloc(repository: repo, actor: demoStaff);
      bloc
        ..add(const LoadQueue())
        ..add(const SelectEntry(QueueEntryId('other-0')))
        ..add(
          const ChangeAvailability(
            BarberId('cut-b0'),
            BarberAvailability.working,
          ),
        );
      await bloc.stream.firstWhere(
        (s) =>
            !s.busy &&
            s.snapshot!.barbers
                    .singleWhere((b) => b.id == const BarberId('cut-b0'))
                    .availability ==
                BarberAvailability.working,
      );
      expect(bloc.state.selectedId, const QueueEntryId('other-0'));
      final entry = bloc.state.snapshot!.entries.singleWhere(
        (e) => e.id == bloc.state.selectedId,
      );
      expect(entry.status, QueueStatus.called);
      bloc
        ..add(ChangeEntry(entry, QueueStatus.inProgress))
        ..add(ChangeEntry(entry, QueueStatus.noShow));
      await bloc.stream.firstWhere((s) => s.error is Conflict);
      expect(
        bloc.state.snapshot!.entries
            .singleWhere((e) => e.id == entry.id)
            .status,
        QueueStatus.inProgress,
      );
      await bloc.close();
    },
  );
  test('Equatable poredi vrednosti stanja', () {
    expect(const QueueState(), const QueueState());
    expect(const QueueState(busy: true), isNot(const QueueState()));
  });
}
