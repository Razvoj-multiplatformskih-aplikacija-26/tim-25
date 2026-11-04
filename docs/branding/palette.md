# Zvanična paleta Frizeraja

Prepisano iz korisnikove reference `palette-reference.png`.

| Boja | HEX | Primena |
| --- | --- | --- |
| Tamnoplava (Navy) | `#172B4D` | Naslovi, primarna dugmad, navigacija, aktivni elementi |
| Koralno crvena (Coral) | `#D9685F` | Sitni akcenti, oznake, obaveštenja i fokus |
| Topla bela (Cream) | `#FAF9F6` | Glavna pozadina |
| Ugljenocrna (Charcoal) | `#242424` | Tekst i sekundarni elementi |
| Svetlosiva | `#F3F4F6` | Neutralne površine |

Vizuelni odnos je smernica: približno 70% bele/krem, 25% tamnoplave i 5% koralne.
Prostor ostaje prozračan; koralna nije velika pozadina niti boja sitnog teksta na belom.
Oznake stanja koriste tekst i različite ikonice, pa ne zavise samo od boje.
Blage nijanse tamnoplave, neutralni razdelnici i prigušen tekst služe hijerarhiji.

Izvor boja za oba Flutter klijenta je `FrizerajColors` u
`packages/ui/lib/src/theme/colors.dart`. Web manifest, boja pregledača i Android
početna pozadina prate istu paletu. Originalni korisnikov logo ostaje neizmenjen.
