# Gnome Rush – plan

Zie CLAUDE.md voor de spelregels en harde regels. Vink af wat klaar is, zodat een nieuwe sessie kan verdergaan.

## M1 Kern ✅ (afgerond 2026-10-15)

Volgorde: eerst een minimaal project + iOS-workflow (zo snel mogelijk een IPA op de iPhone), daarna de spellogica.

### 1. Projectopzet (minimaal, voor de IPA)
- [x] `project.godot`: "Gnome Rush", renderer Mobile, portrait 1080×1920, stretch `canvas_items`/`expand`, ETC2/ASTC, GUT-plugin aan
- [x] Mappen `game/logic/`, `game/scenes/`, `levels/`, `tests/unit/`
- [x] `game/scenes/main.tscn`: placeholder-scène (gras, kabouter-kegels, licht, camera, label)
- [x] `.gitattributes` met LF voor Godot-, script- en workflowbestanden
- [x] Lokaal: `--headless --import` werkt en GUT draait één smoke-test groen

### 2. iOS-workflow `.github/workflows/ios.yml`
- [x] Trigger `workflow_dispatch` en tags `v*`, runner `macos-26`
- [x] Godot 4.7.2 macOS + iOS-exporttemplate downloaden (gecachet)
- [x] Export naar Xcode-project (`export_project_only`), `xcodebuild` zonder ondertekening
- [x] `Payload/` zippen tot `.ipa`, uploaden als artifact (14 dagen)
- [x] `export_presets.cfg`: iOS-preset (bundle-ID `com.sxvandijk.gnomerush`, dummy Team ID) + Android-preset (alleen aangemaakt)
- [x] Versie uit tag, anders `0.1.<run_number>`
- [x] Workflow draait groen (run 0.1.1, IPA 24 MB)
- [x] Stan heeft de IPA via Sideloadly op de iPhone gezet (werkt)

### 3. Test-workflow `.github/workflows/tests.yml`
- [x] Ubuntu, Godot 4.7.2 headless, GUT op push/PR; faalt bij rode tests

### 4. Leger-logica `game/logic/army.gd` (TDD)
- [x] Aantal kabouters; poort toepassen `+n`, `−n`, `×n`, `÷n` (naar beneden afronden, minimum 0, 0 = verloren)
- [x] Deterministische formatie: posities van n kabouters rond het middelpunt
- [x] Middelpunt x begrensd door de baanbreedte

### 5. Poort-logica `game/logic/gate.gd` + `gate_pair.gd` (TDD)
- [x] Poortpaar links/rechts; keuze op het midden van het leger
- [x] `hit_by_acorn()`: `+`/`−`-poort +1; `×`/`÷` onveranderd
- [x] Elk paar maar één keer toegepast

### 6. Scène: leger, besturing, camera
- [x] `MultiMeshInstance3D` voor de kabouters, automatisch vooruit
- [x] Eén-duim besturing: relatief slepen links/rechts (touch + muis)
- [x] Camera volgt van achter/boven, licht verend

### 7. Poorten in de scène + testlevel
- [x] `levels/test_001.json` met een paar poortparen, ingeladen door de scène
- [x] Poorten tonen waarde (Label3D) en kleur (groen positief, rood negatief)
- [x] Simpel einde: scherm met het aantal overgebleven kabouters

### 8. Afronding M1
- [x] Alle GUT-tests groen lokaal en in CI; IPA speelbaar
- [x] Samenvatting (NL) + testinstructies voor pc-editor en iPhone

## M2 Gevecht ✅ (afgerond 2026-10-17)

Waarden uit `docs/prototype-waarden.md`. Alle regels in `game/logic/`, met een vaste stap van 1/60 s, zodat elk level reproduceerbaar is en de validator (M3) dezelfde simulatie gebruikt.

### 1. Schaal en besturing naar het prototype
- [x] Pad 12 breed (poorten 6 breed), legermidden begrensd op ±4,3, heggen op ±6,65, snelheid 9
- [x] Sturen: volle schermbreedte = 13 eenheden; legermidden volgt met `min(1, dt×12)` (in de logica, dus ook de poortkeuze)
- [x] Formatie straal 0,27×√i, max 120 zichtbaar; botsstraal 0,27×√min(n,120) + 0,3
- [x] Camera (x×0,35; 8,6; 10,5 achter), kijkt 9 vooruit, FOV 64 staand
- [x] `RunState.update(dt)` met vaste stap 1/60 s

### 2. Eikels
- [x] 5 per seconde, snelheid 30, max 90 tegelijk, weg na 42 voor het leger
- [x] Raakt `+`/`−`-poort: +1 (×/÷ niet); raakt mol: 1 mol weg; raakt baas: 0,25 schade
- [x] Weergave met MultiMesh

### 3. Mollen
- [x] Groep met aantal en x; botsing als leger en groep elkaar raken, anders ontweken
- [x] Gevecht 1-tegen-1 elke 0,035 s; leger rent door op halve snelheid en duwt de mollen voor zich uit (op verzoek van Stan, i.p.v. stilstaan)
- [x] Weergave: groep mollen met aantal erboven

### 4. Grasmaaiers
- [x] 2,0 × 1,2, zwaait `sin(t×v + fase)×3,7`; kost 1 kabouter per 0,045 s bij overlap
- [x] Weergave

### 5. Molkoning (baas)
- [x] Staat aan het eind; leger stopt ervoor; 1 kabouter = 1 leven, interval `max(0,012; 0,05 − leger/4000)` s
- [x] Winst als levens op zijn; verlies als het leger op is
- [x] Weergave met levens erboven

### 6. Testlevel en afronding
- [x] `levels/test_001.json` met poorten, mollen, maaiers en molkoning; `tests/unit/test_levels.gd` speelt elk level met een piloot zonder schieten (320 kabouters bij de baas, nodig 232)
- [x] Alle tests groen, nieuwe IPA, samenvatting + testinstructies; Stan test op iPhone (voelt prima)

### 7. Mollen-varianten (feedback Stan: mollen voegden niets toe)
- [x] Bewaakte poort: groep max. 3 eenheden voor de betere poort; ontwijken = slechtere poort (alleen levelontwerp)
- [x] Kooi (`cage`): gevangen kabouters komen vrij als de mollen verslagen zijn én het leger over de kooi loopt; voorbijlopen = kwijt
- [x] Achtervolgers (`chase`): schuiven binnen 20 eenheden zijwaarts naar het leger (roodbruin)
- [x] `moles_defeated` geteld voor munten per mol (M4)

## M3 Levels ✅ (afgerond 2026-10-18)

Generator maakt levels uit een seed (= levelnummer); de validator rekent de beste route uit zonder schieten en weigert oneerlijke levels. Levels worden als JSON in `levels/` opgeslagen en bij het laden opnieuw gecontroleerd.

### 1. Validator `game/logic/level_validator.gd`
- [x] Planner: per poort, mollengroep en kooi de beste keuze (alle bewerkingen zijn monotoon, dus per stap het grootste leger kiezen is optimaal); bewaakte poort alleen via vechten
- [x] Piloot: speelt het plan na in `RunState` zonder schieten, ontwijkt maaiers en achtervolgers; aantal bij de baas = `best` (ondergrens van het echte optimum, dus aan de veilige kant)
- [x] `validate(level)`: te halen als `levens × (1 + marge(level)) ≤ best`; `test_levels.gd` gebruikt de validator

### 2. Generator `game/logic/level_generator.gd`
- [x] Rijen elke 26 vanaf z = 32, aantal `5 + min(level, 8)`; poortkansen volgens het prototype
- [x] Obstakels tussen rijen en bewaakte poorten volgens "Ontwerp: mollen per level"
- [x] Baas volgens "Ontwerp: eerlijke bazen" met `best` uit de validator; bij een onbruikbaar level volgende sub-seed (deterministisch)

- [x] Grote legers: ×-poorten alleen onder 2000 kabouters; mollengevecht max. 2 s en baasgevecht max. 6 s (sneller ruilen, nog steeds 1-tegen-1); beste route minstens 50

### 3. Hoofdstukken (3 × 20 levels)
- [x] 1 Voortuin (1–20): poorten, mollen, maaiers, kooien, achtervolgers
- [x] 2 Moestuin (21–40): nieuw: sproeiers die het leger zijwaarts duwen
- [x] 3 Vijvertuin (41–60): nieuw: poorten met een schuivende scheidslijn
- [x] Kleuren/tuin per hoofdstuk (placeholder), bazen per soort (placeholder-uiterlijk)

### 4. 60 levels en laden
- [x] Script `tools/generate_levels.gd` schrijft `levels/level_001.json` … `level_060.json`
- [x] Laden via de validator: oneerlijk level wordt niet geladen
- [x] Simpele levelkeuze (nummer kiezen, na winst volgende level); de echte levelkaart komt in M4
- [x] Tests: alle 60 levels eerlijk, reproduceerbaar (zelfde seed = zelfde JSON)

### 5. Moeilijkheid van makkelijk naar moeilijk (feedback Stan)
- [x] `game/logic/difficulty.gd`: marge loopt af van 75% (level 1) naar 5% (level 60); tussenbazen ×0,8, eindbazen ×0,6, nooit onder 3%
- [x] Obstakelkansen lopen op met het level (bewaakte poorten, maaiers, kooien, achtervolgers, slechte poorten, sproeiers, schuivende poorten)
- [x] Achtervolgers stoppen op 7 eenheden afstand: op het laatste moment uitwijken lukt altijd (Stan: rode mollen soms niet te ontwijken)
- [x] Sproeiers heftiger: duw 6 (level 21) tot 10 eenheden/s
- [x] Compacter leger: grote legers lopen dichter op elkaar (zwerm max. straal 2,0 i.p.v. 3,0), zodat ontwijken lukt (Stan: leger te groot, blijft haken)
- [x] Onbeperkt aantal levels: curve vlakt af i.p.v. te stoppen bij 60, rustpunt na elke baas, bestanden `level_0001.json` + `index.json`, hoofdstukken/thema's/bazen herhalen zich (200 levels getest)

### 6. Afronding
- [x] Ontwikkelopties: `-- --level=N` start direct in level N, `-- --autopilot` laat de validatorpiloot spelen
- [x] Nieuwe IPA, samenvatting + testinstructies; Stan test op iPhone (werkt, ontwijken soms nog niet perfect → TODO.md)

## M4 Voortgang

Alle regels in `game/logic/` (getest), opslaan en schermen in `game/scenes/`. Waarden: prototype waar mogelijk, aangepast aan onze grotere legers.

### 1. Voortgang en opslaan
- [x] `Progress` (logica): vrijgespeelde levels, sterren per level, munten, upgrades, skins, dagelijkse uitdaging, eindeloos-record; `to_dict`/`from_dict` met versienummer
- [x] Opslaan in `user://progress.json` na elke wijziging; kapot of ontbrekend bestand = nieuwe voortgang

### 2. Sterren en munten (`Rewards`)
- [x] Sterren bij winst, op basis van over `r = over / (best − levens)`: 3 bij `r ≥ 0,6`, 2 bij `r ≥ 0,25`, anders 1
- [x] Munten bij winst: `10 + 5×level + 3×√over + 5×sterren + verslagen mollen/10`, × muntbonus
- [x] Beste score per level blijft bewaard (sterren gaan nooit omlaag)

### 3. Upgrades (met munten, kosten `30 × (niveau+1)^1,5` uit het prototype)
- [x] Groter startleger: +5 per niveau (max. 20)
- [x] Sneller schieten: +1,5 eikels/s per niveau (max. 10)
- [x] Schade: eikels op de baas +0,1 per niveau (max. 10)
- [x] Muntopbrengst: +10% per niveau (max. 10)
- [x] Upgrades tellen niet mee in de validator (die rekent zonder hulp)

### 4. Skins (alleen uiterlijk)
- [x] Catalogus met kleuren voor lijf en muts; Klassiek gratis, de rest voor munten; een paar alleen via skinpakketten (M5)
- [x] Gekozen skin zichtbaar in het spel

### 5. Levelkaart
- [x] Kronkelend pad omhoog met genummerde levels, sterren, slotjes; bazen gemarkeerd; hoofdstukbordjes
- [x] Tekent alleen het zichtbare stuk, zodat duizenden levels kunnen
- [x] Opent bij je huidige level; munten en winkel bovenin

### 6. Dagelijkse uitdaging en eindeloze modus
- [x] Dagelijks: level uit de datum (seed `jjjjmmdd`), moeilijkheid volgens je voortgang; eenmaal per dag beloning
- [x] Eindeloos: rijen blijven komen en worden steeds lastiger, geen baas; score = gehaalde rijen; record bewaard; munten per rij

### 7. Afronding
- [x] Ontwikkelopties: `-- --daily` en `-- --endless`
- [ ] Nieuwe IPA, samenvatting + testinstructies; Stan test op iPhone

## Ontwerp: mollen per level (uitwerking in M3)

Makkelijk beginnen, later lastiger. Losse mollen die alleen in de weg staan komen weinig voor; bijna elke groep bewaakt iets, heeft een kooi of achtervolgt.

| Variant | Vanaf level | Sterkte |
|---|---|---|
| Bewaakte poort | 2 | groep 25–55% van het beste leger (prototype); bewaakt altijd de betere poort |
| Grasmaaiers | 3 | prototype: `v = 1,3–2,1 + 0,05×level` |
| Kooi | 4 | kooi = mollen × `max(1,1; 1,5 − 0,01×(level − 4))`: eerst ruim (1,5×), later krap (1,1×) |
| Achtervolgers | 8 | `chase = min(2,0; 0,6 + 0,03×level)` eenheden/s, groep 10–30% van het leger; stoppen op 7 eenheden afstand, zodat laat uitwijken altijd lukt |
| Munten per mol | M4 | 1 munt per verslagen mol |

## Ontwerp: moeilijkheid en bazen

Het spel loopt van makkelijk naar moeilijk. Alles wat moeilijker wordt, hangt alleen van het levelnummer af (`game/logic/difficulty.gd`). De validator rekent de beste route zonder schieten (`best`); die moet de baas altijd halen, met een marge die afneemt:

`marge = 5% + 70% × e^(−(level−1)/35)`: er is geen laatste level, de curve vlakt af.

| Level | Marge `best / levens − 1` | Gevoel |
|---|---|---|
| 1 | 75% | ruim, fouten mogen |
| 30 | ~34% | je moet goed kiezen |
| 60 | ~18% (eindbaas 11%) | weinig ruimte |
| 100+ | 5–8% | bijna perfect spelen of goed schieten |
| tussenbaas (elk 5e) | marge × 0,8 | piekje |
| eindbaas (elk 20e) | marge × 0,6, min. 3% | zwaarste van het hoofdstuk |
| level na een baas | marge × 1,3 | rustpunt |

- Levens = `floor(best / (1 + marge))`, minimaal 5 (tussen-/eindbaas 8). Schieten geeft de speler extra ruimte bovenop de marge.
- Obstakelkansen per rij lopen lineair op van level 1 naar 60 (zie `LevelGenerator`).
- Tussen- en eindbazen krijgen later een eigen eigenschap (zie TODO.md).

## IPA installeren (Stan)
1. GitHub → Actions → "iOS build" → "Run workflow" (of push een tag `v0.1.0`).
2. Als de run klaar is: onderaan bij Artifacts de zip downloaden en uitpakken → `GnomeRush-<versie>.ipa`.
3. Sideloadly: iPhone via USB, IPA erin slepen, Apple ID invullen, Start.
4. iPhone: Instellingen → Privacy en beveiliging → Ontwikkelaarsmodus aan (eenmalig); Instellingen → Algemeen → VPN en apparaatbeheer → je Apple ID vertrouwen.
5. Gratis Apple ID: de app werkt 7 dagen, maximaal 3 apps tegelijk. Daarna opnieuw installeren.
