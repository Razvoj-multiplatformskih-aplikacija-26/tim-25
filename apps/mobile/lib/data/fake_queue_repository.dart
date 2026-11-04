import 'package:use_cases/use_cases.dart';

final class FakeQueueRepository extends MemoryQueueStore {
  FakeQueueRepository() : super(seed: demoSeed(), clock: demoClock);
}
