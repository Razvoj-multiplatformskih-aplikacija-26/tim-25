# Windows demonstracija Frizeraja

## Pokretanje

Iz glavnog foldera projekta:

```powershell
flutter pub get
cd apps/backoffice
flutter run -d windows
```

U Android Studiju alternativa je posebna Flutter konfiguracija sa entrypoint-om
`apps/backoffice/lib/main.dart` i uređajem Windows desktop.
Mobilna konfiguracija koristi drugi entrypoint i Android emulator.

## Redosled pokazivanja

1. Pokaži pregled sa 17 početnih prijava i panel „Frizeri”. To su nezavisni
   memorijski podaci osoblja; mobilna aplikacija ne deli njihovu živu memoriju.
2. Strelicom nadole izaberi prvu prijavu. Desno se otvara Borisovo farbanje
   na čekanju. Sledećom strelicom izaberi pozvanu prijavu za Studio Vračar.
3. Drži Ctrl, pritisni Enter i zatim pusti tastere: očekivani status je „U toku”.
   Ista akcija postoji i na dugmetu „Započni uslugu (Ctrl+Enter)”.
4. Ponovi Ctrl+Enter: očekivani status je „Završen”. To su dve akcije osoblja.
5. Ctrl+R osvežava podatke; izabrana prijava i sačuvana promena ostaju.
6. Suzi prozor ispod približno 900 px: tabela prelazi u listu i izabrani ID
   ostaje isti. Ponovo proširi prozor i pokaži bočni detalj.
7. Iz menija „Demo kontrole” izaberi grešku. Pokaži „Pokušaj ponovo”.
   Zatim pokaži prazan odgovor i povratak svih podataka posle osvežavanja.

Za ceo prolaz samo tastaturom koristi Tab/Shift+Tab za kontrole i Enter/Space
za njihovu aktivaciju. Pregled podržava strelice, Ctrl+R, Ctrl+Enter i Esc;
vidljiv okvir označava fokus pregleda.

## Scenarij automatske dodele

U početnom stanju otvori „Frizeri” i promeni Markovu dostupnost u „Radi”.
On radi šišanje: Filip dobija poziv, dok Boris koji ranije čeka farbanje ostaje
u redu. Pokreni i završi Filipovu uslugu i pokaži sledeću kompatibilnu dodelu.
Nedolazak druge pozvane prijave traži potvrdu.

Za vraćanje celog početnog demo stanja uradi hot restart velikim `R` u terminalu
koji pokreće Flutter ili ponovo pokreni aplikaciju. Obično osvežavanje podataka
ne vraća seed i ne briše promene.

## Šta umeš da objasniš uz demonstraciju

- Ekran šalje događaj Bloc-u, a repo koristi zajednička domenska pravila.
- Promena širine menja prikaz, dok izabrani ID ostaje u `QueueState`.
- Frizer je zauzet već kad je prijava pozvana.
- Najraniji kompatibilni klijent ne mora biti prvi klijent celog reda.
- Za KT1 nema servera, baze i stvarnog prijavljivanja korisnika.

Prvo pokretanje tokom provere 4.11.2026. bilo je blokirano Windows Application
Control politikom. Kasnije standardno `flutter run -d windows --no-pub`
uspešno je pokrenulo debug aplikaciju. Tokom provere nisu menjana bezbednosna
podešavanja; uzrok promene odluke politike nije utvrđen.

Native provera je potvrdila strelice, početak/završetak preko dugmadi i sužen
prikaz uz očuvan izbor. Boris je fizičkom tastaturom potvrdio Ctrl+Enter:
pozvana prijava prešla je u „U toku”. Potvrdio je i da Ctrl+R radi.
Automatizovani unos nije pouzdano preneo Ctrl kombinaciju na Windows prozoru;
widget testovi i web provera ovih prečica prolaze.
