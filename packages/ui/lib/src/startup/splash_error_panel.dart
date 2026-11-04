import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../formatters/domain_error_messages.dart';
import '../theme/colors.dart';

class SplashErrorPanel extends StatelessWidget {
  const SplashErrorPanel({
    super.key,
    required this.error,
    required this.onRetry,
  });
  final DomainError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              errorMessage(error),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: FrizerajColors.cream,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: FrizerajColors.cream,
              foregroundColor: FrizerajColors.navy,
            ),
            child: const Text('Pokušaj ponovo'),
          ),
        ],
      ),
    ),
  );
}
