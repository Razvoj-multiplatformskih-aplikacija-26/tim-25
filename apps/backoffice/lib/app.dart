import 'package:flutter/material.dart';
import 'package:domain/domain.dart';
import 'package:blocs/blocs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';

import 'dependencies.dart';
import 'router.dart';

class FrizerajBackoffice extends StatefulWidget {
  const FrizerajBackoffice({
    super.key,
    this.repository,
    this.initialLocation,
    this.minimumSplashDuration = StartupGate.defaultMinimumDisplayDuration,
  });
  final QueueRepository? repository;
  final String? initialLocation;
  final Duration minimumSplashDuration;
  @override
  State<FrizerajBackoffice> createState() => _FrizerajBackofficeState();
}

class _FrizerajBackofficeState extends State<FrizerajBackoffice> {
  late final dependencies = BackofficeDependencies(
    repository: widget.repository,
  );
  late final router = createBackofficeRouter(
    initialLocation: widget.initialLocation,
  );
  @override
  void dispose() {
    router.dispose();
    dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RepositoryProvider<QueueRepository>.value(
        value: dependencies.repository,
        child: BlocProvider.value(
          value: dependencies.queueBloc,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Frizeraj • osoblje',
            theme: frizerajTheme(),
            routerConfig: router,
            builder: (context, child) => BlocBuilder<QueueBloc, QueueState>(
              builder: (context, state) => StartupGate(
                minimumDisplayDuration: widget.minimumSplashDuration,
                ready: state.phase == LoadPhase.data,
                error: state.phase == LoadPhase.failure ? state.error : null,
                onRetry: () => context.read<QueueBloc>().add(const LoadQueue()),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
}
