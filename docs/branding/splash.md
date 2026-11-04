# Početni ekran Frizeraja

Referenca: `splash-reference.png`. Originali iz korisnikovog `friz.zip` su u
`friz-originals/`. Kompletna referentna slika nije Flutter asset i ne prikazuje
se kao pozadina preko ekrana.

## Delovi ekrana

Implementacija je u `packages/ui/lib/src/startup`:

| Fajl | Odgovornost |
| --- | --- |
| `splash_background.dart` | Flutter gradijent i Bezier putanje krem/koralnog talasa |
| `splash_branding.dart` | Raspored simbola i natpisa uz očuvane proporcije |
| `splash_wordmark.dart` | Natpis iz zasebnog PNG-a i nezavisna Flutter tačka |
| `splash_error_panel.dart` | Čitljiva početna greška i dugme za ponovni pokušaj |
| `splash_screen.dart` | Prilagođavanje telefonu, desktopu i horizontalnom ekranu |
| `startup_gate.dart` | Prikaz do prvog uspešnog učitavanja |
| `splash_reveal_clipper.dart` | Kružna maska koja otkriva sadržaj iz centra indikatora |

Pozadina, oba talasa i tačka su Flutter elementi. Simbol i beli natpis koriste
odvojene transparentne PNG materijale iz ZIP-a. Tačka iz PNG natpisa isključena
je isecanjem prikaza, a zatim je nacrtana zasebno; originalni fajl ostaje isti.
Svaki od ovih elemenata može kasnije dobiti sopstvenu animaciju položaja,
veličine ili providnosti. Brending prati referencu; ispod natpisa se tokom
učitavanja vrti ugrađeni Flutter `CircularProgressIndicator` (28 dp, koralni,
debljina linije 3 dp, blag krem prsten). Pri početnoj grešci indikator se skriva,
a prikazuje retry.

Za animaciju pojedinačnih sečiva ili slova potreban je dodatni SVG sa razdvojenim
objektima, odnosno font ili vektorski natpis. ZIP sadrži PNG izvoze, pa su oni
trenutno jedinice za animaciju simbola i slova kao celine.

## Učitavanje i navigacija

Obe aplikacije u `app.dart` povezuju `QueueState` sa `StartupGate`:

1. Dok prvo učitavanje traje, gate prikazuje splash.
2. Početna greška ostavlja splash sa srpskom porukom i „Pokušaj ponovo”.
3. Prvi `LoadPhase.data` otvara postojeći ruter, uključujući direktan URL detalja.
4. Kasnija učitavanja koriste loading/error prikaze otvorene aplikacije i ne
   vraćaju početni ekran.

Prazan, uspešno učitan red takođe otvara aplikaciju. Uvod se prikazuje najmanje
1,6 sekundi od prvog Flutter layout-a, da brz odgovor fake adaptera (550 ms) ne
preskoči dizajnirani ekran. Aplikacija se otvara kada su završeni i uvod i
učitavanje. Duže učitavanje nije ograničeno tajmerom.
Trajanje je podesivo kroz `minimumSplashDuration` na aplikaciji, odnosno
`minimumDisplayDuration` na gate-u. Funkcionalni testovi koriste `Duration.zero`,
a poseban test proverava minimalno trajanje i brze podatke.

Kada su podaci spremni i istekne minimalni uvod, sledi izlaz od 2100 ms.
Prvih približno 900 ms krem talas klizi ulevo, a koralni udesno. Posle kratkog
predaha (oko 100 ms), iz stvarnog
položaja loading indikatora širi kružna maska i otkriva postojeći ruter.
Brending istovremeno bledi. Sadržaj ostaje iste veličine i čuva svoje stanje;
dodiri i semantika sadržaja omogućavaju se tek kada je prelaz završen.
Sistemsko podešavanje za smanjene animacije preskače izlaznu animaciju.

Na Androidu sistem pre pokretanja Flutter engine-a prikazuje tamnoplavu pozadinu
i transparentni simbol. Potom Flutter crta kompletan raspored sa talasima i
natpisom. Android 12+ ima eksplicitne resurse u `values-v31` i `values-night-v31`.
`tools/generate_icons.ps1` pravi potrebne density verzije native simbola bez
promene odnosa stranica. `launch_logo_safe.xml` dodaje praznu ivicu: simbol od
144 dp dobija platno od 288 dp da bi stao u kružnu masku Androida 12+.
Dimenzije prate [zvaničnu Android dokumentaciju](https://developer.android.com/develop/ui/views/launch/splash-screen/).

## Pregledi i provere

Pokreni iz root-a:

```powershell
flutter test packages/ui/test apps/mobile/test apps/backoffice/test
flutter test tools/preview_ui_test.dart
```

PNG pregledi su u `docs/previews`: `splash-mobile`, `splash-desktop`,
`splash-landscape`, `splash-error` i `splash-error-landscape`.
Proveravaju se i izostanak overflow-a, početni retry, očuvanje detalja iz URL-a
i odsustvo povratka na splash pri običnom osvežavanju.
