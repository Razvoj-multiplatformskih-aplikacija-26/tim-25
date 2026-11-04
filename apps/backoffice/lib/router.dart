import 'package:domain/domain.dart';
import 'package:go_router/go_router.dart';

import 'screens/queue_screen.dart';

GoRouter createBackofficeRouter({String? initialLocation}) => GoRouter(
  initialLocation: initialLocation,
  overridePlatformDefaultLocation: initialLocation != null,
  routes: [
    GoRoute(path: '/', builder: (_, _) => const QueueScreen()),
    GoRoute(
      path: '/entries/:id',
      builder: (_, state) =>
          QueueScreen(initialId: QueueEntryId(state.pathParameters['id']!)),
    ),
  ],
);
