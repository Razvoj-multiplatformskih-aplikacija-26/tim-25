# Frizeraj

<img src="packages/ui/assets/branding/logo.png" width="96" alt="Frizeraj logo">

Sistem za red čekanja u frizerskim salonima, bez zakazivanja termina. Klijenti preko mobilne aplikacije pregledaju salone, biraju uslugu i prijavljuju se u red. Osoblje prati prijave, upravlja dostupnošću frizera i beleži početak i završetak usluge.

Projekat iz predmeta Razvoj multiplatformskih aplikacija, tim 25.

## Tim

| Ime i prezime | Broj indeksa | GitHub nalog |
| --- | --- | --- |
| Boris Bošković | SI 114/24 | [@CoolGitGuy](https://github.com/CoolGitGuy) |
| Filip Karadžić | SI 131/24 | [@StaticVoid-0](https://github.com/StaticVoid-0) |

## Zahtevi za temu

Glavni pojam sistema je **prijava u red** za određeni salon i uslugu.

1. **Uloge.** Klijent pregleda salone, prijavljuje se u red i otkazuje svoju prijavu dok čeka. Osoblje upravlja dostupnošću frizera, početkom i završetkom usluge i nedolaskom klijenata.
2. **Stanja.** Prijava može biti na čekanju, pozvana, u toku, završena, otkazana ili označena kao nedolazak. Zajednički domen određuje dozvoljene prelaze između stanja.
3. **Pravila.** Klijent može imati najviše jednu aktivnu prijavu po salonu, prijavljivanje je dozvoljeno tokom radnog vremena, a napomena ima najviše 120 znakova. Automatska dodela bira najranijeg klijenta čiju uslugu slobodan frizer pruža. Server proverava pravila i dodelu uz aktuelne podatke iz baze.
4. **Rad bez mreže.** U KT3 planirano je lokalno čuvanje zahteva za otkazivanje i slanje po povratku mreže. Server će proveriti aktuelno stanje i moći da odbije otkazivanje ako je klijent u međuvremenu pozvan.
5. **Posao za osoblje.** Backoffice prikazuje prijave, statuse, detalje i dostupnost frizera na većem ekranu. Osoblje koristi tastaturu i akcije za obradu reda, dok uži prozor prikazuje listu uz očuvan izbor prijave.
6. **Javni sadržaj.** U KT4 planiran je javni veb sa salonima, uslugama, cenama, radnim vremenom i stanjem reda bez ličnih podataka klijenata. Taj sadržaj dostupan je i bez naloga i ima smisla za indeksiranje u pretraživačima.

## Delovi sistema

| Deo | Korisnici | Tehnologija | Platforme |
| --- | --- | --- | --- |
| Mobilna aplikacija | klijenti | Flutter | Android |
| Backoffice | osoblje salona | Flutter | Windows, veb |
| Server | oba klijenta | Dart, Relic 1.2.0, PostgreSQL | Docker |
| Domenski paket | oba klijenta | Dart | nezavisan od platforme |

Oba klijenta koriste isti domenski paket, Bloc i mrežni adapter. Server koristi isti domen i čuva podatke u PostgreSQL-u.

## Pokretanje

Provereno sa Flutter 3.47.7 i Dart 3.13.5. Za Android su potrebni Android SDK i emulator ili povezan uređaj; za Windows Visual Studio sa opcijom **Desktop development with C++**, a za veb Chrome ili Edge.

Sve aplikacije i paketi pripadaju jednom pub workspace-u. Zavisnosti se preuzimaju iz korena projekta:

```powershell
flutter pub get
flutter devices
```

Uključi Docker Desktop. Iz korena projekta kopiraj razvojna podešavanja i podigni server i bazu:

```powershell
Copy-Item .env.example .env
docker compose up --build --wait
```

Server je na portu 8080. Prvo podizanje učitava šemu i demo podatke. Sledeće podizanje čuva stanje. `.env` je lokalni fajl. Ima razvojne vrednosti koje se koriste samo za demonstraciju.

Mobilna aplikacija, iz korena projekta, uz pokrenut Android emulator ili povezan telefon:

```powershell
cd apps/mobile
flutter run -d emulator-5554
```

Backoffice za Windows, iz zasebnog terminala u korenu projekta:

```powershell
cd apps/backoffice
flutter run -d windows
```

Za veb, iz foldera `apps/backoffice`:

```powershell
flutter run -d chrome --web-hostname localhost --web-port 7357
```

ID Android uređaja prikazuje komanda `flutter devices`. Android emulator se povezuje na `10.0.2.2:8080`, a Windows i veb koriste `localhost:8080`. Dodatnu adresu postavi pomoću `--dart-define=API_BASE_URL=https://adresa-servera`. Windows i web backend se proveravaju nad istom bazom kao mobilna aplikacija.

| Korisničko ime | Lozinka iz .env.example | Aplikacija |
| --- | --- | --- |
| `boris` | `FrizerajDemo26` | mobilna |
| `filip` | `FrizerajDemo26` | mobilna |
| `osoblje` | `FrizerajDemo26` | backoffice |

Početni skup ima 17 prijava kroz svih šest stanja. Podrazumevani demonstracioni poslovni sat je **21.11.2026. u 12:00** po vremenu Beograda. Brisanjem vrednosti `DEMO_BUSINESS_TIME` koristi se stvarno vreme. Sesija koristi stvarno vreme, pa se istek na odbrani može pokazati kratkom vrednošću `SESSION_SECONDS`, ponovnim podizanjem servera i novom prijavom.

Izričiti KT1 režim pokreće se sa `--dart-define=FRIZERAJ_FAKE=true`. U tom režimu rade početni podaci u memoriji i meni **Demo kontrole**.

## Struktura

```text
apps/mobile          mobilni klijent: saloni, forma, moje prijave i detalj
apps/backoffice      osoblje: tabela/lista, detalj i dostupnost frizera
apps/server          rute, autentifikacija, SQL migracije i upis reda
packages/domain      modeli, ID tipovi, stanja, pravila i port repozitorijuma
packages/use_cases   memorijski adapter, početni podaci i demo sat
packages/blocs       zajednički QueueBloc, događaji i stanje
packages/ui          tema, ikonice, poruke, splash i zajednički widgeti
packages/api_contract zahtevi, odgovori i kodovi grešaka
packages/api_mapping  prevod između API ugovora i domena
packages/api_client   HTTP klijent i udaljeni repozitorijumi
```

Paketi `domain`, `use_cases` i `blocs` su čisti Dart, bez Flutter i platformskih zavisnosti. `blocs` i `use_cases` zavise od domena; aplikacije povezuju repozitorijume, Bloc i interfejs. Ekrani šalju događaje, a validacija i dozvoljene promene stanja nalaze se u domenu.

## Provere

Iz korena projekta:

```powershell
flutter analyze
flutter test packages/domain/test packages/use_cases/test packages/blocs/test packages/ui/test apps/mobile/test apps/backoffice/test tools/kt1_acceptance_test.dart
flutter test tools/kt2_acceptance_test.dart
```

Za KT2 testove sa stvarnom bazom koristi poseban Compose projekat i sveže početne podatke. Test menja stanje te baze.

```powershell
$env:API_PORT = '18080'
docker compose -p frizeraj-kt2-test up --build --wait
$env:FRIZERAJ_TEST_URL = 'http://localhost:18080'
flutter test tools/kt2_acceptance_test.dart
docker compose -p frizeraj-kt2-test down
Remove-Item Env:API_PORT, Env:FRIZERAJ_TEST_URL
```

Za novi testni prolaz koristi drugo ime Compose projekta da dobiješ praznu bazu. Testovi pokrivaju istovremenu prijavu, dodelu frizera, zastarelu reviziju, prava, vidljivost promena, API paginaciju, ugovor grešaka i web sesije.

Za proveru prijave, obnove sesije i odjave u pokrenutoj aplikaciji koristi sledeće komande u odgovarajućim folderima, dok server radi:

```powershell
# U apps/mobile
flutter test integration_test/kt2_session_test.dart -d emulator-5554

# U apps/backoffice
flutter test integration_test/kt2_session_test.dart -d windows
```

## Stanje projekta

**KT2 — server i korisnici.** Klijent vidi svoje prijave, poziciju i zbirno stanje reda. Osoblje vidi i obrađuje prijave salona. Istovremene promene reda zaključavaju isti salon u bazi, nakon čega zajednički domen radi proveru i dodelu. Klijenti na zahtev osvežavaju podatke.

Backoffice podržava izbor strelicama, `Ctrl+Enter` za početak i završetak usluge, `Ctrl+R` za osvežavanje i `Esc` za zatvaranje detalja. Sužavanje prozora menja tabelu u listu uz očuvan izbor. Rad bez mreže i javni veb pripadaju narednim kontrolnim tačkama.
