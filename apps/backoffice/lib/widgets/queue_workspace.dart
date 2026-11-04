import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';

import '../presentation/queue_presentation.dart';
import 'barber_status_panel.dart';
import 'entry_detail_panel.dart';
import 'queue_list.dart';
import 'queue_overview.dart';
import 'queue_table.dart';

class QueueWorkspace extends StatelessWidget {
  const QueueWorkspace({super.key, required this.state});
  final QueueState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<QueueBloc>();
    final snapshot = state.snapshot!;
    final entries = queueEntriesForDisplay(snapshot);
    final selected = entries.where((e) => e.id == state.selectedId).firstOrNull;
    void select(QueueEntryId id) => bloc.add(SelectEntry(id));
    return LayoutBuilder(
      builder: (context, size) {
        final compact = size.maxHeight < 600;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 24,
            8,
            compact ? 14 : 24,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QueueOverview(
                entries: entries,
                compact: compact,
                width: size.maxWidth,
              ),
              BarberStatusPanel(
                snapshot: snapshot,
                busy: state.busy,
                onAvailabilityChanged: (id, availability) =>
                    bloc.add(ChangeAvailability(id, availability)),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 850;
                    final detail = selected == null
                        ? const NoEntrySelected()
                        : EntryDetailPanel(
                            entry: selected,
                            snapshot: snapshot,
                            actor: bloc.actor,
                            busy: state.busy,
                            onClose: () => bloc.add(const SelectEntry(null)),
                            onTransition: (target) =>
                                bloc.add(ChangeEntry(selected, target)),
                          );
                    final queue = entries.isEmpty
                        ? EmptyView(
                            onRefresh: () => bloc.add(const LoadQueue()),
                          )
                        : wide
                        ? QueueTable(
                            entries: entries,
                            snapshot: snapshot,
                            selectedId: state.selectedId,
                            onSelect: select,
                          )
                        : QueueList(
                            entries: entries,
                            snapshot: snapshot,
                            selectedId: state.selectedId,
                            onSelect: select,
                          );
                    final queuePanel = Card(
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                            child: SectionHeading(
                              'Sve prijave',
                              caption: '${entries.length} ukupno',
                            ),
                          ),
                          Expanded(child: queue),
                        ],
                      ),
                    );
                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: queuePanel),
                          const SizedBox(width: 18),
                          SizedBox(
                            width: 330,
                            child: Card(
                              margin: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              child: detail,
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Expanded(child: queuePanel),
                        if (selected != null) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: constraints.maxHeight * .52,
                            child: Card(
                              margin: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              child: detail,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
