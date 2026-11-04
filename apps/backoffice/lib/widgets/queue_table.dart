import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';

class QueueTable extends StatelessWidget {
  const QueueTable({
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('KLIJENT')),
              DataColumn(label: Text('USLUGA / SALON')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('PRIJAVA')),
            ],
            rows: [
              for (final entry in entries)
                DataRow(
                  selected: entry.id == selectedId,
                  onSelectChanged: (_) => onSelect(entry.id),
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: FrizerajColors.navyTint,
                            child: Text(
                              entry.clientName.substring(0, 1),
                              style: const TextStyle(
                                fontSize: 12,
                                color: FrizerajColors.navy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            entry.clientName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            serviceName(snapshot, entry.serviceId),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            salonName(snapshot, entry.salonId),
                            style: const TextStyle(
                              fontSize: 11,
                              color: FrizerajColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(StatusChip(entry.status)),
                    DataCell(
                      Text(
                        dateLabel(entry.joinedAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: FrizerajColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
