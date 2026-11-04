import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:frizeraj_ui/frizeraj_ui.dart';

import '../presentation/salon_discovery.dart';

class DiscoverySalonCard extends StatelessWidget {
  const DiscoverySalonCard({
    super.key,
    required this.salon,
    required this.snapshot,
    required this.onTap,
  });
  final Salon salon;
  final QueueSnapshot snapshot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = SalonDiscoveryInfo.demo[salon.id.value];
    final prices = snapshot.services
        .where((s) => s.salonId == salon.id)
        .map((s) => s.priceRsd);
    final price = prices.isEmpty
        ? null
        : prices.reduce((a, b) => a < b ? a : b);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final photoSize = (constraints.maxWidth * .3).clamp(80.0, 122.0);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: photoSize,
                    height: photoSize,
                    decoration: BoxDecoration(
                      color: const Color(0xffeee7df),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          salon.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: FrizerajColors.navy,
                            height: 1.15,
                            letterSpacing: -.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (info != null)
                          Row(
                            children: [
                              const FrizerajIcon('star_rating', size: 17),
                              const SizedBox(width: 6),
                              Text(
                                info.rating
                                    .toStringAsFixed(1)
                                    .replaceAll('.', ','),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '(${info.reviewCount})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: FrizerajColors.muted,
                                ),
                              ),
                              const Spacer(),
                              const FrizerajIcon('chevron_right', size: 18),
                            ],
                          ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FrizerajIcon('location_salon', size: 15),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                salon.address,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: FrizerajColors.navy,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (info != null)
                              Tooltip(
                                message: 'Demo procena čekanja',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: info.waitMinutes <= 10
                                        ? const Color(0xffdeedce)
                                        : info.waitMinutes <= 15
                                        ? const Color(0xfff0e5d7)
                                        : const Color(0xffffdacb),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const FrizerajIcon('clock', size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        '~ ${info.waitMinutes} min',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (price != null)
                              Text(
                                'od ${_formatPrice(price)} RSD',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: FrizerajColors.muted,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatPrice(int price) => price.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );
}
