import 'package:flutter/material.dart';

import '../theme/colors.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.dark = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool dark;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: dark ? FrizerajColors.navy : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: dark ? FrizerajColors.navy : FrizerajColors.line,
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: dark
                      ? FrizerajColors.onNavyMuted
                      : FrizerajColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  height: 1,
                  letterSpacing: -.8,
                  fontWeight: FontWeight.w700,
                  color: dark ? Colors.white : FrizerajColors.charcoal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          icon,
          size: 23,
          color: dark ? FrizerajColors.coral : FrizerajColors.navy,
        ),
      ],
    ),
  );
}
