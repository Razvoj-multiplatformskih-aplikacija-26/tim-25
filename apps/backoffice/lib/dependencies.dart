import 'package:domain/domain.dart';
import 'package:blocs/blocs.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_queue_repository.dart';

final class BackofficeDependencies {
  BackofficeDependencies({QueueRepository? repository})
    : repository = repository ?? FakeQueueRepository() {
    queueBloc = QueueBloc(repository: this.repository, actor: demoStaff)
      ..add(const LoadQueue());
  }
  final QueueRepository repository;
  late final QueueBloc queueBloc;
  Future<void> dispose() => queueBloc.close();
}
