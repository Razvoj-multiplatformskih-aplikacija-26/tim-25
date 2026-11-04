import 'package:flutter/material.dart';

import 'splash_wordmark.dart';

class SplashBranding extends StatelessWidget {
  const SplashBranding({super.key, required this.width});
  final double width;

  static const symbolAsset = 'assets/branding/splash_symbol.png';
  static const wordmarkAsset = SplashWordmark.asset;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Frizeraj',
    image: true,
    child: ExcludeSemantics(
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              symbolAsset,
              package: 'frizeraj_ui',
              width: width * .54,
              height: width * .54 * 966 / 912,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            SizedBox(height: width * .065),
            SplashWordmark(width: width),
          ],
        ),
      ),
    ),
  );
}
