import 'package:domain/domain.dart';

List<QueueEntry> queueEntriesForDisplay(QueueSnapshot snapshot) =>
    snapshot.entries.toList()..sort((a, b) {
      if (a.status.isActive != b.status.isActive) {
        return a.status.isActive ? -1 : 1;
      }
      return compareQueueEntries(a, b);
    });

QueueStatus? primaryActionForEntry(QueueEntry entry, User actor) {
  for (final target in [QueueStatus.inProgress, QueueStatus.completed]) {
    if (validateTransition(entry, target, actor) is Success<void>) {
      return target;
    }
  }
  return null;
}
