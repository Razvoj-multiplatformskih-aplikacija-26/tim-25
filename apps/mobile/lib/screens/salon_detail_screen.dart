import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';
import 'package:go_router/go_router.dart';

import '../widgets/mobile_scaffold.dart';

class SalonDetailScreen extends StatelessWidget {
  const SalonDetailScreen({super.key, required this.salonId});
  final SalonId salonId;
  @override
  Widget build(BuildContext context) => MobileScaffold(
    title: 'Frizeraj',
    backPath: '/',
    contentBuilder: (context, state, snapshot) {
      final salon = snapshot.salons.where((s) => s.id == salonId).firstOrNull;
      if (salon == null) {
        return const Center(child: Text('Salon nije pronađen.'));
      }
      final waiting =
          snapshot.entries
              .where((e) => e.salonId == salon.id && e.status.isActive)
              .toList()
            ..sort(compareQueueEntries);
      return Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: FrizerajColors.navy,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.storefront_outlined,
                        color: FrizerajColors.coral,
                        size: 30,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        salon.name,
                        style: Theme.of(context).textTheme.headlineMedium!
                            .copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        salon.address,
                        style: const TextStyle(
                          color: FrizerajColors.onNavyMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pon–sub · 09:00–20:00',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: FrizerajColors.cream,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                const SectionHeading('Usluge', caption: 'Cene u RSD'),
                for (final service in snapshot.services.where(
                  (s) => s.salonId == salon.id,
                ))
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.content_cut_outlined, size: 21),
                      title: Text(service.name),
                      subtitle: Text('Oko ${service.durationMinutes} min'),
                      trailing: Text(
                        '${service.priceRsd} RSD',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                const SizedBox(height: 28),
                SectionHeading(
                  'Trenutni red',
                  caption: '${waiting.length} aktivnih',
                ),
                if (waiting.isEmpty)
                  const Text('Trenutno nema aktivnih prijava.'),
                for (final entry in waiting)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Klijent • ${serviceName(snapshot, entry.serviceId)}',
                    ),
                    trailing: StatusChip(entry.status),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.go('/salons/${salonId.value}/join'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Prijavi se u red'),
              ),
            ),
          ),
        ],
      );
    },
  );
}
