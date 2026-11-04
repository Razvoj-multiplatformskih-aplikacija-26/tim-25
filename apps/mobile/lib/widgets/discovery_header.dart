import 'package:flutter/material.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';

import '../presentation/salon_discovery.dart';

class DiscoveryHeader extends StatelessWidget {
  const DiscoveryHeader({
    super.key,
    required this.onCityTap,
    required this.onNotificationsTap,
    required this.hasNotification,
    required this.searchController,
    required this.onSearch,
    required this.sort,
    required this.onSort,
  });

  final VoidCallback onCityTap;
  final VoidCallback onNotificationsTap;
  final bool hasNotification;
  final ValueChanged<String> onSearch;
  final TextEditingController searchController;
  final SalonSort sort;
  final ValueChanged<SalonSort> onSort;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          TextButton(
            onPressed: onCityTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: FrizerajColors.navy,
            ),
            child: const Row(
              children: [
                FrizerajIcon('location_header', size: 26),
                SizedBox(width: 8),
                Text(
                  'Beograd',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
                ),
                SizedBox(width: 10),
                FrizerajIcon('chevron_down', size: 19),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Obaveštenja',
            onPressed: onNotificationsTap,
            icon: FrizerajIcon(
              hasNotification ? 'notification_bell' : 'notification_bell_plain',
              size: 27,
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      TextField(
        controller: searchController,
        onChanged: onSearch,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Pretraži frizerske salone',
          hintStyle: const TextStyle(fontSize: 15, color: FrizerajColors.muted),
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.all(12),
            child: FrizerajIcon('search', size: 23),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: FrizerajColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: FrizerajColors.navy),
          ),
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: SalonSort.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final option = SalonSort.values[index];
            final selected = option == sort;
            return Semantics(
              selected: selected,
              child: OutlinedButton(
                onPressed: () => onSort(option),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: selected
                      ? FrizerajColors.navy
                      : Colors.transparent,
                  foregroundColor: selected
                      ? Colors.white
                      : FrizerajColors.charcoal,
                  side: BorderSide(
                    color: selected ? FrizerajColors.navy : FrizerajColors.line,
                  ),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontFamily: frizerajFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                child: Text(option.label),
              ),
            );
          },
        ),
      ),
    ],
  );
}
