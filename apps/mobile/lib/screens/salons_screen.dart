import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';
import 'package:go_router/go_router.dart';

import '../presentation/salon_discovery.dart';
import '../widgets/discovery_header.dart';
import '../widgets/discovery_salon_card.dart';
import '../widgets/mobile_scaffold.dart';

class SalonsScreen extends StatefulWidget {
  const SalonsScreen({super.key});

  @override
  State<SalonsScreen> createState() => _SalonsScreenState();
}

class _SalonsScreenState extends State<SalonsScreen> {
  final _search = TextEditingController();
  SalonSort _sort = SalonSort.nearest;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _showCity() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Izaberi grad', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const FrizerajIcon('location_header'),
              title: const Text('Beograd'),
              trailing: const FrizerajIcon('check_circle'),
              onTap: () => Navigator.pop(context),
            ),
            const Text('Trenutno su dostupni saloni u Beogradu.'),
          ],
        ),
      ),
    ),
  );

  void _showNotifications(QueueSnapshot snapshot) {
    final actor = context.read<QueueBloc>().actor;
    final entries = snapshot.entries
        .where(
          (entry) =>
              entry.clientId == actor.id &&
              (entry.status == QueueStatus.called ||
                  entry.status == QueueStatus.inProgress),
        )
        .toList();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tvoj red',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Nema novih obaveštenja.'),
                ),
              for (final entry in entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const FrizerajIcon('notification_bell_plain'),
                  title: Text(salonName(snapshot, entry.salonId)),
                  subtitle: Text(
                    entry.status == QueueStatus.called
                        ? 'Pozvan si — tvoj frizer je spreman.'
                        : 'Tvoja usluga je u toku.',
                  ),
                  trailing: const FrizerajIcon('chevron_right', size: 18),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/entries/${entry.id.value}');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MobileScaffold(
    title: 'Saloni',
    showAppBar: false,
    showDemoBadge: false,
    contentBuilder: (context, state, snapshot) {
      final salons = discoverSalons(snapshot, _search.text, _sort);
      final actor = context.read<QueueBloc>().actor;
      final hasNotification = snapshot.entries.any(
        (entry) =>
            entry.clientId == actor.id && entry.status == QueueStatus.called,
      );
      return RefreshIndicator(
        onRefresh: () async {
          final bloc = context.read<QueueBloc>();
          bloc.add(const LoadQueue());
          await bloc.stream.firstWhere(
            (state) => !state.busy && state.phase != LoadPhase.loading,
          );
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          children: [
            DiscoveryHeader(
              onCityTap: _showCity,
              onNotificationsTap: () => _showNotifications(snapshot),
              hasNotification: hasNotification,
              searchController: _search,
              onSearch: (_) => setState(() {}),
              sort: _sort,
              onSort: (value) => setState(() => _sort = value),
            ),
            const SizedBox(height: 22),
            if (salons.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  'Nema salona za ovu pretragu.',
                  textAlign: TextAlign.center,
                ),
              ),
            for (final (index, salon) in salons.indexed) ...[
              DiscoverySalonCard(
                salon: salon,
                snapshot: snapshot,
                onTap: () => context.go('/salons/${salon.id.value}'),
              ),
              if (index < salons.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 124),
                  child: Divider(
                    height: 1,
                    color: FrizerajColors.line.withValues(alpha: .8),
                  ),
                ),
            ],
          ],
        ),
      );
    },
  );
}
