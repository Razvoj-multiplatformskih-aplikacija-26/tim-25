import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../formatters/queue_labels.dart';
import 'status_chip.dart';

class QueueEntryCard extends StatelessWidget {
  const QueueEntryCard({
    super.key,
    required this.entry,
    required this.snapshot,
    required this.onTap,
    this.selected = false,
  });
  final QueueEntry entry;
  final QueueSnapshot snapshot;
  final VoidCallback onTap;
  final bool selected;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    color: selected ? FrizerajColors.navyTint : null,
    child: ListTile(
      onTap: onTap,
      selected: selected,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: statusColor(entry.status).withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.content_cut_rounded,
          size: 21,
          color: statusColor(entry.status),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Text(
          serviceName(snapshot, entry.serviceId),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            salonName(snapshot, entry.salonId),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(entry.status),
              Text(
                dateLabel(entry.joinedAt),
                style: const TextStyle(
                  fontSize: 10,
                  color: FrizerajColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: FrizerajColors.muted,
      ),
    ),
  );
}
