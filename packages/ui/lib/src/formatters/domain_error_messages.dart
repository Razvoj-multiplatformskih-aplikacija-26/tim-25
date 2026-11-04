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
  InvalidNote() => 'Napomena može imati najviše $maxNoteLength znakova.',
  RepositoryUnavailable() => 'Podaci trenutno nisu dostupni. Pokušaj ponovo.',
};
