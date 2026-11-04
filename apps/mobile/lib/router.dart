import 'package:domain/domain.dart';
import 'package:go_router/go_router.dart';

import 'screens/join_queue_screen.dart';
import 'screens/my_entries_screen.dart';
import 'screens/queue_entry_detail_screen.dart';
import 'screens/salon_detail_screen.dart';
import 'screens/salons_screen.dart';
import 'screens/profile_screen.dart';

GoRouter createMobileRouter({String? initialLocation}) => GoRouter(
  initialLocation: initialLocation,
  overridePlatformDefaultLocation: initialLocation != null,
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SalonsScreen()),
    GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    GoRoute(
      path: '/salons/:id',
      builder: (_, state) =>
          SalonDetailScreen(salonId: SalonId(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/salons/:id/join',
      builder: (_, state) =>
          JoinQueueScreen(salonId: SalonId(state.pathParameters['id']!)),
    ),
    GoRoute(path: '/entries', builder: (_, _) => const MyEntriesScreen()),
    GoRoute(
      path: '/entries/:id',
      builder: (_, state) => QueueEntryDetailScreen(
        entryId: QueueEntryId(state.pathParameters['id']!),
      ),
    ),
  ],
);
