import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/colors.dart';

class SplashBackground extends StatelessWidget {
  const SplashBackground({super.key, this.exitProgress = 0});
  final double exitProgress;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.topRight,
        radius: 1.6,
        colors: [FrizerajColors.navy, Color(0xff102343)],
      ),
    ),
    child: CustomPaint(
      painter: _SplashWavesPainter(exitProgress),
      child: const SizedBox.expand(),
    ),
  );
}

class _SplashWavesPainter extends CustomPainter {
  const _SplashWavesPainter(this.exitProgress);
  final double exitProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final topWidth = math.min(size.width * .42, 440.0);
    final topHeight = math.min(size.height * .125, 160.0);
    canvas.save();
    canvas.translate(-topWidth * exitProgress, 0);
    final topWave = Path()
      ..moveTo(0, 0)
      ..lineTo(topWidth, 0)
      ..cubicTo(
        topWidth * .78,
        topHeight * .52,
        topWidth * .34,
        topHeight * .27,
        0,
        topHeight,
      )
      ..close();
    canvas.drawPath(
      topWave,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FrizerajColors.cream, Color(0xffe7d9cc)],
        ).createShader(Rect.fromLTWH(0, 0, topWidth, topHeight)),
    );
    final highlight = Path()
      ..moveTo(0, 0)
      ..lineTo(topWidth * .34, 0)
      ..cubicTo(
        topWidth * .27,
        topHeight * .24,
        topWidth * .15,
        topHeight * .42,
        0,
        topHeight * .6,
      )
      ..close();
    canvas.drawPath(
      highlight,
      Paint()..color = Colors.white.withValues(alpha: .22),
    );

    canvas.restore();
    final bottomWidth = math.min(size.width * .56, 560.0);
    final bottomHeight = math.min(size.height * .155, 220.0);
    canvas.save();
    canvas.translate(bottomWidth * exitProgress, 0);
    final right = size.width;
    final bottom = size.height;
    final bottomWave = Path()
      ..moveTo(right - bottomWidth, bottom)
      ..cubicTo(
        right - bottomWidth * .67,
        bottom - bottomHeight * .5,
        right - bottomWidth * .31,
        bottom - bottomHeight * .19,
        right - bottomWidth * .14,
        bottom - bottomHeight * .65,
      )
      ..cubicTo(
        right - bottomWidth * .07,
        bottom - bottomHeight * .82,
        right - bottomWidth * .02,
        bottom - bottomHeight * .94,
        right,
        bottom - bottomHeight,
      )
      ..lineTo(right, bottom)
      ..close();
    canvas.drawPath(
      bottomWave,
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [FrizerajColors.coral, Color(0xffc95850)],
            ).createShader(
              Rect.fromLTWH(
                right - bottomWidth,
                bottom - bottomHeight,
                bottomWidth,
                bottomHeight,
              ),
            ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SplashWavesPainter oldDelegate) =>
      oldDelegate.exitProgress != exitProgress;
}
