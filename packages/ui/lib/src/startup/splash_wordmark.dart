import 'package:flutter/material.dart';

class SplashWordmark extends StatelessWidget {
  const SplashWordmark({super.key, required this.width});
  final double width;

  static const asset = 'assets/branding/splash_wordmark_white.png';
  static const _sourceWidth = 1280.0;
  static const _sourceHeight = 385.0;
  static const _textRight = 1136.0;
  static const _dotCenter = Offset(1194.5, 246);
  static const _dotDiameter = 83.0;
  static const _dotColor = Color(0xfffb5248);

  @override
  Widget build(BuildContext context) {
    final scale = width / _sourceWidth;
    final height = _sourceHeight * scale;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: _textRight * scale,
            height: height,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: width,
                maxWidth: width,
                minHeight: height,
                maxHeight: height,
                child: Image.asset(
                  asset,
                  package: 'frizeraj_ui',
                  width: width,
                  height: height,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          Positioned(
            left: (_dotCenter.dx - _dotDiameter / 2) * scale,
            top: (_dotCenter.dy - _dotDiameter / 2) * scale,
            width: _dotDiameter * scale,
            height: _dotDiameter * scale,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: _dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
