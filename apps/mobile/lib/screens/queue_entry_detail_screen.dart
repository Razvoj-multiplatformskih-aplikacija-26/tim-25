import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';
import 'package:blocs/blocs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:use_cases/use_cases.dart';

import '../widgets/mobile_scaffold.dart';

class QueueEntryDetailScreen extends StatelessWidget {
  const QueueEntryDetailScreen({super.key, required this.entryId});
  final QueueEntryId entryId;
  @override
  Widget build(BuildContext context) => MobileScaffold(
    title: 'Detalj prijave',
    backPath: '/entries',
    selectedIndex: 1,
    contentBuilder: (context, state, snapshot) {
      final entry = snapshot.entries
          .where((e) => e.id == entryId && e.clientId == demoClient.id)
          .firstOrNull;
      if (entry == null) {
        return const Center(child: Text('Prijava nije pronađena.'));
      }
      return Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: EntryInfo(entry: entry, snapshot: snapshot),
                  ),
                ),
              ],
            ),
          ),
          if (validateTransition(entry, QueueStatus.cancelled, demoClient)
              is Success<void>)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: state.busy
                      ? null
                      : () async {
                          if (await confirmAction(context, 'Otkaži prijavu?') &&
                              context.mounted) {
                            context.read<QueueBloc>().add(
                              ChangeEntry(entry, QueueStatus.cancelled),
                            );
                          }
                        },
                  child: const Text('Otkaži prijavu'),
                ),
              ),
            ),
        ],
      );
    },
  );
}
