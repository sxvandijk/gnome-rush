# Gnome Rush – plan

Zie CLAUDE.md voor de spelregels en harde regels. Vink af wat klaar is, zodat een nieuwe sessie kan verdergaan.

## M1 Kern

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
- [ ] `MultiMeshInstance3D` voor de kabouters, automatisch vooruit
- [ ] Eén-duim besturing: relatief slepen links/rechts (touch + muis)
- [ ] Camera volgt van achter/boven, licht verend

### 7. Poorten in de scène + testlevel
- [ ] `levels/test_001.json` met een paar poortparen, ingeladen door de scène
- [ ] Poorten tonen waarde (Label3D) en kleur (groen positief, rood negatief)
- [ ] Simpel einde: scherm met het aantal overgebleven kabouters

### 8. Afronding M1
- [ ] Alle GUT-tests groen lokaal en in CI; IPA speelbaar
- [ ] Samenvatting (NL) + testinstructies voor pc-editor en iPhone

## IPA installeren (Stan)
1. GitHub → Actions → "iOS build" → "Run workflow" (of push een tag `v0.1.0`).
2. Als de run klaar is: onderaan bij Artifacts de zip downloaden en uitpakken → `GnomeRush-<versie>.ipa`.
3. Sideloadly: iPhone via USB, IPA erin slepen, Apple ID invullen, Start.
4. iPhone: Instellingen → Privacy en beveiliging → Ontwikkelaarsmodus aan (eenmalig); Instellingen → Algemeen → VPN en apparaatbeheer → je Apple ID vertrouwen.
5. Gratis Apple ID: de app werkt 7 dagen, maximaal 3 apps tegelijk. Daarna opnieuw installeren.
