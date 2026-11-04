import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../formatters/queue_labels.dart';
import 'status_chip.dart';

class EntryInfo extends StatelessWidget {
  const EntryInfo({super.key, required this.entry, required this.snapshot});
  final QueueEntry entry;
  final QueueSnapshot snapshot;
  @override
  Widget build(BuildContext context) {
    final position = queuePosition(entry, snapshot.entries);
    final barber = snapshot.barbers
        .where((b) => b.id == entry.barberId)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DETALJI PRIJAVE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: FrizerajColors.muted,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          entry.clientName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        StatusChip(entry.status),
        const SizedBox(height: 22),
        _infoRow(Icons.storefront_outlined, salonName(snapshot, entry.salonId)),
        _infoRow(
          Icons.content_cut_rounded,
          serviceName(snapshot, entry.serviceId),
        ),
        _infoRow(
          Icons.schedule_rounded,
          'Prijava: ${dateLabel(entry.joinedAt)}',
        ),
        if (barber != null)
          _infoRow(Icons.person_outline_rounded, 'Frizer: ${barber.name}'),
        if (position != null)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FrizerajColors.navyTint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pozicija u redu: $position',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Redosled usluživanja zavisi i od veština slobodnih frizera.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: FrizerajColors.muted,
                  ),
                ),
              ],
            ),
          ),
        if (entry.note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text('Napomena: ${entry.note}'),
          ),
        const SizedBox(height: 16),
        Text(
          'ID: ${entry.id.value}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: FrizerajColors.muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
        ),
      ],
    ),
  );
}
