# blocs

Pravi QueueBloc sa događajima i Equatable stanjima, bez Flutter zavisnosti.
Komunicira preko domenskog QueueRepository porta. Događaji se obrađuju sekvencijalno.
Implementacija je u `lib/src/queue_bloc.dart`, događaji u `queue_event.dart`,
a Equatable stanje u `queue_state.dart`; javni API ostaje `lib/blocs.dart`.
Testovi iz root-a: `flutter test packages/blocs/test`.
