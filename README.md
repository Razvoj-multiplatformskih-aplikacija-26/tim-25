# tim-25
# Frizeraj – Sistem za zakazivanje termina u frizerskim salonima

Frizeraj je multiplatformski sistem za zakazivanje i upravljanje terminima u frizerskim salonima. Klijenti putem mobilne aplikacije pregledaju salone, usluge, cene i dostupne termine, zakazuju i otkazuju rezervacije i prate njihov status. Svaki salon ima svoje zaposlene, radno vreme i raspored, dok osoblje putem backoffice aplikacije upravlja rezervacijama, potvrđuje ili odbija zahteve i evidentira završene termine.

## Tim

| Ime i prezime | Broj indeksa | GitHub nalog |
|---|---|---|
| Boris Bošković | SI 114/24 | [CoolGitGuy](https://github.com/CoolGitGuy) |
| Filip Karadžić | SI 131/24 | [StaticVoid-0](https://github.com/StaticVoid-0) |

## Zahtevi za temu

Glavni pojam sistema je **rezervacija termina** u frizerskom salonu.

### 1. Uloge

Sistem koriste klijenti i osoblje frizerskih salona. Klijenti pregledaju usluge i slobodne termine, kreiraju rezervacije i otkazuju sopstvene termine. Osoblje salona ima pristup rasporedu zaposlenih, potvrđuje ili odbija zahteve za rezervaciju i evidentira završene termine.

### 2. Stanja

Rezervacija prolazi kroz sledeća stanja: **na čekanju, potvrđena, završena, odbijena i otkazana**. Nakon kreiranja rezervacija čeka potvrdu osoblja, koje može da je potvrdi ili odbije. Potvrđena rezervacija prelazi u završenu nakon obavljene usluge, dok je klijent može otkazati pre termina u skladu sa pravilima salona.

### 3. Pravila

Rezervacija mora biti zakazana u budućnosti, u okviru radnog vremena izabranog zaposlenog i dovoljno dugog slobodnog intervala za odabranu uslugu. Jedan zaposleni ne može imati dve aktivne rezervacije koje se vremenski preklapaju. Pošto dostupnost termina zavisi od rezervacija drugih klijenata, konačnu proveru i odluku o zakazivanju donosi server.

### 4. Rad bez mreže

Klijent može da zatraži otkazivanje postojeće rezervacije i kada nema internet konekciju. Zahtev se čuva lokalno i šalje serveru kada se veza ponovo uspostavi. Server proverava da li je otkazivanje i dalje dozvoljeno i vraća rezultat sinhronizacije.

### 5. Posao za osoblje

Osoblje koristi backoffice aplikaciju za pregled dnevnog i nedeljnog rasporeda svih zaposlenih i njihovih rezervacija. Na većem ekranu moguće je pregledati veći broj termina, filtrirati rezervacije po zaposlenom, datumu i statusu, otvarati detalje i potvrđivati ili odbijati zahteve za zakazivanje.

### 6. Javni sadržaj

Javni veb omogućava posetiocima da bez prijavljivanja pregledaju frizerske salone, njihove usluge, cenovnike, radno vreme i osnovne informacije o zaposlenima. Ovaj sadržaj dostupan je internet pretraživačima kako bi korisnici mogli da pronađu salon i njegove usluge pre instaliranja aplikacije.

## Delovi sistema

| Deo | Korisnici | Tehnologija | Platforme |
|---|---|---|---|
| Mobilna aplikacija | Klijenti | Flutter | Android, iOS |
| Backoffice | Osoblje salona | Flutter | Windows, veb |
| Javni veb | Svi posetioci | Jaspr | Pregledač |
| Server | Ostali delovi sistema | Relic, PostgreSQL | Linux |
| Domenski paket | Svi delovi sistema | Dart | Sve platforme |

Svi delovi sistema koriste zajednički domenski paket koji sadrži modele i poslovna pravila. Server čuva podatke, proverava ovlašćenja i konačno odlučuje o dostupnosti termina kako bi sprečio dvostruko zakazivanje.
