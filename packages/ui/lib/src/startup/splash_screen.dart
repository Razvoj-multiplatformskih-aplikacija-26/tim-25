import 'dart:math' as math;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import 'splash_background.dart';
import 'splash_branding.dart';
import 'splash_error_panel.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key,
    this.error,
    this.onRetry,
    this.exitProgress = 0,
    this.loadingKey,
  }) : assert(error == null || onRetry != null);
  final DomainError? error;
  final VoidCallback? onRetry;
  final double exitProgress;
  final GlobalKey? loadingKey;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: FrizerajColors.navy,
    ),
    child: Scaffold(
      backgroundColor: FrizerajColors.navy,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.biggest.isEmpty) {
            return const SizedBox.shrink();
          }
          final hasError = error != null;
          final brandHeightLimit =
              constraints.maxHeight * (hasError ? .4 : .65);
          final brandWidth = math.min(
            constraints.maxWidth * .66,
            math.min(
              320.0,
              math.max(0, hasError ? brandHeightLimit : brandHeightLimit - 52) /
                  .95,
            ),
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              SplashBackground(
                exitProgress: Curves.easeInOutCubic.transform(
                  (exitProgress / .43).clamp(0, 1),
                ),
              ),
              Align(
                alignment: Alignment(0, hasError ? -.45 : -.16),
                child: Opacity(
                  opacity:
                      1 -
                      Curves.easeIn.transform(
                        ((exitProgress - .48) / .45).clamp(0, 1),
                      ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SplashBranding(width: brandWidth),
                      if (!hasError) ...[
                        const SizedBox(height: 24),
                        SizedBox.square(
                          key: loadingKey,
                          dimension: 28,
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                            color: FrizerajColors.coral,
                            backgroundColor: Color(0x40faf9f6),
                            semanticsLabel: 'Učitavanje Frizeraja',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (hasError)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  child: SafeArea(
                    top: false,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight * .35,
                      ),
                      child: SplashErrorPanel(error: error!, onRetry: onRetry!),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}
