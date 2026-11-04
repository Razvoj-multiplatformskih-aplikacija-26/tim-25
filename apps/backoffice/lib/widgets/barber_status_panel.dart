import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';

class BarberStatusPanel extends StatelessWidget {
  const BarberStatusPanel({
    super.key,
    required this.snapshot,
    required this.busy,
    required this.onAvailabilityChanged,
  });
  final QueueSnapshot snapshot;
  final bool busy;
  final void Function(BarberId id, BarberAvailability availability)
  onAvailabilityChanged;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      leading: const CircleAvatar(
        backgroundColor: FrizerajColors.navyTint,
        child: Icon(Icons.badge_outlined, color: FrizerajColors.navy, size: 21),
      ),
      title: Text(
        'Frizeri • ${snapshot.barbers.length}',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: const Text(
        'Dostupnost i trenutna zaduženja',
        style: TextStyle(fontSize: 12, color: FrizerajColors.muted),
      ),
      children: [
        SizedBox(
          height: 178,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 4, 2, 12),
            scrollDirection: Axis.horizontal,
            children: [
              for (final barber in snapshot.barbers)
                _BarberCard(
                  barber: barber,
                  snapshot: snapshot,
                  busy: busy,
                  onChanged: (value) => onAvailabilityChanged(barber.id, value),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BarberCard extends StatelessWidget {
  const _BarberCard({
    required this.barber,
    required this.snapshot,
    required this.busy,
    required this.onChanged,
  });
  final Barber barber;
  final QueueSnapshot snapshot;
  final bool busy;
  final ValueChanged<BarberAvailability> onChanged;

  @override
  Widget build(BuildContext context) {
    final occupied = snapshot.entries.any(
      (e) => e.barberId == barber.id && e.status.occupiesBarber,
    );
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FrizerajColors.neutral,
        border: Border.all(color: FrizerajColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: FrizerajColors.navyTint,
                child: Text(
                  barber.name.substring(0, 1),
                  style: const TextStyle(
                    fontSize: 13,
                    color: FrizerajColors.navy,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                barber.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Icon(
                occupied ? Icons.content_cut_rounded : Icons.circle,
                size: occupied ? 17 : 8,
                color: occupied ? FrizerajColors.navy : FrizerajColors.muted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            salonName(snapshot, barber.salonId),
            style: const TextStyle(fontSize: 11, color: FrizerajColors.muted),
          ),
          const SizedBox(height: 3),
          Text(
            occupied
                ? 'Klijent je pozvan / usluga u toku'
                : 'Bez trenutne dodele',
            style: const TextStyle(fontSize: 11, color: FrizerajColors.muted),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<BarberAvailability>(
              isExpanded: true,
              value: barber.availability,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: FrizerajColors.navy,
              ),
              items: [
                for (final value in BarberAvailability.values)
                  DropdownMenuItem(
                    value: value,
                    child: Text(availabilityLabel(value)),
                  ),
              ],
              onChanged: busy
                  ? null
                  : (value) {
                      if (value != null) onChanged(value);
                    },
            ),
          ),
        ],
      ),
    );
  }
}
