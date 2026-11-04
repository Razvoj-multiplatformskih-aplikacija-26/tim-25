import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 38});
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/branding/logo.png',
    package: 'frizeraj_ui',
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    semanticLabel: 'Frizeraj logo',
  );
}
