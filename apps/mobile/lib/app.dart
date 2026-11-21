import 'package:flutter/material.dart';
import 'package:domain/domain.dart';
import 'package:blocs/blocs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';

import 'dependencies.dart';
import 'router.dart';

class FrizerajMobile extends StatefulWidget {
  const FrizerajMobile({
    super.key,
    this.repository,
    this.actor,
    this.onSessionExpired,
    this.initialLocation,
    this.minimumSplashDuration = StartupGate.defaultMinimumDisplayDuration,
  });
  final QueueRepository? repository;
  final User? actor;
  final VoidCallback? onSessionExpired;
  final String? initialLocation;
  final Duration minimumSplashDuration;
  @override
  State<FrizerajMobile> createState() => _FrizerajMobileState();
}

class _FrizerajMobileState extends State<FrizerajMobile> {
  late final dependencies = MobileDependencies(
    repository: widget.repository,
    actor: widget.actor,
  );
  late final router = createMobileRouter(
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
            title: 'Frizeraj',
            theme: frizerajTheme(),
            routerConfig: router,
            builder: (context, child) => BlocConsumer<QueueBloc, QueueState>(
              listenWhen: (_, state) => state.error is SessionExpired,
              listener: (_, _) => widget.onSessionExpired?.call(),
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
