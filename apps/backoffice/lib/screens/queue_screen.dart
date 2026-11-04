import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';
import 'package:use_cases/use_cases.dart';

import '../shortcuts/queue_shortcuts.dart';
import '../widgets/queue_workspace.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key, this.initialId});
  final QueueEntryId? initialId;
  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final queueFocus = FocusNode(debugLabel: 'Pregled reda');
  bool focused = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialId != null) {
      context.read<QueueBloc>().add(SelectEntry(widget.initialId));
    }
  }

  @override
  void dispose() {
    queueFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<QueueBloc, QueueState>(
    builder: (context, state) {
      final bloc = context.read<QueueBloc>();
      void refresh() => bloc.add(const LoadQueue());
      return Scaffold(
        appBar: AppBar(
          leading: const Padding(
            padding: EdgeInsets.all(9),
            child: BrandMark(),
          ),
          title: const Text('Frizeraj • osoblje'),
          actions: [
            const Tooltip(
              message: '↑/↓ izbor · Enter otvori · Ctrl+R osveži\nCtrl+Enter započni/završi · Esc zatvori',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.keyboard_outlined,
                  color: FrizerajColors.muted,
                ),
              ),
            ),
            IconButton(
              onPressed: state.busy ? null : refresh,
              tooltip: 'Osveži (Ctrl+R)',
              icon: const Icon(Icons.refresh),
            ),
            PopupMenuButton<String>(
              tooltip: 'Demo kontrole',
              onSelected: (value) {
                final repo = context.read<QueueRepository>();
                if (repo is MemoryQueueStore) {
                  if (value == 'error') repo.failNextRequest = true;
                  if (value == 'empty') repo.emptyNextLoad = true;
                  refresh();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'error', child: Text('Simuliraj grešku')),
                PopupMenuItem(value: 'empty', child: Text('Prazan odgovor')),
              ],
            ),
          ],
        ),
        body: Focus(
          autofocus: true,
          focusNode: queueFocus,
          onKeyEvent: (_, event) => handleQueueShortcut(event, bloc: bloc),
          onFocusChange: (value) {
            if (mounted) setState(() => focused = value);
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: focused
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                const DemoBadge(staff: true),
                if (state.busy) const LinearProgressIndicator(),
                if (state.error != null && state.phase == LoadPhase.data)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(child: Text(errorMessage(state.error!))),
                        TextButton(
                          onPressed: refresh,
                          child: const Text('Osveži'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: state.phase == LoadPhase.loading
                      ? const Center(child: CircularProgressIndicator())
                      : state.phase == LoadPhase.failure
                      ? ErrorView(error: state.error!, onRetry: refresh)
                      : QueueWorkspace(state: state),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
