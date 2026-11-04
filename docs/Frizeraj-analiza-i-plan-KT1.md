# Frizeraj — analiza Rafstorana i plan za KT1

Datum pregleda: 31. oktobar 2026.

## Osnova i granice pregleda

Pregledan je stvarni prilog `Rafstoran-main.zip` iz prethodnog razgovora, raspakovan u `work/rafstoran/Rafstoran-main`. Pregled obuhvata strukturu, konfiguraciju workspace-a, domenske modele i pravila, use case sloj, Bloc, lažne repozitorijume, navigaciju, mobilnu formu, backoffice prikaz, prečice, testove i delove serverske implementacije.

Ovo je analiza izvornog koda. Testovi nisu pokretani i aplikacije nisu vizuelno proverene na uređaju ili u pregledaču; postojanje testa nije dokaz da trenutno prolazi. Službeni DOCX dokumenti nisu dostupni u ovoj radnoj fascikli niti su priloženi dostupnom zapisu prethodnog razgovora. Poređenje sa KT1 zasniva se na korisnikovom prenetom sadržaju, a ne na neposrednom čitanju tih dokumenata.

## 1. Šta profesorov projekat zaista sadrži

Root je Dart pub workspace. `pubspec.yaml` uključuje četiri aplikacije: `mobile`, `backoffice`, `console`, `server`; pakete `domain`, `use_cases`, `blocs`, `ui`, `design_tokens`, `api_contract`, `api_mapping`. Paketi koriste `resolution: workspace`. Deklarisani Dart je `^3.13.0`, a README navodi Flutter 3.47.6. Verzije iz ovog ZIP-a ne treba naslepo menjati ili prepisivati bez provere lokalnog okruženja.

README ima zastareo odeljak „Stanje projekta” koji kaže da se kod tek dodaje. ZIP već sadrži ozbiljnu implementaciju. Takođe navodi Jaspr javni veb, ali takva aplikacija nije prisutna u workspace-u.

### Domen

- `identifiers.dart`: posebni `extension type` identifikatori `ReservationId`, `DiningTableId`, `UserId`.
- `Reservation`: immutable `final class`, final polja, `copyWith`, jednakost i hash.
- `ReservationStatus`: sealed hijerarhija `Pending`, `Confirmed`, `Cancelled`, `Arrived`, `NoShow`. Stanja nose vreme i identitet osoblja gde je potrebno.
- `canTransition`: eksplicitna matrica prelaza; terminalna stanja ne mogu nazad u aktivna.
- `Result<T>`: `Success<T>` ili `Failure<T>` sa `DomainError`, bez oslanjanja na tekst poruke.
- Value objekti za broj osoba, napomenu, ime i telefon; validacija vraća tipizovan rezultat.
- `availability.dart`: računanje slobodnih stolova iz rezervacija drugih gostiju; dodeljuje najmanji odgovarajući slobodan sto, uz deterministički redosled.
- `transitions.dart`: ovlašćenja, otkazivanje dva sata unapred, pravila dolaska i nedolaska. Vreme se prosleđuje funkcijama.
- `OpeningHours`: vremenska zona Europe/Belgrade, pretvaranje u UTC i provera radnog vremena. Testovi obuhvataju i promenu letnjeg vremena.

Ovo su dobri obrasci za Frizeraj. Konkretna pravila o terminima, stolovima i otkazivanju dva sata unapred pripadaju Rafstoranu.

### Use case sloj i repozitorijumi

`use_cases` povezuje domen, repozitorijumske portove i `Clock`. Primer: `CreateReservation` proverava ulogu, parsira termin i delegira upis repozitorijumu; `CancelReservation` koristi zajedničko domensko pravilo.

Važno odstupanje: portovi `ReservationRepository`, `SlotRepository`, `ScheduleRepository` nalaze se u `packages/use_cases/lib/src/ports`, a ne u `domain`. Za Frizeraj preneti KT1 zahtev eksplicitno traži port u domenskom paketu. Pratiti taj zahtev.

### Bloc

`packages/blocs` koristi `bloc` i `equatable` bez Flutter zavisnosti. Postoje `AvailableSlotsBloc`, `MyReservationsBloc`, `ReservationFormBloc`, `DailyScheduleBloc`, `NewReservationBloc`, `CommandPaletteBloc`.

`MyReservationsBloc` obrađuje učitavanje, osvežavanje, otkazivanje i potvrdu prikazane poruke. Ima loading/failure/empty/loaded stanja i razlikuje poslovno odbijanje od tehničke greške. `ReservationFormBloc` poziva domenski parser napomene; ekran šalje događaje i prevodi tipizovanu grešku u poruku.

`DailyScheduleBloc` drži izbor, kursor, raspoložive akcije i zahtev u toku. Brojač `_request` sprečava da zastareo odgovor pregazi noviji prikaz. Dostupne akcije izračunava pozivanjem domenskih funkcija. Prazan raspored predstavlja loaded stanjem sa praznim podacima, što je validno i bez posebne Empty klase.

### Fake podaci

Mobilni `FakeRestaurant` ima podrazumevano kašnjenje od 700 ms, brojač `failingRequests` i `emptyResponses`. Kreiranje koristi zajednička pravila o zauzetosti gosta i dodeli stola. Seed sadrži 11 rezervacija trenutnog gosta, svih pet stanja i dodatne rezervacije drugih gostiju tokom 14 dana.

Backoffice ima sopstveni `FakeSchedule`, svoj seed i simulaciju greške. Aplikacije ne dele živu memoriju i ne sinhronizuju se. To odgovara KT1.

Slabost: oba fake `save` metoda primaju `from`, ali ga ne proveravaju. Direktno menjaju element pronađen po ID-u; nema ni obrade nepostojećeg indeksa. Ovo nije obrazac za zaštitu od konkurentnih promena. Takođe ne treba pretpostaviti da `final List` znači nepromenljivu kolekciju: neke Bloc liste su prosleđene bez zaštitne kopije.

### Mobilni UI

Postoje početni prikaz termina, detalj termina, forma rezervacije, lista mojih rezervacija i poseban detalj rezervacije. `go_router` koristi shell sa granama i rutama detalja. Forma šalje događaje, prikazuje greške na srpskom, blokira dugme tokom slanja i nudi retry. Otkazivanje ima dijalog potvrde. Debug meni omogućava simulaciju greške i praznog odgovora. Prisutan je zajednički UI paket, tema, fontovi, grafički znak i platform assets za ikonicu/splash.

Jedna granica primera: neke rute zavise od `state.extra` i preusmeravaju na početak ako ono ne postoji. U Frizeraju je bolje da detalj može da se obnovi iz ID-a u URL-u.

### Backoffice UI

Široki prikaz je mreža stolovi × vreme, sa desnim panelom detalja širine 340. Ispod praga od 840 prikazuje listu; izabrani ID je u Bloc stanju. Na uskom prikazu detalj se otvara u donjem panelu. Postoje akcije potvrde, dolaska, nedolaska, otkazivanja i unosa gosta bez naloga.

Tastatura je stvarno implementirana: strelice pomeraju kursor, Enter otvara zapis, C potvrđuje, A beleži dolazak, D nedolazak, X otkazuje, Esc zatvara izbor. Postoje paleta komandi i pregled prečica. Mreža koristi FocusNode i obradu tastera, a prikazi imaju Semantics oznake.

Pri zatvaranju detalja u donjem panelu kod eksplicitno čisti izbor. Zato ne treba zaključiti da je izbor sačuvan u baš svakom toku samo zato što postoji test za resize.

### Server i ono što još nije povezano

Server nije samo placeholder: postoje Relic handlers, PostgreSQL adapter, migracija, seed, konfiguracija i Docker compose. Baza ima exclusion ograničenja protiv preklapanja rezervacija istog stola i istog gosta. PostgreSQL adapter ponavlja izbor stola posle konflikta i pri promeni statusa proverava prethodno stanje.

Mobilna i backoffice aplikacija ipak koriste fake podatke; server poziva posebna konzola. Nema implementiranog Jaspr javnog sajta u ovom ZIP-u. U pregledanim klijentima nema trajnog offline reda otkazivanja. Korisničke uloge i prosleđivanje aktera nisu dokaz kompletne produkcijske autentifikacije: pojedini read handleri direktno vraćaju podatke bez provere vlasništva u samom handleru.

### Testovi

Postoje domenski testovi granica vrednosti, prelaza, dostupnosti i vremena; use case testovi sa fiksnim satom; Bloc testovi; mobilni widget testovi za loading/error/empty/data, grešku napomene i otkazivanje; backoffice widget testovi za C/X prečice, rad samo tastaturom, resize sa očuvanjem izbora, deep link i unos gosta. Server testovi pokrivaju konkurentne rezervacije i konkurentne promene statusa, ali zahtevaju bazu.

Zaključak pregleda testova: pokriveni su korisni scenariji, ali nisu dokaz potpune ispravnosti svih putanja niti su pokrenuti u ovom pregledu.

## 2. Precizna struktura Frizeraja za KT1

```text
frizeraj/
  pubspec.yaml
  README.md
  apps/
    mobile/lib/
      app.dart, router.dart, dependencies.dart
      data/fake_queue_repository.dart, seed.dart
      screens/salons_screen.dart, salon_detail_screen.dart
      screens/join_queue_screen.dart, my_entries_screen.dart
      screens/queue_entry_detail_screen.dart
    backoffice/lib/
      app.dart, router.dart, dependencies.dart, shortcuts.dart
      data/fake_queue_repository.dart, seed.dart
      screens/queue_screen.dart
      widgets/queue_table.dart, queue_list.dart, entry_detail_panel.dart
      widgets/barber_status_panel.dart
  packages/
    domain/lib/src/
      identifiers.dart, result.dart, errors.dart, clock.dart
      models/queue_entry.dart, queue_status.dart, barber.dart
      models/salon.dart, service.dart, opening_hours.dart, user.dart
      rules/join_queue.dart, transitions.dart, assignment.dart, queue_position.dart
      ports/queue_repository.dart
    blocs/lib/src/
      my_entries/, join_queue/, salon_queue/
    ui/lib/src/
      theme.dart, domain_error_messages.dart, widgets/
```

Za KT1 su dovoljni `domain`, `blocs`, `ui` i dve aplikacije. `use_cases` može da se doda kada postoji stvarna potreba; nije uslov da se reprodukuje svaki paket profesorovog kasnijeg primera. Server i Jaspr dolaze u kasnijim fazama.

### Domenski model i odluke

Glavni entitet je `QueueEntry`: tipizovani ID, salon, klijent, usluga, vreme prijave, status i podaci dodele. Posebni ID tipovi: `QueueEntryId`, `SalonId`, `ClientId`, `BarberId`, `ServiceId`.

Predlog je sealed status sa podacima dodele u `Called` i `InProgress`, da pozvan klijent ne može postojati bez frizera. Stanja: Waiting, Called, InProgress, Completed, Cancelled, NoShow. Kolekcije salona, usluga i veština frizera moraju imati nepromenljive kopije.

Predloženi prelazi: Waiting → Called ili Cancelled; Called → InProgress ili NoShow; InProgress → Completed. Terminalna stanja ne prelaze dalje. Otkazivanje klijenta dozvoliti dok čeka, prema trenutnom README-u; proširenje na Called je posebna poslovna odluka, ne podrazumevana mogućnost.

Aktivna prijava obuhvata Waiting, Called i InProgress. Frizer je zauzet i tokom Called, a ne tek tokom InProgress. Status frizera razlikuje rad/odsustvo/pauzu; zauzetost se izvodi iz aktivnih dodela kako dve odvojene vrednosti ne bi postale neusaglašene.

### Pravila koja moraju biti zajednička

1. `validateJoinQueue`: salon radi, usluga pripada salonu i postoji frizer koji je pruža, klijent nema drugu aktivnu prijavu u tom salonu. Vraća tipizovanu grešku, npr. SalonClosed ili ActiveEntryAlreadyExists.
2. `assignNextCompatible`: proverava da frizer radi i nema Called/InProgress dodelu, filtrira Waiting prijave istog salona po usluzi, bira najmanji redosled prijave i vraća novu dodelu.
3. Funkcije prelaza proveravaju status i ulogu; klijent otkazuje samo sopstvenu prijavu.
4. `queuePosition`: računa poziciju iz liste prijava. To je pozicija u redu, a ne obećanje da će svi biti usluženi tim redom: različiti frizeri pružaju različite usluge.

Za jednaka vremena prijave predvideti monotoni redni broj u salonu; za KT1 ga generiše repo. U kasnijem serveru redosled određuje server. Korisnik ne bira vreme usluge i nema slotova.

### Automatska dodela i granica odgovornosti

Domenska funkcija odlučuje ko je sledeći na osnovu prosleđenog snimka reda. Repozitorijum obezbeđuje da provera i upis budu jedna operacija. UI ne bira klijenta, ne menja status direktno i ne upisuje proizvoljnog frizera.

U KT1 fake repo simulira ovu operaciju: najpre odradi kašnjenje/grešku, zatim u jednom neprekinutom delu proveri najnovije podatke, pozove domensko pravilo i sačuva novi snimak. Između konačne provere i upisa nema `await`. Alternativno sve izmene prolaze kroz isti red operacija. Samo isključeno dugme u UI nije zaštita.

Dodela se pokreće po prijavi novog klijenta, vraćanju frizera na rad, završetku usluge i evidentiranju nedolaska. Ako je više frizera slobodno, obrada ide determinističkim redosledom, svaki put nad već izmenjenim redom. Jedan klijent ne može dobiti dva frizera.

KT1 ne dokazuje konkurentnost između uređaja jer nema zajednički server. Kasnije isti postupak mora biti transakcija na serveru sa zaključavanjem/proverom i ograničenjima baze. Ne prepisivati Rafstoranov exclusion constraint za vremenske intervale u model koji nema termine.

### Bloc i ekrani

- `MyEntriesBloc`: učitavanje mojih prijava, retry, otkazivanje; Loading/Failure/Empty/Loaded i zauzetost konkretne akcije.
- `JoinQueueBloc`: izbor usluge i napomena, domen validacija, slanje, poslovno odbijanje, tehnička greška i uspeh. Primer poruke: „Već imaš aktivnu prijavu u ovom salonu.”
- `SalonQueueBloc`: ceo red, statusi frizera, izabrani ID, početak/kraj usluge, nedolazak i promena dostupnosti. Izbor se čuva u stanju i posle resize-a.

Port `abstract interface class QueueRepository` je u `domain`. Treba nuditi operacije poput učitavanja snimka, prijave, otkazivanja, početka/završetka usluge, nedolaska i promene dostupnosti. Izbegavati generički `save` koji prihvata proizvoljno stanje. Sve izmene proveravaju najnoviji snimak.

Mobilna aplikacija ima rute za salone, detalj salona, formu prijave, moje prijave i detalj po ID-u. Seed: najmanje 10 prijava trenutnog klijenta kroz istoriju, svih šest stanja i prijave drugih klijenata za pravila dodele. Ne praviti 10 aktivnih prijava istog klijenta u jednom salonu samo zbog zahteva o broju zapisa.

Backoffice: tabela reda levo, detalj desno, panel frizera; na uskom prozoru lista uz očuvan izbor. Strelice/Enter za izbor, Ctrl+R za osvežavanje, Ctrl+Enter za dozvoljeni početak/završetak uz jasno naznačenu akciju; prečice ne smeju da rade tokom unosa u formu. Nedolazak i otkazivanje imaju potvrdu. Vidljiv fokus je obavezan.

Svaka aplikacija dobija sopstvenu instancu fake repoa. Oba klijenta koriste iste domenske funkcije i Bloc paket, bez međusobne sinhronizacije. Debug kontrole demonstriraju sledeću grešku, prazne podatke i ponovno učitavanje bez menjanja poslovnih pravila.

## 3. Redosled implementacije i odbrane

1. Root workspace i dva pokretljiva Flutter klijenta; proveriti root `flutter pub get`.
2. Domen: ID tipovi, immutable modeli, šest stanja, tipizovane greške, prijava, prelazi, kompatibilna dodela i pozicija. Testirati najranijeg kompatibilnog, zauzetog frizera, duplu prijavu i nedozvoljene prelaze.
3. Fake repo sa nezavisnim podacima, kašnjenjem, greškom sledećeg zahteva i atomarnom dodelom u memoriji.
4. Pravi Bloc sa Equatable stanjima; smisleni testovi greške/retry i uzastopnih zahteva za dodelu.
5. Mobilni lista–detalj–forma tok, srpske poruke, potvrda otkazivanja, tema i ikonica.
6. Backoffice tabela–detalj, početak/kraj, nedolazak, dostupnost, tastatura i responsive lista.
7. Provera Android uređaja/emulatora, Windows i web pokretanja, resize-a i čistog klona; README sa tačnim koracima.
8. Pred odbranu oba člana menjaju jedno domensko pravilo i demonstriraju njegov uticaj u obe nezavisne aplikacije.

Primer ključnog scenarija: prvi klijent traži farbanje, drugi šišanje; slobodni frizer radi samo šišanje. Sistem bira drugog, prvi ostaje na čekanju. Posle početka usluge drugi klijent i frizer su zauzeti. Završetak automatski otvara sledeću kompatibilnu dodelu. Ponovljeni zahtev ne sme prepisati postojeću dodelu.

## 4. Sačuvani kontekst projekta

- Predmet RAF Razvoj multiplatformskih aplikacija, IV godina, projekat u paru.
- Boris Bošković, SI 114/24, GitHub CoolGitGuy; Filip Karadžić, SI 131/24, GitHub StaticVoid-0.
- Tema: Frizeraj, red čekanja bez zakazivanja; profesor je prethodnu booking temu ocenio kao previše sličnu Rafstoranu. Status prihvatanja nove teme nije potvrđen.
- Glavni entitet prijava u red, uloge klijent i osoblje, šest navedenih stanja, jedna aktivna prijava po klijentu i salonu, prijava tokom radnog vremena, automatski najraniji kompatibilni klijent, zaštita od dvostruke dodele i konačna provera na serveru.
- Konačni sistem: Flutter Android/iOS klijent, Flutter Windows/web backoffice, Dart server Relic/PostgreSQL, Jaspr javni SEO veb i zajednički Dart domen. Javni sadržaj: saloni, usluge, cene, radno vreme, red i eventualna procena čekanja.
- Offline otkazivanje je plan za kasniju fazu: zahtev ostaje lokalno, šalje se po povratku mreže i server može da ga odbije zbog promenjenog stanja.
- KT1: isključivo memorijski fake podaci; zasebno stanje svake aplikacije; nema auth/servera. Četiri oblasti po 5 bodova: mobilna, domain, blocs/repo, backoffice.
- KT1 rok: 4. novembar 2026. u 23:59:59 na GitHub main; automatsko preuzimanje 5. novembra u 00:00. Oba člana brane ceo sistem. Tema mora biti prihvaćena ili prihvaćena uz komentar pre odbrane.
- Prema prenetoj specifikaciji: KT2 u novembru server/baza/korisnici 15 bodova; KT3 16. decembra offline/uređaj 20; KT4 u januaru javni veb/test/isporuka 15; ispit 30.
- Riverpod i Supabase bili su raniji predlozi. KT1 obavezno koristi pravi Bloc, Equatable i fake repo; oni nisu zamenjeni tim ranijim predlozima.
- Nedostajući originali: `Projektni zadatak - Razvoj multiplatformskih aplikacija.docx`, `KT1 - Dva klijenta nad istim domenom.docx`. Tri README priloga drugih timova i fotografije nisu pregledani u ovoj sesiji.
- U radnoj fascikli nije pronađen postojeći Frizeraj repozitorijum. Profesorov primer je raspakovan isključivo za analizu, nije preimenovan u korisnikov projekat.
