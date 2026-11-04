import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import 'splash_screen.dart';
import 'splash_reveal_clipper.dart';

class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    required this.ready,
    required this.child,
    required this.onRetry,
    this.error,
    this.minimumDisplayDuration = defaultMinimumDisplayDuration,
  });
  static const defaultMinimumDisplayDuration = Duration(milliseconds: 1600);
  final bool ready;
  final DomainError? error;
  final VoidCallback onRetry;
  final Widget child;
  final Duration minimumDisplayDuration;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate>
    with SingleTickerProviderStateMixin {
  late bool _introComplete = widget.minimumDisplayDuration == Duration.zero;
  late bool _opened = widget.ready && _introComplete;
  Timer? _introTimer;
  final _loadingKey = GlobalKey();
  final _surfaceKey = GlobalKey();
  bool _revealing = false;
  Offset _revealCenter = Offset.zero;
  late final _exit =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2100),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _opened = true);
        }
      });

  void _tryOpen() {
    if (_opened || _revealing || !widget.ready || !_introComplete) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _opened = true);
      return;
    }
    final loader = _loadingKey.currentContext?.findRenderObject() as RenderBox?;
    final surface =
        _surfaceKey.currentContext?.findRenderObject() as RenderBox?;
    if (loader == null ||
        surface == null ||
        !loader.hasSize ||
        !surface.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tryOpen();
      });
      return;
    }
    _revealCenter = surface.globalToLocal(
      loader.localToGlobal(loader.size.center(Offset.zero)),
    );
    setState(() => _revealing = true);
    _exit.forward();
  }

  @override
  void initState() {
    super.initState();
    if (_introComplete) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _introTimer = Timer(widget.minimumDisplayDuration, () {
        if (!mounted) return;
        setState(() {
          _introComplete = true;
        });
        _tryOpen();
      });
    });
  }

  @override
  void didUpdateWidget(covariant StartupGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ready && _introComplete && !_opened && !_revealing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tryOpen();
      });
    }
  }

  @override
  void dispose() {
    _introTimer?.cancel();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _exit,
    builder: (context, _) => Stack(
      key: _surfaceKey,
      fit: StackFit.expand,
      children: [
        if (!_opened)
          SplashScreen(
            error: widget.error,
            onRetry: widget.onRetry,
            loadingKey: _loadingKey,
            exitProgress: _exit.value,
          ),
        if (_revealing || _opened)
          Positioned.fill(
            key: const ValueKey('application-content'),
            child: IgnorePointer(
              ignoring: !_opened,
              child: ExcludeSemantics(
                excluding: !_opened,
                child: ClipPath(
                  clipper: _opened
                      ? null
                      : SplashRevealClipper(
                          center: _revealCenter,
                          progress: Curves.easeInOutCubic.transform(
                            ((_exit.value - .48) / .52).clamp(0, 1),
                          ),
                        ),
                  child: widget.child,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
