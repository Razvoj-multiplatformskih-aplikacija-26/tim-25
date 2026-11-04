import 'package:flutter/material.dart';

import 'brand_mark.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.message = 'Nema prijava za prikaz.',
    required this.onRefresh,
  });
  final String message;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandMark(size: 64),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRefresh, child: const Text('Osveži')),
        ],
      ),
    ),
  );
}
