import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';

class EntryDetailPanel extends StatelessWidget {
  const EntryDetailPanel({
    super.key,
    required this.entry,
    required this.snapshot,
    required this.actor,
    required this.busy,
    required this.onClose,
    required this.onTransition,
  });
  final QueueEntry entry;
  final QueueSnapshot snapshot;
  final User actor;
  final bool busy;
  final VoidCallback onClose;
  final ValueChanged<QueueStatus> onTransition;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          tooltip: 'Zatvori detalje (Esc)',
          onPressed: onClose,
          icon: const Icon(Icons.close),
        ),
      ),
      EntryInfo(entry: entry, snapshot: snapshot),
      const SizedBox(height: 20),
      for (final target in [
        QueueStatus.inProgress,
        QueueStatus.completed,
        QueueStatus.noShow,
        QueueStatus.cancelled,
      ])
        if (validateTransition(entry, target, actor) is Success<void>)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if ((target == QueueStatus.noShow ||
                              target == QueueStatus.cancelled) &&
                          !await confirmAction(
                            context,
                            '${statusLabel(target)}?',
                          )) {
                        return;
                      }
                      if (context.mounted) onTransition(target);
                    },
              child: Text(switch (target) {
                QueueStatus.inProgress => 'Započni uslugu (Ctrl+Enter)',
                QueueStatus.completed => 'Završi uslugu (Ctrl+Enter)',
                QueueStatus.noShow => 'Evidentiraj nedolazak',
                _ => 'Otkaži prijavu',
              }),
            ),
          ),
    ],
  );
}

class NoEntrySelected extends StatelessWidget {
  const NoEntrySelected({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: FrizerajColors.navyTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.touch_app_outlined,
              size: 32,
              color: FrizerajColors.navy,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Pogledaj izbliza',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Izaberi prijavu za detalje.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FrizerajColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Text(
            '↑ ↓  za izbor · Enter za otvaranje',
            style: TextStyle(color: FrizerajColors.muted, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}
