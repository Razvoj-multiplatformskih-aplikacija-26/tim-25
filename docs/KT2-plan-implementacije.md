# Plan implementacije Frizeraja za KT2

Datum: 21.11.2026. Ovaj dokument čuva početni plan i rezultat provere na kraju.

Cilj je da Android aplikacija i backoffice za Windows i pregledač rade nad istim serverom i bazom, sa prijavom korisnika, zajedničkim pravilima i proverljivom zaštitom istovremenih zahteva. Osnova su zahtevi dokumenta „KT2 - Server i korisnici.docx”. Rok naveden u njemu je 21.11.2026. u 23:59:59; kompletan obim ne treba smatrati završenim dok ne prođu provere u ovom planu.

## Polazište

Pregledan je lokalni commit `5bf5744`. Pre dodavanja ovog plana radno stablo je bilo čisto.

- `packages/domain` već sadrži modele, šest statusa, uloge, tipizovane greške, `QueueRepository` i funkcije validacije i dodele frizera.
- `packages/blocs` već sadrži zajednički `QueueBloc`, događaje i stanje. Ekrani ne treba da dobiju HTTP ili SQL logiku.
- `packages/use_cases` trenutno sadrži memorijski adapter i demo podatke. Sinhroni upis u taj adapter nije zaštita između SQL transakcija ili procesa.
- Aplikacije podrazumevano koriste zasebne fake repozitorijume i fiksne aktere. Mobilni detalj i lista dodatno direktno koriste `demoClient`.
- `InvalidNote` nema polje za limit; poruka koristi lokalni `maxNoteLength`. To mora da se promeni za scenario stare aplikacije i novog serverskog pravila.
- `queuePosition` računa poziciju iz cele liste prijava. Serverski odgovor za klijenta mora sačuvati tačan položaj bez izlaganja tuđih imena i napomena.
- Server, API ugovor, mrežni adapter, prijava, baza i Compose još ne postoje.
- Docker CLI i Compose su instalirani, ali Docker Linux engine nije dostupan tokom pregleda. Pre serverskih testova pokrenuti Docker Desktop i proveriti engine; ne menjati sistemske bezbednosne postavke radi pokretanja.

Pre implementacije ponovo proveriti lokalne izmene i udaljenu istoriju. KT1 commit ostaje dostupan za zasebnu odbranu; ne prepisivati istoriju i ne raditi force push.

## Predložene odluke

Ovo su polazne odluke za implementaciju. Svaku potvrditi funkcionalnim testom, a promenu upisati u ovaj plan i konačni README.

| Oblast | Izbor | Odbačena mogućnost i razlog |
| --- | --- | --- |
| Server | Dart, tačno `relic: 1.2.0`, `apps/server` | Noviji Relic nije verzija koju specifikacija traži. |
| Baza | PostgreSQL 17, SQL migracije, parametrizovani upiti | Memorijska baza ne daje trajnost i SQL zaštitu potrebnu za KT2. |
| Konkurentnost | Transakcija sa zaključavanjem reda salona i dodatnim ograničenjima baze | Mutex u jednom Dart procesu ne štiti više procesa. |
| Prijava | Nasumični neprozirni tokeni, heš tokena i istek u tabeli sesija | JWT ovde dodaje složenost opoziva, bez potrebne koristi. |
| Lozinke | PBKDF2 HMAC SHA256 kroz održavanu biblioteku; početno 600.000 iteracija, nasumični salt, sačuvani parametri | Običan SHA256 i šifrovana lozinka nisu heširanje lozinki. Argon2id je dobra alternativa, ali zahteva dodatnu proveru implementacije i pakovanja. |
| Obaveštavanje o promenama | Ručno osvežavanje i osvežavanje posle akcije ili poslovnog odbijanja | WebSocket nije neophodan jer KT2 dopušta vidljivost posle osvežavanja. |
| Spoljni servis | Predlog: port za obaveštenje da je klijent pozvan, sa fake implementacijom samo na serveru | Direktan poziv servisa iz Fluttera otkriva ključ i zaobilazi server. |
| Pristup podacima | Svi poslovni podaci zahtevaju prijavu; osoblje vidi sve salone demo sistema, klijent katalog, svoje prijave i zbirne podatke o redu | Slanje kompletnog reda sa tuđim ličnim podacima pa filtriranje u UI nije kontrola pristupa. |

Spoljni servis za obaveštenja je predlog za Frizeraj, ne zahtev za tačno taj servis iz KT2. Ako je u prihvaćenoj temi dogovorena druga integracija, pre implementacije tog porta uskladiti izbor. Za KT2 nije potreban plaćeni nalog niti stvarno slanje poruka.

## Organizacija koda

```text
apps/server
  bin/                 ulazna tačka, konfiguracija i pokretanje
  lib/src/http/        Relic rute, autentifikacija, CORS i odgovor na greške
  lib/src/application/ serverske operacije i transakcione granice
  lib/src/data/        PostgreSQL adapteri, migracije i seed
  lib/src/auth/        heširanje lozinki i izdavanje sesija
  lib/src/integrations/ port obaveštenja i fake implementacija
  test/                HTTP i integracione provere nad PostgreSQL-om
packages/api_contract  DTO zahteva, odgovora, grešaka i JSON kodiranje
packages/api_mapping   jedini prevod ugovor ↔ domen, uključujući greške
packages/api_client    zajednički HTTP kod i udaljeni repozitorijumi
apps/mobile/lib/data/android_session_storage.dart
apps/backoffice/lib/data/windows_session_storage.dart
apps/backoffice/windows/runner/session_storage.cpp
compose.yaml           baza i server sa healthcheck-ovima i volume-om
.env.example           razvojna podešavanja i demo kredencijali
```

Zavisnosti: `api_contract` ne uvozi domen, Flutter ili `dart:io`; `api_mapping` zavisi samo od ugovora i domena. `api_client` koristi njih i HTTP biblioteku koja radi na VM-u i u pregledaču. `domain`, `use_cases` i `blocs` ostaju čisti Dart. Platformski adapteri sesije su u aplikacijama, a port je u domenu.

Zadržati postojeće ekrane, rute, Manrope, boje, logo i splash. Dodati samo neophodnu prijavu, odjavu, poruke o isteku i prikaz stvarnog korisnika. Ne uvoditi registraciju, reset lozinke, novi dizajn, javni veb, offline slanje ili sistem rezervacija za KT2.

## Faza 0 Provera osnove

1. Proveriti SDK, Docker engine, Compose, slobodne portove 8080 i 7357 i postojeće izmene. Ne instalirati niti nadograđivati alate bez stvarne potrebe.
2. Ponoviti analizu i postojeće funkcionalne testove; zabeležiti početni rezultat. Render proveru koristiti ako se menja postojeći izgled.
3. Proveriti da Relic 1.2.0, SQL drajver, kriptografska biblioteka i secure storage mogu zajedno da se razreše i izgrade za potrebne platforme. Biblioteke uvoditi samo gde su potrebne.
4. Sačuvati pristup KT1 commit-u i raditi KT2 u zasebnoj grani. Commit i push raditi kada korisnik traži; ne prepisivati udaljene izmene.

Uslov završetka: poznata početna provera i dostupno okruženje za realne serverske testove. Ako engine ne radi, ugovor i domen mogu napredovati, ali serverski testovi ne smeju biti prijavljeni kao prošli.

## Faza 1 Ugovor i dopuna domena

1. Dodati `api_contract` i `api_mapping` u workspace. Ručno napisati male DTO klase i testove kodiranja; generator uvoditi samo ako je opravdan količinom koda.
2. Verzija API-ja je `/api/v1`. Dogovoriti login, obnovu trenutne sesije, logout, pregled kataloga/reda, detalj prijave, novu prijavu, promenu statusa i dostupnosti frizera.
3. ID vrednosti i statusi na mreži su stabilni stringovi; novac je ceo broj RSD kao u sadašnjem domenu. Trenuci su ISO8601 UTC sa `Z`, a radno vreme ima vremensku zonu `Europe/Belgrade`.
4. Greška ima stabilan `code` i strukturisane `details`, na primer `invalid_note` i `maxLength`. `InvalidNote` dobija stvarni limit, a zajednička UI poruka koristi taj podatak. Nepoznat kod ili novo stanje daju bezbednu opštu poruku, bez rušenja i sirovog serverskog teksta.
5. Izdvojiti proveru promene dostupnosti i pristupa aplikaciji u domenska pravila, umesto provere uloge samo unutar memorijskog adaptera. Prava promene statusa ostaju u domenu.
6. Klijentski odgovor sadrži samo njegove prijave, plus zbirne podatke i serverski izračunate pozicije. Dopuniti `QueueSnapshot` odgovarajućim projekcijama; fake adapter računa istu projekciju zajedničkom funkcijom. Serverska validacija i dodela rade nad potpunim podacima salona.
7. Za velike liste predvideti ograničen `limit` i neprozirni `cursor`, sa stabilnim redosledom i odvojenim detaljem po ID-u. Poslovna pravila i pozicija ne smeju zavisiti od učitane stranice. HTTP adapter može prikupljati stranice za postojeći prikaz KT1, uz konačne rokove i prekid na ponovljenom cursor-u; metapodaci o ukupnom redu dolaze sa servera.

Uslov završetka: testovi DTO ↔ domen ↔ DTO i svih grešaka prolaze; ugovor nema zabranjene zavisnosti; isti kod gradi se za web.

## Faza 2 Baza i ponovljivo podizanje

1. Dodati tabele `users`, `sessions`, `salons`, `services`, `barbers`, `barber_services` i `queue_entries`, uz migracionu evidenciju. Sačuvati reviziju, redni broj i vremenske oznake prijave.
2. Dodati strane ključeve, ograničenja statusa i delimične jedinstvene indekse: jedna aktivna prijava po korisniku i salonu; najviše jedna pozvana/usluga u toku po frizeru.
3. Dodati idempotentni seed sa najmanje 17 validnih prijava kroz svih šest stanja. Sve klijentske prijave imaju postojeći nalog; uključiti dva naloga za demonstraciju vlasništva i nalog osoblja. Seed ne briše korisničke promene pri svakom restartu.
4. Lozinke demo naloga dolaze iz razvojne konfiguracije i heširaju se pre upisa. U bazi nisu običan tekst. Token sesije se čuva samo kao heš, sa korisnikom, vrstom aplikacije, istekom i opozivom.
5. Dodati Dockerfile i Compose: server se pokreće iz monorepo konteksta, čeka spremnu bazu, primenjuje migracije i seed pre prijema saobraćaja. Build servera ne sme zahtevati instalaciju Fluttera u Dart kontejner samo zbog root dev zavisnosti; proveriti serverski build kontekst za čiste Dart pakete.
6. Dodati `.dockerignore`, ignorisati `.env` i lokalne podatke, a zadržati `.env.example`. Baza ima named volume i nije nepotrebno izložena spolja. `/health` proverava spremnost servera i baze.

Uslov završetka: kopiranje `.env.example` u `.env` bez izmena i `docker compose up --build -d` podižu sistem; restart čuva podatke; šema i seed rade iz prazne baze.

## Faza 3 Autentifikacija i serverske operacije

1. Login proverava heš lozinke, ulogu i aplikaciju. Backoffice odbija klijenta porukom „Backoffice je za osoblje salona.” Mobilna aplikacija je u ovoj fazi za klijente.
2. Middleware na svakom zaštićenom zahtevu nalazi sesiju, proverava istek/opoziv i učitava stvarnog korisnika. JSON zahtev ne sadrži pouzdani `actor`, ulogu ili proizvoljan vlasnički ID. Udaljeni adapter ne šalje postojeći `actor` parametar kao ovlašćenje; server ga izvodi iz sesije.
3. Svaka promena reda započinje transakciju i zaključava red odgovarajućeg salona `SELECT ... FOR UPDATE`. Tek posle zaključavanja čita aktuelne prijave i frizere, proverava ovlašćenje i reviziju, poziva zajednički domen, upisuje promenu i automatske dodele, pa potvrđuje transakciju.
4. Isti redosled zaključavanja važi za novu prijavu, promenu statusa i dostupnosti frizera. Ne zaključavati samo postojeću prijavu: kod istovremenog kreiranja ona još ne postoji. Ne zaključavati sve salone za jednu akciju.
5. SQL ograničenja daju dodatnu zaštitu. Poznata kršenja prevode se u isti domenski kod greške; nepoznata interna greška ne vraća SQL ili stack trace. Upiti su parametrizovani, transakcije imaju rok i rollback.
6. Posle izmene i dalje važi zajednička kompatibilna dodela. Domen ne prepisivati u SQL uslovima kao drugi izvor poslovnih pravila.
7. Poziv lažnog servisa za obaveštenja sledi tek posle uspešnog commit-a za novopozvane prijave. Ne držati zaključavanje dok se čeka spoljni servis; greška obaveštenja ne poništava završenu poslovnu akciju. Za KT2 dokumentovati ograničenje bez garantovane dostave i ne uvoditi queue sistem bez potrebe.
8. Pravi serverski sat je UTC, sa pretvaranjem u vreme salona pre validacije radnog vremena. Za odbranu dozvoliti eksplicitno razvojno podešavanje poslovnog sata. Sat isteka sesija uvek je stvarni/testom kontrolisani UTC sat, odvojen od demo poslovnog sata.

Uslov završetka: HTTP testovi nad stvarnom bazom potvrđuju vlasništvo, uloge, revizije i istovremene zahteve iz najmanje dva nezavisna klijenta/konekcije.

## Faza 4 Zajednički mrežni adapter

1. Dodati `RemoteQueueRepository` i udaljeni auth adapter u `api_client`, sa ubrizganim HTTP klijentom, konfiguracijom i portom sesije.
2. Postaviti ograničenje trajanja zahteva i dosledno mapirati nedostupnost, timeout, neispravan odgovor, 401, 403, 404, 409 i poslovne greške. Ne ponavljati automatski POST/PATCH bez idempotentnosti, jer je upis mogao uspeti pre prekida veze.
3. Dopuniti `QueueBloc`: posle poslovnog odbijanja učitati aktuelne podatke i zadržati razlog odbijanja. Ako i osvežavanje ne uspe, sačuvati razumljivu grešku i ponuditi retry; ne ostati u loading-u. Izbor sačuvati dok zapis postoji i dok korisnik ima pristup.
4. Normalno pokretanje koristi server. Fake ostaje za testove i izričito izabran demo režim, bez automatskog prebacivanja na izmišljene podatke kada server ne radi.
5. Podrazumevane razvojne adrese: Android emulator `http://10.0.2.2:8080`, Windows `http://localhost:8080`, web `http://localhost:8080`. Podesiv `API_BASE_URL` služi drugim uređajima bez izmene izvora. U aplikacionoj konfiguraciji nema tajni.
6. Android dobija dozvolu za internet i ograničenu razvojnu HTTP konfiguraciju; ne praviti globalno produkcijsko izuzeće za nešifrovan saobraćaj. Proveriti i zapakovani APK, ne samo debug.

Uslov završetka: isti adapter prolazi VM i browser provere; server i fake mogu da se zamene bez HTTP grananja po ekranima.

## Faza 5 Sesije i povezivanje aplikacija

1. Dodati zajednički `AuthBloc` za obnovu sesije, login, logout i istek. `QueueBloc` se pravi sa prijavljenim korisnikom, zatvara pri odjavi i ponovo pravi pri promeni naloga. Stari korisnički podaci ne ostaju sledećem korisniku.
2. Ukloniti `demoClient` i `demoStaff` iz normalnog toka, uključujući mobilne liste, detalj, profil, validaciju i dependency klase. Testovi i eksplicitni fake režim mogu koristiti demo aktere.
3. Startup redosled je obnova sesije → prijava ako je nema → učitavanje reda nakon prijave. Postojeći `StartupGate` ne sme sakriti login zato što neautentifikovani `QueueBloc` nikada nije učitao podatke. Sačuvati dozvoljenu direktnu rutu posle uspešne prijave.
4. Android i Windows čuvaju samo token kroz port i bezbedni platformski adapter, npr. `flutter_secure_storage`, uz proveru stvarnog Windows Credential Manager i Android Keystore mehanizma izabrane verzije. Ne koristiti običan fajl ili shared preferences za token; lozinku nikada ne čuvati.
5. Pregledač koristi trajni `HttpOnly`, `SameSite=Lax` cookie sa rokom koji ne prelazi serverski istek. Native klijenti koriste Bearer token. Cookie režim ne vraća sesijski token JavaScript-u. `Secure` je obavezan uz HTTPS; lokalni HTTP razvoj ima izričito razvojno podešavanje.
6. Web pokretati na stalnom `http://localhost:7357`. CORS dopušta samo dokumentovane razvojne origin-e, potrebne metode i kredencijale, sa OPTIONS podrškom; bez wildcard-a uz credentials. Ne mešati `localhost` i `127.0.0.1` u browser konfiguraciji. Cookie promene štititi proverom Origin-a i CSRF tokenom dobijenim iz login/session odgovora; login takođe proverava Origin. Bearer klijenti ne zavise od browser Origin-a.
7. Sesije imaju apsolutni TTL iz server konfiguracije. Istek se proverava na serveru pri svakom zahtevu i u klijentu radi pravovremene poruke; 401 briše lokalno stanje i vraća na prijavu. Mrežna greška nije dokaz isteka i ne sme sama obrisati prijavu.
8. Logout opoziva serversku sesiju i briše cookie/bezbedno skladište i korisničke podatke. Ako server nije dostupan, jasno razlikovati lokalnu odjavu od potvrđenog opoziva na serveru; token ne ostaje u lokalnoj aplikaciji.
9. Postojeće KT1 kontrole greške/praznog odgovora ostaju u fake režimu. U server režimu testirati ugašen server i pravi prazan rezultat; ne ostaviti vidljiv meni koji ništa ne radi.

Uslov završetka: prijava opstaje posle restarta Androida i Windowsa i browser refresh-a; logout i istek rade na sve tri platforme, a nalog pogrešne uloge je odbijen.

## Faza 6 Završna provera prema rubrici

| Scenario | Dokaz koji treba izvršiti |
| --- | --- |
| Direktan nedozvoljen zahtev | `curl` sa važećom sesijom krši domensko pravilo i dobija isti kod kao aplikacija. |
| Istovremena nova prijava | Dva zahteva istog klijenta za isti salon: tačno jedan uspeh i jedna aktivna prijava u bazi. |
| Konkurentna dodela | Dva različita klijenta i jedan slobodan kompatibilni frizer: najviše jedan pozvan; drugi ostaje u redu, bez dvostrukog zauzeća. |
| Zastareo zahtev osoblja | Dve promene iste revizije: jedna uspeva, druga dobija konflikt; klijent pokazuje razlog i osvežava stanje. |
| Dve zabranjene akcije | Klijentski token direktno pokušava početak i završetak usluge; obe akcije server odbija. |
| Tuđa prijava | Drugi klijent direktno pokušava čitanje privatnog detalja i otkazivanje Borisove prijave; nema curenja podataka niti izmene. |
| Promena vidljiva svuda | Mobilna prijava se vidi posle osvežavanja Windows i web backoffice-a; status koji promeni osoblje vidi mobilni klijent. |
| Nedostupan server | Ugašen server, timeout i povratak servera: konačna poruka i uspešan retry na svakoj platformi. |
| Stari mobilni build | Sačuvati izgrađen APK pre serverske izmene limita; promeniti domensko pravilo, obnoviti samo server, poslati sada nevažeći unos i videti poruku sa novim limitom bez pada. |
| Sesije | Login, restart/refresh, logout, ponovna upotreba opozvanog tokena, kratak TTL i pogrešna aplikacija na Androidu, Windowsu i webu. |
| Privatnost i paginacija | Klijent ne dobija tuđa imena/napomene; pozicija je tačna i kada drugi zapisi nisu poslati ili lista ima više stranica. |
| Trajnost i čist klon | Novi folder/klon, razvojni `.env` bez izmena, jedna Compose komanda, seed, oba klijenta i promene sačuvane posle restarta servera. |

Pored ciljanih domen, ugovor, adapter, Bloc i HTTP/SQL testova pokrenuti analizu i postojeće relevantne KT1 testove. Potrebni su Android, Windows i web buildovi i stvarni prolaz na emulatoru, desktopu i u pregledaču. Ponoviti testove kada se kod promeni ili nalaz to zahteva; ne predstavljati samo uspešan build kao dokaz funkcionalnog toka.

## Završni materijali

- README sa tačnim komandama iz čistog klona, tri ili više razvojnih naloga, podešavanjem adresa, TTL-a i poslovnog sata i odvojenim KT1/KT2 opisom.
- Kratki reproduktivni skriptovi direktnih i konkurentnih API poziva, bez ličnih tokena u repozitorijumu.
- Evidencija izvršenih provera i realnih preostalih problema, odvojena od planiranih provera.
- Kratak zapis izbora i odbačenih mogućnosti za konkurentnost, sesije, vidljivost, vreme/novac, paginaciju i browser ograničenja.
- Predaja je u repozitorijumu organizacije predmeta. Push samo na lični fork nije potvrda predaje; proveriti udaljeni `main` i vreme kada je commit stigao. Ne menjati datum commit-a radi predstavljanja zakašnjele predaje kao pravovremene.

## Pravila rada pri nastavku

Raditi faze redom, sa kratkim proverama nakon svake funkcionalne celine. Dovršavati povezane tokove, a nalaze unositi u ovaj plan. Ako Docker, potrebna sistemska instalacija ili pristup udaljenom repozitorijumu sprečavaju proveru, prijaviti konkretan problem i nastaviti nezavisan posao.

Zadržati jasne odgovornosti i male fajlove. Bez komentara za podučavanje i bez vraćanja obrisanih materijala za učenje. Za nov potreban dizajnerski materijal pitati korisnika kada se pojavi potreba. Ne uvoditi nove servise, plaćanje ili promene dizajna mimo obima KT2.

## Izvedene odluke i lokalne provere

- Server koristi Relic 1.2.0 i PostgreSQL 17. SQL migracija i seed se primenjuju tokom prvog pokretanja. Compose i analiza rade i u čistom izvozu izvora, bez lokalnog Flutter keša. To je provera pakovanja lokalne verzije.
- Zaštita je u transakciji po salonu i jedinstvenim indeksima. Od dva zahteva istog klijenta uspeva jedan, a pri dve paralelne prijave i jednom slobodnom frizeru samo jedna prijava prelazi u „Pozvan”. Zastarela revizija dobija konflikt.
- Server je potvrdio zabranu obe akcije osoblja za klijenta i pristupa tuđoj prijavi. Odgovor za klijenta uključuje njegove prijave i zbir reda. Liste se dohvaćaju po stabilnom rednom broju sa ograničenjem i cursor-om.
- Posle restarta testnog servera i baze ostali su sačuvani status `completed`, revizija 2 i važeća sesija osoblja. Kratak TTL od 8 sekundi je potvrđen odvojeno. Gašenje izdvojenog servera vratilo je poruku o nedostupnosti u konačnom roku.
- Android build iz radnog projekta sa limitom 120 poslao je napomenu od 80 znakova. Stvarni server iz izolovane kopije sa limitom 60 odbio je zahtev, a mobilna forma je prikazala „Napomena može imati najviše 60 znakova.” Isti rezultat je potvrđen zasebnom proverom klijentskog adaptera.
- Android koristi adapter za Android Keystore. Windows koristi Flutter kanal i direktni Windows Credential Manager jer bi Windows dodatak zahtevao sistemsku podršku za simboličke veze. Web koristi HttpOnly cookie i CSRF proveru.
- Web je potvrđen u pregledaču za prijavu osoblja, obnovu sesije posle reload-a i odjavu. Test za Windows na pokrenutoj aplikaciji potvrdio je pogrešnu ulogu, prijavu, obnovu i odjavu. Android test je potvrdio isti tok prijave, obnove i odjave na emulatoru. Obnova u nativnim testovima ponovo kreira aplikaciju i čita stvarno platformsko skladište.
- Prošlo je svih 41 postojećih KT1 funkcionalnih testova i završna Flutter analiza. Android, Windows i web buildovi su uspešni.
- Timski `main` je pre KT2 obuhvatio KT1 kroz `dc6f934`. Verzija za odbranu svake kontrolne tačke određuje se prema stanju grane na njenom roku.

## Tehničke reference

- [Relic 1.2.0](https://pub.dev/packages/relic/versions/1.2.0)
- [HTTP paket za više platformi](https://pub.dev/packages/http)
- [PostgreSQL zaključavanje redova](https://www.postgresql.org/docs/17/explicit-locking.html)
- [OWASP heširanje lozinki](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)
- [Flutter secure storage](https://pub.dev/packages/flutter_secure_storage) i [Windows Credential Manager](https://learn.microsoft.com/en-us/windows/win32/api/wincred/nf-wincred-credwritew)
