import 'package:domain/domain.dart';

enum SalonSort {
  nearest('Najbliži'),
  shortestWait('Najkraće čekanje'),
  bestRated('Najbolje ocenjeni');

  const SalonSort(this.label);
  final String label;
}

class SalonDiscoveryInfo {
  const SalonDiscoveryInfo({
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.waitMinutes,
  });

  final double rating;
  final int reviewCount;
  final double distanceKm;
  final int waitMinutes;

  static const demo = {
    's0': SalonDiscoveryInfo(
      rating: 4.8,
      reviewCount: 312,
      distanceKm: .5,
      waitMinutes: 25,
    ),
    's1': SalonDiscoveryInfo(
      rating: 4.7,
      reviewCount: 189,
      distanceKm: 1.2,
      waitMinutes: 5,
    ),
    's2': SalonDiscoveryInfo(
      rating: 4.9,
      reviewCount: 421,
      distanceKm: 3.1,
      waitMinutes: 40,
    ),
    's3': SalonDiscoveryInfo(
      rating: 4.6,
      reviewCount: 97,
      distanceKm: 4.5,
      waitMinutes: 15,
    ),
  };
}

String _searchText(String value) => value
    .toLowerCase()
    .replaceAll('š', 's')
    .replaceAll('č', 'c')
    .replaceAll('ć', 'c')
    .replaceAll('ž', 'z')
    .replaceAll('đ', 'dj');

List<Salon> discoverSalons(
  QueueSnapshot snapshot,
  String query,
  SalonSort sort,
) {
  final search = _searchText(query.trim());
  final salons = snapshot.salons
      .where(
        (salon) =>
            _searchText('${salon.name} ${salon.address}').contains(search),
      )
      .toList();
  salons.sort((a, b) {
    final first = SalonDiscoveryInfo.demo[a.id.value];
    final second = SalonDiscoveryInfo.demo[b.id.value];
    if (first == null) return second == null ? a.name.compareTo(b.name) : 1;
    if (second == null) return -1;
    final comparison = switch (sort) {
      SalonSort.nearest => first.distanceKm.compareTo(second.distanceKm),
      SalonSort.shortestWait => first.waitMinutes.compareTo(second.waitMinutes),
      SalonSort.bestRated => second.rating.compareTo(first.rating),
    };
    return comparison == 0 ? a.id.value.compareTo(b.id.value) : comparison;
  });
  return salons;
}
