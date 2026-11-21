import 'package:domain/domain.dart';

String errorMessage(DomainError error) => switch (error) {
  SalonClosed() =>
    'Salon trenutno ne radi. Prijava je moguća tokom radnog vremena.',
  ActiveEntryAlreadyExists() => 'Već imaš aktivnu prijavu u ovom salonu.',
  UnsupportedService() => 'Izabrana usluga nije dostupna u ovom salonu.',
  InvalidTransition() => 'Ova promena nije dozvoljena u trenutnom stanju.',
  Forbidden() => 'Nemaš pravo na ovu akciju.',
  NotFound() => 'Traženi zapis nije pronađen.',
  Conflict() =>
    'Prijava je u međuvremenu promenjena. Osveži podatke i pokušaj ponovo.',
  InvalidNote(:final maxLength) =>
    'Napomena može imati najviše $maxLength znakova.',
  SessionExpired() => 'Prijava je istekla. Prijavi se ponovo.',
  InvalidCredentials() => 'Korisničko ime ili lozinka nisu ispravni.',
  WrongApplication() => 'Ovaj nalog nije namenjen ovoj aplikaciji.',
  InvalidRequest() => 'Zahtev nije ispravan. Proveri unos i pokušaj ponovo.',
  RepositoryUnavailable() => 'Podaci trenutno nisu dostupni. Pokušaj ponovo.',
};
