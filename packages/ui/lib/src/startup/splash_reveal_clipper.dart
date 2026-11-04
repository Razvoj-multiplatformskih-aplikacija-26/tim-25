import 'dart:math' as math;

import 'package:flutter/material.dart';

class SplashRevealClipper extends CustomClipper<Path> {
  const SplashRevealClipper({required this.center, required this.progress});

  final Offset center;
  final double progress;

  @override
  Path getClip(Size size) {
    final dx = math.max(center.dx, size.width - center.dx);
    final dy = math.max(center.dy, size.height - center.dy);
    final radius = math.sqrt(dx * dx + dy * dy);
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius * progress));
  }

  @override
  bool shouldReclip(SplashRevealClipper oldClipper) =>
      center != oldClipper.center || progress != oldClipper.progress;
}
