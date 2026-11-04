import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';

class QueueOverview extends StatelessWidget {
  const QueueOverview({
    super.key,
    required this.entries,
    required this.compact,
    required this.width,
  });
  final List<QueueEntry> entries;
  final bool compact;
  final double width;

  @override
  Widget build(BuildContext context) {
    final waiting = entries
        .where((e) => e.status == QueueStatus.waiting)
        .length;
    final called = entries.where((e) => e.status == QueueStatus.called).length;
    final inProgress = entries
        .where((e) => e.status == QueueStatus.inProgress)
        .length;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pregled reda',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Sve na jednom mestu. Za mirniji dan u salonu.',
                      style: TextStyle(
                        color: FrizerajColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: FrizerajColors.navyTint,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '${waiting + called + inProgress} aktivnih',
                style: const TextStyle(
                  color: FrizerajColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (!compact) ...[
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'Na čekanju',
                  value: '$waiting',
                  icon: Icons.people_outline_rounded,
                  dark: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  label: 'Pozvani',
                  value: '$called',
                  icon: Icons.notifications_active_outlined,
                ),
              ),
              if (width >= 500) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    label: 'U toku',
                    value: '$inProgress',
                    icon: Icons.content_cut_rounded,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}
