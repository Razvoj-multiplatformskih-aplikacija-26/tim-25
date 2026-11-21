import 'package:domain/domain.dart';

abstract interface class CallNotifications {
  Future<void> called(QueueEntry entry);
}

final class DemoCallNotifications implements CallNotifications {
  @override
  Future<void> called(QueueEntry entry) async {}
}
