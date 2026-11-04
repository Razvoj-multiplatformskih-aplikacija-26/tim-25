import 'package:flutter/material.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';
import 'package:blocs/blocs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:use_cases/use_cases.dart';

import '../widgets/mobile_scaffold.dart';

class MyEntriesScreen extends StatelessWidget {
  const MyEntriesScreen({super.key});

  @override
  Widget build(BuildContext context) => MobileScaffold(
    title: 'Moje prijave',
    selectedIndex: 1,
    contentBuilder: (context, state, snapshot) {
      final entries =
          snapshot.entries.where((e) => e.clientId == demoClient.id).toList()
            ..sort((a, b) => b.joinedAt.compareTo(a.joinedAt));
      if (entries.isEmpty) {
        return EmptyView(
          onRefresh: () => context.read<QueueBloc>().add(const LoadQueue()),
        );
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeading('Tvoje posete', caption: '${entries.length} prijava'),
          for (final entry in entries)
            QueueEntryCard(
              entry: entry,
              snapshot: snapshot,
              onTap: () => context.go('/entries/${entry.id.value}'),
            ),
        ],
      );
    },
  );
}
