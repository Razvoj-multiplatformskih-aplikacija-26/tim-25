import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../formatters/domain_error_messages.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});
  final DomainError error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(errorMessage(error), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Pokušaj ponovo')),
        ],
      ),
    ),
  );
}
