import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../formatters/queue_labels.dart';

Color statusColor(QueueStatus status) => switch (status) {
  QueueStatus.waiting || QueueStatus.cancelled => FrizerajColors.muted,
  QueueStatus.called || QueueStatus.noShow => FrizerajColors.coral,
  QueueStatus.inProgress || QueueStatus.completed => FrizerajColors.navy,
};

IconData statusIcon(QueueStatus status) => switch (status) {
  QueueStatus.waiting => Icons.schedule_rounded,
  QueueStatus.called => Icons.notifications_active_outlined,
  QueueStatus.inProgress => Icons.content_cut_rounded,
  QueueStatus.completed => Icons.check_circle_outline_rounded,
  QueueStatus.cancelled => Icons.block_rounded,
  QueueStatus.noShow => Icons.person_off_outlined,
};

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final QueueStatus status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: statusColor(status).withValues(alpha: .09),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(statusIcon(status), size: 12, color: statusColor(status)),
        const SizedBox(width: 6),
        Text(
          statusLabel(status),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: status.isActive
                ? FrizerajColors.navy
                : FrizerajColors.charcoal,
          ),
        ),
      ],
    ),
  );
}
