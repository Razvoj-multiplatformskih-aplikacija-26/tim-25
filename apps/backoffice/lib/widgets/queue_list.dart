import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';

class QueueList extends StatelessWidget {
  const QueueList({
    super.key,
    required this.entries,
    required this.snapshot,
    required this.selectedId,
    required this.onSelect,
  });
  final List<QueueEntry> entries;
  final QueueSnapshot snapshot;
  final QueueEntryId? selectedId;
  final ValueChanged<QueueEntryId> onSelect;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(4),
    itemCount: entries.length,
    itemBuilder: (context, index) {
      final entry = entries[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: entry.id == selectedId
              ? FrizerajColors.navyTint
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            selected: entry.id == selectedId,
            leading: CircleAvatar(
              backgroundColor: FrizerajColors.navyTint,
              child: Text(
                entry.clientName.substring(0, 1),
                style: const TextStyle(
                  fontSize: 14,
                  color: FrizerajColors.navy,
                ),
              ),
            ),
            title: Text(
              entry.clientName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${serviceName(snapshot, entry.serviceId)} · ${salonName(snapshot, entry.salonId)}',
              style: const TextStyle(fontSize: 11, color: FrizerajColors.muted),
            ),
            trailing: StatusChip(entry.status),
            onTap: () => onSelect(entry.id),
          ),
        ),
      );
    },
  );
}
