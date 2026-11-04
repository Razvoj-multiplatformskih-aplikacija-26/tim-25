# KT1 — evidencija provere

Najnovija kompletna provera prema originalnim DOCX kriterijumima završena je
4.11.2026: [izveštaj sa svih 42 provere i preostalim koracima](KT1-provera-2026-11-04.md).
Stariji odeljci ispod predstavljaju istoriju prethodnih provera.

Dopuna 4.11.2026: native Windows aplikacija je uspešno pokrenuta. Provereni su
izbor strelicama, početak i završetak usluge dugmadima i prelaz tabela → lista
uz očuvan izbor. Boris je fizičkom tastaturom potvrdio Ctrl+Enter za početak
usluge i rad prečice Ctrl+R. Detalji i snimci
su u najnovijem izveštaju, a [redosled demonstracije ovde](windows-demonstracija.md).

Datum: 31.10.2026. Okruženje: Windows, Flutter 3.47.7 stable, Dart 3.13.5.

## Potvrđeno izvršavanjem

- `flutter pub get` u root-u: uspešno; jedinstveni workspace lockfile.
- `flutter analyze`: **No issues found**.
- Zajednički skup `flutter test packages/domain/test packages/use_cases/test packages/blocs/test apps/mobile/test apps/backoffice/test`: **26 testova prošlo**.
- `flutter build windows` iz backoffice-a: uspešan release build.
- `flutter build web` iz backoffice-a: uspešan build, uključujući Wasm dry run.
- `flutter build apk --debug` iz mobile-a: uspešan build posle podešavanja NDK-a.
- Windows release aplikacija zaista je pokrenuta: vizuelno provereni tabela,
  desni panel detalja, izbor pozvane prijave, naziv i Frizeraj ikonica.
- Widget test stvarno proverava Ctrl+Enter početak/završetak, Ctrl+R i prelazak
  široko → usko → široko uz očuvanje izabranog zapisa.
- Widget testovi proveravaju mobilnu formu i uspešnu dodelu, srpsku domensku
  grešku napomene, potvrdu/odustajanje od otkazivanja, grešku/retry i praznu listu.
- ADB je posle podizanja emulatora prijavio `emulator-5554 device`.
- `flutter run -d emulator-5554 --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk`:
  instalacija uspešna, proces pokrenut, Flutter engine učitan i Dart VM Service dostupan.
  ADB je potvrdio `com.example.mobile/.MainActivity` kao resumed aktivnost.
- Flutter hot reload je uspešno završen na emulatoru; zatim je CLI odvojen
  komandom `d`, tako da aplikacija ostaje pokrenuta za ručni pregled.

## Granice i preostala ručna demonstracija

- Android build i pokretanje potvrđeni su alatima, ali interaktivna vizuelna
  demonstracija na emulatoru nije završena posle zaustavljanja UI alata.
- Web UI nije vizuelno potvrđen. Automatski Computer Use alat zaustavio je
  upravljanje zato što nije mogao dovoljno pouzdano da utvrdi trenutni URL Chrome-a.
  Posle te poruke nije nastavljeno upravljanje aplikacijama.
- Čist Git klon nije proveren: početna fascikla nema `.git`, remote ni istoriju.
  Nije izvršen commit ili push. Originalni DOCX zahtevi i profesorov ZIP nisu bili dostupni.
- Prihvatanje teme mora potvrditi profesor; kod to ne potvrđuje.

## Lokalni problemi okruženja

Prvi `flutter run -d emulator-5554` nije pokrenuo aplikaciju jer je emulator još
bio offline. Naknadni ADB pregled pokazao je da se uređaj podigao.

Prvi APK build je pao zato što Flutterov podrazumevani NDK 28.2.13676358 nije
instaliran, a novi lokalni sdkmanager wrapper nije uspeo da ga automatski doda.
Pregledom stvarnog SDK-a potvrđen je već instalirani NDK 30.0.16248370; projekat
ga sada eksplicitno koristi, a potrebna verzija je navedena u README-u.
Android SDK Platform 36 je tokom narednog build-a automatski preuzeta kroz Gradle.

Ponovljeni web debug start uspešno je poslužio aplikaciju na
`http://127.0.0.1:5174` posle uklanjanja read-only atributa.

Prvi web debug start nije mogao da ukloni generisani
`apps/backoffice/build/flutter_assets` direktorijum. U njemu su pronađeni
OneDrive reparse point i read-only atributi. Read-only je uklonjen samo sa
generisanih direktorijuma ispod tog build-a, pa je start ponovljen. Izgrađeni
release web može da se pregleda i pomoću opcionog lokalnog servera:

```powershell
# Iz root-a, uz već instaliran Node.js:
node tools/serve_web.mjs
# Otvoriti http://127.0.0.1:5173
```

Za odbranu je praktičnije klonirati projekat u običnu lokalnu fasciklu izvan
OneDrive-a. Ovaj problem nije razlog za promenu domenskog modela ili SDK verzije.

## Dopuna: osvežen izgled oba klijenta

- Ujednačena topla svetla podloga, tamnozelena paleta i lokalno upakovan Roboto
  font sa originalnom licencom u `packages/ui/assets/fonts`.
- Nove kartice salona/prijava, zaglavlje početne strane, oznake svih šest stanja,
  pregled broja klijenata i preglednija tabela sa odvojenim panelom detalja.
- Mobilne akcije prijave i otkazivanja ostaju dostupne dok se sadržaj skroluje.
- Posle redizajna: `flutter analyze` bez problema; svih sedam postojećih widget
  testova prolazi. Domen, repozitorijumi i Bloc nisu menjani.
- `flutter test tools/preview_ui_test.dart` generiše pet stvarno renderovanih
  prikaza (telefon: početna/detalj/forma; backoffice: široki/uski prozor).
  PNG prikazi su pregledani; renderovanje nije prijavilo overflow.
- Web i Android buildovi sa novim izgledom su uspešni; novi APK je instaliran i
  pokrenut na postojećem emulatoru kroz Flutter CLI.
  `flutter build windows --debug` takođe je uspešno završen sa novim izgledom.
  Pri osvežavanju Android APK-a
  ponovio se OneDrive read-only problem; atribut je uklonjen samo sa generisanih
  direktorijuma ispod `apps/mobile/build`, pa je build ponovljen.

## Dopuna: korisnikov logo

- Originalni transparentni PNG sačuvan je bez izmene kao
  `packages/ui/assets/branding/logo.png`; SHA-256 odgovara poslatom fajlu.
- Zajednički `BrandMark` prikazuje taj asset: zaglavlja oba klijenta, mobilni
  baner i prazni prikazi. Mobilne podstrane imaju logo uz naziv ekrana.
- Iz istog originala izvedeni su Android launcher i splash PNG-ovi po gustinama,
  Windows ICO sa sedam veličina, web favicon, instalacione i maskable ikonice.
  Generator ne zavisi od Downloads fascikle. Logo je dodat i u README.
- Workspace test runner sada eksplicitno uključuje oba klijenta i Material
  assete, da root testovi prikupe i zajedničke slike.
- Analiza bez problema; svih sedam widget testova i renderovanje pet pregleda
  prolaze. Render alat čeka dekodiranje slike i proverava da je učitana.
- Android debug, Windows debug i web buildovi sa logom su uspešni.

## Dopuna: zvanična paleta

- Oba klijenta koriste korisnikove HEX vrednosti: navy `#172B4D`, coral
  `#D9685F`, cream `#FAF9F6`, charcoal `#242424` i neutralnu `#F3F4F6`.
  Smernica 70/25/5 i originalna referenca su u `docs/branding`.
- Uklonjena je prethodna zelena paleta iz UI-ja. Naslovi, glavna dugmad i
  navigacija su tamnoplavi; koralna je sitan akcenat. Tekst statusa je taman,
  a stanja se razlikuju i po ikonici i nazivu. Originalni logo nije menjan.
- Android početna pozadina i web manifest/meta boje su usklađeni sa paletom.
- `flutter analyze` bez problema. Sedam widget testova i render alat prolaze;
  pet PNG pregleda je osveženo. Android debug, Windows debug i web buildovi prolaze.

## Refaktor strukture — 1.11.2026.

- Oba `main.dart` fajla imaju samo import i `runApp`. Kreiranje zavisnosti i
  životni ciklus su u `dependencies.dart` i `app.dart`, a rute u `router.dart`.
- Mobilni klijent ima zasebne klase svih pet ekrana i izdvojenu formu;
  uklonjen je tekstualni `view` switch. `MobileScaffold` drži samo zajednički okvir.
- Backoffice ima izdvojene prečice, redosled prikaza, tabelu/listu, pregled
  stanja, panel frizera i detalj. Prezentacioni paneli primaju podatke i callback-e;
  `QueueWorkspace` ih povezuje sa Bloc događajima.
- Tema, boje, srpske poruke i zajednički widgeti su odvojeni u UI paketu.
  Događaji i stanje Bloc-a su u posebnim fajlovima. Poslovna pravila i adapter nisu menjani.
- `flutter analyze`: bez problema. Ceo skup postojećih testova i render
  scenarija: **27 provera prolazi**. Svih pet PNG pregleda ima isti SHA-256 kao
  pre refaktora, uključujući široki/uski backoffice i mobilni detalj/formu.
- Android debug, Windows debug i web buildovi su uspešni sa novim importima.

## Početni splash ekran — 1.11.2026.

- Pregledan je `friz.zip`: pet transparentnih PNG materijala. Originali su u
  `docs/branding/friz-originals`, a izabrani simbol i beli natpis u UI assetima.
  Kopije imaju iste SHA-256 vrednosti kao originali. Referentni screenshot nije
  uključen među runtime assete.
- `packages/ui/lib/src/startup` razdvaja vektorsku pozadinu/talase, simbol,
  natpis sa zasebnom Flutter tačkom, kompoziciju, grešku/retry i startup gate.
- Oba klijenta prikazuju splash do prvog uspešnog učitavanja; naredni refresh
  čuva ekran i direktnu rutu. Prvobitna verzija nije imala dodatni tajmer;
  minimalno trajanje je dodato u ispravci ispod. Nema početne animacije.
- Android native resursi koriste tamnoplavu pozadinu i transparentni simbol,
  uključujući Android 12+ konfiguraciju. PNG se skalira uz očuvanje proporcija.
- Analiza bez problema. Kompletan skup sa novim startup testovima: **30 testova
  prošlo**; posle izdvajanja tačke ponovo su prošli svi pogođeni UI/startup
  testovi i render scenariji (11 testova).
- Vizuelno pregledani prikazi telefona, desktopa i male horizontalne greške.
  Render alat sada generiše deset PNG prikaza (pet ranijih i pet splash varijanti)
  i proverava da nema layout izuzetaka.
- Windows debug i web buildovi konačne kompozicije su uspešni. Android build
  je takođe uspešan, posle uklanjanja poznatih OneDrive read-only atributa iz
  generisanih direktorijuma.
- Dokumentacija i granice buduće animacije: `docs/branding/splash.md`.
- Konačni APK je instaliran i pokrenut na postojećem emulatoru kroz Flutter CLI;
  engine i VM Service su se uspešno pokrenuli. CLI je odvojen komandom `d`.

## Ispravka stvarnog Android pokretanja — 1.11.2026.

- Screenshot korisnika otkrio je odsečen native simbol i prekratak kompletan
  splash. Android 12+ drawable sada ima praznu ivicu za sistemsku masku.
- `StartupGate` čeka i podatke i podesivi uvod od najmanje 1600 ms. Brzo
  učitavanje više ne preskače kompoziciju; duže učitavanje i retry ostaju podržani.
- `flutter analyze` prolazi bez problema; svih 11 pogođenih UI i aplikacionih
  testova prolazi, uključujući proveru brzih podataka i minimalnog trajanja.
- Android debug APK je uspešno izgrađen, instaliran i hladno pokrenut na
  emulatoru API 37. ADB snimak stvarnog Flutter splash-a sa celim simbolom,
  natpisom i talasima: `docs/previews/splash-emulator.png`.

## Čišćenje pre pregleda koda — 1.11.2026.

- Uklonjeno je neiskorišćeno `QueueState.message` polje i njegovo postavljanje.
  Test sekvencijalnih događaja sada čeka stvarnu promenu dostupnosti frizera.
- Uklonjeni su tri trivijalna `example` programa i tri generisana changelog-a
  sa tekstom „Initial version”. Opisi paketa sada navode njihovu odgovornost.
- Manifesti klijenata očišćeni su od generisanih tutorijal komentara; uklonjena
  je neiskorišćena zavisnost `cupertino_icons` i osvežen workspace lockfile.
- `flutter analyze`: bez problema. Svih **30 postojećih testova prolazi**.

## Animirani izlaz splash-a — 1.11.2026.

- Posle minimalnog uvoda i uspešnog učitavanja, izlaz traje 2100 ms: krem talas
  ide ulevo, koralni udesno (oko 900 ms), pa posle kratkog predaha kružna maska
  otkriva aplikaciju iz izmerenog centra loading indikatora (oko 1100 ms).
- Ruter i stanje sadržaja ostaju sačuvani na kraju animacije; dodiri sadržaja
  su blokirani do završetka. Smanjene sistemske animacije preskaču prelaz.
- Analiza prolazi bez problema. Svih 13 pogođenih UI i aplikacionih testova
  prolazi; proveren je i redosled talasi → krug, očuvanje elementa sadržaja,
  blokada ranog dodira i smanjene animacije.
- APK izgrađen i instaliran. Međukadrovi stvarnog hladnog pokretanja potvrđuju
  ceo prelaz: `docs/previews/splash-transition-emulator.png`.

## Home prema korisnikovom prototipu — 1.11.2026.

- Ugrađen je dostavljeni Manrope (400–800, OFL licenca), kao i originalne SVG
  ikonice iz ZIP-a, preko `flutter_svg`. Stari Roboto resursi su uklonjeni.
- Home ima grad, zvono, pretragu naziva/adrese, tri sortiranja, prazna mesta za
  fotografije i zajedničku navigaciju Saloni / Moj red / Profil. Zadržani su
  postojeći domenski saloni, njihove cene i rute detalja/prijave.
- Demo ocene, broj recenzija, udaljenosti i procene čekanja izdvojeni su u mobilni
  prezentacioni fajl. Zvono otvara postojeće prijave; Profil prikazuje fiksnog
  demo klijenta. Nema GPS-a, autentifikacije ni servisa recenzija.
- Analiza: bez problema. Ceo skup sa render alatom: **36 testova prolazi**.
  Posle završnog podešavanja sistemskih ikonica ponovo je prošlo svih osam
  mobilnih testova. Provereni su pretraga, sortiranja, prazna pretraga, zvono,
  navigacija i skrolovanje/otvaranje salona pri širini 320 px.
- Render alat sada učitava Manrope i čeka završetak splash animacije pre snimka
  klijenta. Vizuelno je pregledan `docs/previews/mobile-home.png`, kao i stvarni
  Home na Android emulatoru. Debug APK uspešno je izgrađen, instaliran i pokrenut.
