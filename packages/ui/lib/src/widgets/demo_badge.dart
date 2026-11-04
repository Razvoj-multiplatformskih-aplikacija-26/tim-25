import 'package:flutter/material.dart';

import '../theme/colors.dart';

class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key, this.staff = false});
  final bool staff;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
    child: Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: FrizerajColors.coral,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            staff ? 'Demo prostor · subota, 12:00' : 'Zdravo, Boris.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (!staff)
          Text(
            'Demo · subota, 12:00',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    ),
  );
}
