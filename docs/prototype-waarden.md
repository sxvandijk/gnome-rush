# Gnome Rush – waarden uit het browserprototype

Startpunt voor gevoel en balans; later bijstellen na testen op de iPhone. Eenheden zijn Godot-meters; een kabouter is ongeveer 0,3 breed en 0,9 hoog.

## Besturing en camera
- Vooruitsnelheid leger: 9 eenheden/s
- Slepen: volle schermbreedte = 13 eenheden zijwaarts; leger volgt met smoothing `lerp(x, target, min(1, dt*12))`
- Leger-midden begrensd op x = ±4,3; pad 12 breed, heggen op x = ±6,65
- Camera: positie (x*0,35, 8,6, z−10,5), kijkt naar (x*0,35, 0, z+9); FOV 64 staand, 50 liggend

## Leger
- Startleger 10, +5 per upgrade; upgradekosten 30 × (niveau+1)^1,5
- Formatie: zonnebloemspiraal, hoek i×2,39996, straal 0,27×√i; max 120 zichtbaar (getal toont het echte aantal)
- Leger-straal voor botsingen: 0,27×√min(n,120) + 0,3

## Eikels (schieten)
- 5 per seconde, +1,5 per upgrade; max 90 tegelijk
- Snelheid 30 eenheden/s, verdwijnen 42 eenheden voor het leger
- Raakt `+`/`−`-poort: waarde +1. ×/÷-poorten veranderen niet
- Raakt mol: 1 mol weg. Raakt baas: 0,25 schade

## Levels (seed = levelnummer)
- Rijen elke 26 eenheden vanaf z = 32; aantal rijen 5 + min(level, 8)
- Goede poort: 28% kans ×2 (75%) of ×3 (alleen als beste leger < 250), anders +5 tot +(14 + 3×level)
- Andere kant: 55% kans slecht (30% ÷2, anders −5 tot −(12 + 2×level)), anders nog een goede
- Mollen vanaf level 2 (22% per rij): aantal 25–55% van het beste leger op dat punt, x-verschuiving ±2, ontwijkbaar; gevecht 1-tegen-1 elke 0,035 s, leger staat stil
- Grasmaaiers vanaf level 3 (12% per rij): 2,0 × 1,2 groot, zwaait x = sin(t×v + fase)×3,7 met v = 1,3–2,1 + 0,05×level; kost 1 kabouter per 0,045 s bij overlap
- Baas na de laatste rij + 14; levens = beste route × min(0,8; 0,55 + 0,02×level), minimaal 5
- Baasgevecht: 1 kabouter = 1 leven, interval max(0,012; 0,05 − leger/4000) s
- Tussenbaas (elke 5 levels) en eindbaas (elke 20) zaten nog niet in het prototype: zelf invullen, met dezelfde 20%-margeregel

## Beloning en advertenties (mock)
- Munten bij winst: 10 + 5×level + overgebleven kabouters; rewarded ×3
- Revive: 1× per level, verder met 20 kabouters
- Interstitial: vanaf level 6, na elk 2e level
