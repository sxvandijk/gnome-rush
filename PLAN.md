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

## M2 Gevecht

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
- [x] Gevecht 1-tegen-1 elke 0,035 s, leger staat stil
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
- [ ] Alle tests groen, nieuwe IPA, samenvatting + testinstructies; Stan test op iPhone

## Ontwerp: eerlijke bazen (uitwerking in M3)

Regel: de beste route zonder schieten en zonder hulp (`best`) moet de baas halen met minstens 20% marge, dus `levens × 1,2 ≤ best` ofwel `levens ≤ 0,833 × best`. De validator rekent `best` uit met dezelfde simulatie (mollen en maaiers inbegrepen, ideaal ontwijken).

| Baas | Wanneer | Levens | Marge bij `best` |
|---|---|---|---|
| Molkoning (gewoon) | elk level | `best × min(0,80; 0,55 + 0,02×level)`, min. 5 | ≥ 25% |
| Tussenbaas (kat, ekster, sproeierrobot) | level 5, 10, 15 | `best × min(0,80; 0,62 + 0,015×level)`, min. 8 | ≥ 25% |
| Eindbaas (molkoning XL, flamingokoningin) | level 20, 40, 60 | `best × 0,80` | 25% |

- De afronding is altijd naar beneden. De validator controleert daarna nog eens hard `levens × 1,2 ≤ best` en weigert het level als dat niet klopt.
- Tussen- en eindbazen krijgen in M3 een eigen eigenschap (bijvoorbeeld een kat die het leger even terugduwt). Die eigenschap kost nooit kabouters buiten de berekende route om, anders telt de validator haar mee.

## IPA installeren (Stan)
1. GitHub → Actions → "iOS build" → "Run workflow" (of push een tag `v0.1.0`).
2. Als de run klaar is: onderaan bij Artifacts de zip downloaden en uitpakken → `GnomeRush-<versie>.ipa`.
3. Sideloadly: iPhone via USB, IPA erin slepen, Apple ID invullen, Start.
4. iPhone: Instellingen → Privacy en beveiliging → Ontwikkelaarsmodus aan (eenmalig); Instellingen → Algemeen → VPN en apparaatbeheer → je Apple ID vertrouwen.
5. Gratis Apple ID: de app werkt 7 dagen, maximaal 3 apps tegelijk. Daarna opnieuw installeren.
