# tim-25
# Frizeraj – Sistem za upravljanje redom čekanja u frizerskim salonima

Frizeraj je multiplatformski sistem za digitalno upravljanje redom čekanja u frizerskim salonima koji rade bez prethodnog zakazivanja. Klijenti putem mobilne aplikacije pregledaju salone, dostupne usluge i trenutno stanje reda čekanja, prijavljuju se u red i prate svoju poziciju i status prijave. Kada se frizer oslobodi, server automatski određuje sledećeg klijenta na osnovu redosleda prijavljivanja i usluga koje frizer može da obavi. Osoblje putem backoffice aplikacije prati red čekanja, upravlja dostupnošću frizera, poziva dodeljene klijente i evidentira završetak usluga.

## Tim

| Ime i prezime  | Broj indeksa | GitHub nalog                                    |
| -------------- | ------------ | ----------------------------------------------- |
| Boris Bošković | SI 114/24    | [CoolGitGuy](https://github.com/CoolGitGuy)     |
| Filip Karadžić | SI 131/24    | [StaticVoid-0](https://github.com/StaticVoid-0) |

## Zahtevi za temu

Glavni pojam sistema je **prijava klijenta u red čekanja**.

### 1. Uloge

Sistem koriste klijenti i osoblje frizerskih salona. Klijenti pregledaju usluge i trenutno stanje reda čekanja, prijavljuju se u red, prate svoju poziciju i mogu da otkažu sopstvenu prijavu. Osoblje prati red čekanja, upravlja dostupnošću frizera, pokreće pozivanje sledećeg klijenta i evidentira početak i završetak pružanja usluge.

### 2. Stanja

Prijava u red čekanja prolazi kroz stanja: **na čekanju, pozvan, u toku, završen, otkazan i nije se pojavio**. Nakon prijavljivanja klijent čeka svoj red. Kada sistem pronađe odgovarajućeg slobodnog frizera, klijent prelazi u stanje „pozvan“, zatim „u toku“ kada usluga započne i „završen“ nakon završetka. Klijent može da otkaže prijavu dok čeka, a osoblje može da označi da se pozvani klijent nije pojavio.

### 3. Pravila

Klijent može imati samo jednu aktivnu prijavu u istom salonu, a prijavljivanje je dozvoljeno samo tokom radnog vremena salona. Kada se frizer oslobodi, sistem bira najranije prijavljenog klijenta čiju uslugu taj frizer može da obavi. Jedan frizer može istovremeno biti dodeljen samo jednom klijentu, a jedan klijent ne može biti dodeljen dvojici frizera. Pošto redosled i dostupnost frizera zavise od prijava drugih korisnika, konačnu proveru i dodelu obavlja server.

### 4. Rad bez mreže

Klijent može da zatraži otkazivanje svoje prijave u red čekanja i bez internet konekcije. Zahtev se čuva lokalno i automatski šalje serveru nakon ponovnog uspostavljanja veze. Server proverava da li je otkazivanje i dalje dozvoljeno, jer je klijent u međuvremenu mogao biti pozvan ili je usluga već započeta. Aplikacija zatim prikazuje rezultat sinhronizacije.

### 5. Posao za osoblje

Osoblje koristi backoffice aplikaciju za pregled i upravljanje redovima čekanja i dostupnošću frizera. Na većem ekranu prikazuju se svi prijavljeni klijenti, njihove pozicije i statusi, kao i trenutno slobodni i zauzeti frizeri. Osoblje može da pokrene automatsku dodelu sledećeg klijenta, označi početak i završetak usluge, evidentira nedolazak i prati promene stanja reda čekanja.

### 6. Javni sadržaj

Javni veb omogućava posetiocima da bez prijavljivanja pregledaju frizerske salone, njihove usluge, cenovnike, radno vreme i trenutno stanje reda čekanja, uključujući procenjeno vreme čekanja. Informacije o salonima i uslugama dostupne su internet pretraživačima kako bi korisnici mogli da pronađu odgovarajući salon pre instaliranja aplikacije.

## Delovi sistema

| Deo                | Korisnici             | Tehnologija       | Platforme     |
| ------------------ | --------------------- | ----------------- | ------------- |
| Mobilna aplikacija | Klijenti              | Flutter           | Android, iOS  |
| Backoffice         | Osoblje salona        | Flutter           | Windows, veb  |
| Javni veb          | Svi posetioci         | Jaspr             | Pregledač     |
| Server             | Ostali delovi sistema | Relic, PostgreSQL | Linux         |
| Domenski paket     | Svi delovi sistema    | Dart              | Sve platforme |

Svi delovi sistema koriste zajednički domenski paket napisan u Dartu, koji sadrži modele, stanja i poslovna pravila. Server čuva podatke, proverava ovlašćenja i upravlja automatskom raspodelom klijenata, vodeći računa o redosledu prijavljivanja, dostupnosti frizera i uslugama koje pružaju.

## Stanje projekta

Projekat je u početnoj fazi razvoja. Funkcionalnosti će biti implementirane tokom semestra u skladu sa zahtevima kontrolnih tačaka iz predmeta Razvoj multiplatformskih aplikacija.

