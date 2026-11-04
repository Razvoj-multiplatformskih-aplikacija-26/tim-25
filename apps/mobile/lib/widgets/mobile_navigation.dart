import 'package:flutter/material.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';
import 'package:go_router/go_router.dart';

class MobileNavigation extends StatelessWidget {
  const MobileNavigation({super.key, required this.selectedIndex});
  final int selectedIndex;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: FrizerajColors.cream,
            borderRadius: BorderRadius.circular(40),
            boxShadow: const [
              BoxShadow(
                color: Color(0x160e2036),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                for (final (index, label, icon, route) in [
                  (0, 'Saloni', 'home_outline', '/'),
                  (1, 'Moj red', 'calendar', '/entries'),
                  (2, 'Profil', 'profile', '/profile'),
                ])
                  Expanded(
                    child: Semantics(
                      selected: selectedIndex == index,
                      child: Material(
                        color: selectedIndex == index
                            ? FrizerajColors.navy
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(32),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(32),
                          onTap: () => context.go(route),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FrizerajIcon(
                                  index == 0 && selectedIndex == 0
                                      ? 'home_active'
                                      : icon,
                                  size: 23,
                                  color: selectedIndex == index
                                      ? Colors.white
                                      : FrizerajColors.navy,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: selectedIndex == index
                                        ? Colors.white
                                        : FrizerajColors.navy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
