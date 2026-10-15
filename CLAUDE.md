# Gnome Rush – projectinstructies voor Claude Code

Antwoord Stan in het Nederlands. Code, commits en comments in het Engels.
Werk zo zelfstandig mogelijk. Vraag alleen iets bij keuzes die geld kosten, accounts of sleutels vereisen, of niet terug te draaien zijn.

## Het spel
3D-poortenrenner voor iOS (eerst) en Android (later), gemaakt in Godot 4 (laatste stabiele 4.x), GDScript.
- Een leger tuinkabouters rent automatisch vooruit; speler sleept links/rechts met één duim.
- Poorten in paren: `+n`, `−n`, `×n`, `÷n`. Het leger gaat door de poort aan de kant waar het midden van het leger is.
- Kabouters schieten eikels. Een eikel die een `+`/`−`-poort raakt, verhoogt die met 1 (zo wordt −20 langzaam +5).
- Obstakels: rijdende grasmaaiers (kosten kabouters), groepjes mollen (gevecht 1-tegen-1, ontwijkbaar).
- Eindbaas: de molkoning met levens; elke kabouter die hem bereikt kost hem 1 leven. Eikels doen ook schade.
- Na winst: munten. Upgrades: groter startleger, sneller schieten, schade, muntopbrengst. Skins zijn alleen cosmetisch.
- Levelkaart zoals Candy Crush: kronkelend pad met genummerde levels; haal je een level, dan gaat het volgende open. 1–3 sterren per level (op basis van overgebleven kabouters).
- Tussenbaas elke 5 levels (bijv. boze kat, ekster, sproeierrobot); eindbaas aan het eind van elk hoofdstuk van 20 levels (bijv. molkoning, flamingokoningin). Elk hoofdstuk = nieuwe tuin + nieuwe mechaniek.
- Verlies = hetzelfde level opnieuw. Geen levens of wachttijden.
- Uiterlijk: vrolijke, verzorgde low-poly stijl met goede belichting, effecten (stof, confetti, schermschud) en geluid. Het prototype is alleen voor de regels, niet voor het uiterlijk.
- Referentie voor gevoel en getallen: het browserprototype (Stan heeft de link). Neem de regels over, niet de code.

## Eerlijkheid (harde regels, nooit van afwijken)
- Een levelvalidator rekent per level de beste route uit zonder schieten en zonder betaalde hulp. Die route moet de baas verslaan met minstens 20% marge. Levels die dat niet halen, worden niet geladen.
- Moeilijkheid hangt alleen af van het levelnummer. Nooit van advertenties, aankopen, highscore of speelgedrag.
- Het spel zorgt nooit expres voor verlies om een revive-advertentie te tonen.
- Willekeur alleen via seeds; elk level is reproduceerbaar.
- Geen energie/stamina, geen wachttijden, geen loot boxes, geen aftellende aanbiedingen, geen neppe sluitknoppen.

## Verdienmodel (alles achter interfaces, eerst nepversies)
- `AdService` met `MockAdService`. Echte SDK (AdMob of AppLovin MAX via Godot-plugin) pas na Stans akkoord.
- Rewarded (speler kiest zelf): munten ×3 na winst, 1 revive per level bij verlies, +20% startleger, max 3 gratis upgrades per dag.
- Interstitial: pas vanaf level 5, hooguit na elk 2e level, minimaal 90 s ertussen, nooit direct na een revive.
- `PurchaseService` met mock: "Geen advertenties" €3,99, startpakket €1,99, seizoenspas €4,99 met gratis spoor, skinpakketten €1,99–€4,99. Plafond €9,99.

## Privacy
- Geen account, geen Facebook-SDK, geen camera/opslag/locatie-rechten.
- Eén advertentie-SDK en één analysetool, verder geen SDK's.
- Analyse alleen spelgebeurtenissen (level start/winst/verlies, advertentie bekeken), zonder advertentie-ID.
- EU-toestemmingsscherm via Google UMP; ATT-vraag pas na level 3 met eerlijk voorscherm.
- Knop "Wis mijn gegevens" in Instellingen.

## Techniek en structuur
- `game/logic/`: pure scripts zonder scène (leger, poorten, gevecht, levelgenerator, validator). Volledig getest met GUT.
- `game/scenes/`: weergave, input, camera, effecten. Gebruik MultiMeshInstance3D voor de kabouters.
- `levels/`: levels als JSON. De validator draait in de tests over alle levels.
- Doel: 60 fps op een iPhone uit 2020, Compatibility- of Mobile-renderer.
- Tests draaien headless: `godot --headless -s addons/gut/gut_cmdln.gd`. Draai ze na elke wijziging aan `game/logic/`.

## Bouwen en testen
- Repo is openbaar op GitHub.
- GitHub Actions (`.github/workflows/ios.yml`): op een macOS 26-runner Godot headless installeren met export-templates, exporteren naar een Xcode-project, bouwen met `xcodebuild` zonder ondertekening (`CODE_SIGNING_ALLOWED=NO`), en een `.ipa` (map `Payload/` gezipt) als artifact uploaden. Starten via `workflow_dispatch` en bij tags `v*`.
- Stan installeert de IPA met Sideloadly en zijn gratis Apple ID (werkt 7 dagen). Nog geen developer-account.
- Android later: export-preset alvast aanmaken, testen in de Android Studio-emulator.

## Werkwijze
1. Houd `PLAN.md` bij met mijlpalen en taken; vink af wat klaar is, zodat een nieuwe sessie kan verdergaan.
2. Per taak: eerst tests (voor `game/logic/`), dan code, tests groen, dan een kleine commit.
3. Na elke mijlpaal: korte samenvatting in het Nederlands + wat Stan moet testen (op pc in de editor, of op iPhone via de IPA).
4. Loop je na 3 pogingen vast: stop, beschrijf het probleem en de opties.

## Mijlpalen
- M1 Kern: projectopzet, leger + besturing + camera, poorten, GUT-tests, iOS-workflow die een IPA oplevert.
- M2 Gevecht: eikels, mollen, grasmaaiers, molkoning.
- M3 Levels: generator + validator, 60 levels in 3 hoofdstukken.
- M4 Voortgang: munten, upgrades, skins, opslaan, dagelijkse uitdaging, eindeloze modus.
- M5 Geld en privacy: AdService/PurchaseService met mocks, UMP, ATT, privacyverklaring (NL + EN).
- M6 Afwerking: geluid, effecten, onboarding in 3 levels zonder tekst, vertaling in 8 talen.
- M7 Lancering iOS (vereist dan pas het Apple Developer-account), daarna Android.
