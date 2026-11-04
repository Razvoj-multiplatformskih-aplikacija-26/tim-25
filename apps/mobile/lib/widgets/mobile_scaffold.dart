import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';
import 'package:blocs/blocs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:use_cases/use_cases.dart';

import 'mobile_navigation.dart';

class MobileScaffold extends StatelessWidget {
  const MobileScaffold({
    super.key,
    required this.title,
    required this.contentBuilder,
    this.backPath,
    this.selectedIndex = 0,
    this.showActionError = true,
    this.showAppBar = true,
    this.showDemoBadge = true,
  });
  final String title;
  final String? backPath;
  final int selectedIndex;
  final bool showActionError;
  final bool showAppBar;
  final bool showDemoBadge;
  final Widget Function(
    BuildContext context,
    QueueState state,
    QueueSnapshot snapshot,
  )
  contentBuilder;
  @override
  Widget build(BuildContext context) => BlocBuilder<QueueBloc, QueueState>(
    builder: (context, state) {
      final bloc = context.read<QueueBloc>();
      void refresh() => bloc.add(const LoadQueue());
      Widget body;
      if (state.phase == LoadPhase.loading) {
        body = const Center(child: CircularProgressIndicator());
      } else if (state.phase == LoadPhase.failure) {
        body = ErrorView(error: state.error!, onRetry: refresh);
      } else {
        final snapshot = state.snapshot!;
        body = contentBuilder(context, state, snapshot);
      }
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          appBar: !showAppBar
              ? null
              : AppBar(
                  leading: backPath == null
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: BrandMark(),
                        )
                      : IconButton(
                          tooltip: 'Nazad',
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context.go(backPath!),
                        ),
                  title: Row(
                    children: [
                      if (backPath != null) ...[
                        const BrandMark(size: 30),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      onPressed: state.busy ? null : refresh,
                      tooltip: 'Osveži',
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
                        PopupMenuItem(
                          value: 'error',
                          child: Text('Simuliraj grešku'),
                        ),
                        PopupMenuItem(
                          value: 'empty',
                          child: Text('Prazan odgovor'),
                        ),
                      ],
                    ),
                  ],
                ),
          body: SafeArea(
            top: !showAppBar,
            bottom: false,
            child: Column(
              children: [
                if (showDemoBadge) const DemoBadge(),
                if (state.busy && state.phase != LoadPhase.loading)
                  const LinearProgressIndicator(),
                if (state.error != null &&
                    state.phase == LoadPhase.data &&
                    showActionError)
                  Padding(
                    padding: const EdgeInsets.all(12),
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
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: body,
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: MobileNavigation(selectedIndex: selectedIndex),
        ),
      );
    },
  );
}
