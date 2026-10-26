# Kraxl – Projektinhalt

## Ziel

Offline-Sandkasten-Fahrspiel für Kinder ab 4 Jahren auf Windows und Android. Fahrzeuge erkunden eine
offene Welt (ca. 1×1 km) mit Hängen, Steinen, Matsch und Toren. Ohne Punkte, ohne Scheitern, ohne Internet.

## Rollen

- **Product Owner:** David (Mensch, Fahrgefühl-Abnahme, Kindertest nach jedem Release)
- **Team-Lead-Agent:** merged Worktree-Branches nach grünem Gate, pflegt Regeln auf `main`
- **Sub-Agents:** arbeiten in Worktrees (`isolation: worktree`) mit eigenen Regeln im Prompt
- **Reviewer-Agent:** Screenshots/Fahrbot-Videos über Godot-MCP, Metrik-Tabellen

## Entscheidungen (ADRs)

| Nr. | Thema | Status |
|---|---|---|
| [0001](docs/decisions/0001-godot-version-pin.md) | Godot 4.7.2 + Terrain3D 1.0.2 pinnen | Windows bestätigt, Android offen |
| [0002](docs/decisions/0002-rad-controller.md) | Eigener Rad-Controller mit ShapeCast + Parkbremse | angenommen, Prototyp besteht 14/14 |
| [0003](docs/decisions/0003-steuerung-kleine-haende.md) | Halte-Tasten statt Joystick | angenommen |
| [0004](docs/decisions/0004-renderer-und-zielgeraet.md) | Mobile-Renderer, schwaches Zielgerät | angenommen, Gerät offen |
| [0005](docs/decisions/0005-kinderbeitraege.md) | Kinderbeiträge: Zeichnungen ja, Stimmen nein | angenommen |
| [0006](docs/decisions/0006-lizenzen.md) | MIT für Code, CC BY 4.0 für Assets | angenommen |
| [0007](docs/decisions/0007-ci-und-tests.md) | CI-Ablauf, Secrets, Manifest-Gate, GUT | angenommen, Umsetzung offen |
| [0008](docs/decisions/0008-crawler-baukasten.md) | Crawler-Baukasten (Garage), 53 Teile, 8 Vorlagen | angenommen, Feel-Check offen |
| [0009](docs/decisions/0009-gamepad-8bitdo.md) | Gamepad 8BitDo SN30 Pro, Knopf-Paare | Windows bestätigt, Android offen |
| [0010](docs/decisions/0010-toene.md) | Töne per Code (Motor, Hupe, Plumps, Klick) | angenommen, Feel-Check offen |
| [0011](docs/decisions/0011-modelle-werkzeug-licht-rauch.md) | Kenney-Modelle, Bagger/Radlader, Licht, Auspuffrauch, Touch-Tasten nur bei Touch | angenommen, Feel-Check offen |
| [0012](docs/decisions/0012-zwei-spieler-farben-rand-update.md) | Zwei Spieler (geteilter Bildschirm), bunte Farben, Weltrand, Updater neben der Exe | angenommen, Feel-Check offen |

## Fahrphysik-Ziele (Spike)

Messung vom 26.10.2026 (Details in ADR 0002/0008):

| Ziel | Gemessen | |
|---|---|---|
| 30-cm-Stufe überwinden | 1,8 s | ✅ |
| 35°-Hang: Drift < 2 cm in 10 s (bergauf, quer, Terrain3D) | 0,0 mm | ✅ |
| Winkelgeschwindigkeit im Stand < 0,01 rad/s | 0,0001 rad/s | ✅ |
| Rad-Einsinken in 15-cm-Spalt | 16,9 mm (Plan: 0, geometrisch ≥ 7 mm) | ⚠️ PO-Entscheidung |
| Aufstellen nach Umkippen < 3 s | 2,0 s | ✅ |
| Alle 109 Baupläne: parken am 35°-Hang + aufstellen | schlechtester: 0,2 mm / 2,2 s | ✅ |
| Android-Zielgerät: ≥ 30 fps über 5 min Fahrbot-Runde | – | offen (Spike-Tag) |

## Offene Aufgaben

- [x] Spike-Tag vorbereiten: Spike-Szene, Fahrbot, Export-Presets, Ablaufplan (`docs/spike/spike-tag.md`)
- [x] Terrain3D 1.0.2-stable pinnen (Skript mit SHA-256), Lizenztexte in `THIRD_PARTY_NOTICES.md`
- [x] CI-Teil 1: Import + Fahrbot (`.github/workflows/fahrbot.yml`)
- [x] Spike-Tag Windows: Mobile-Renderer + Terrain3D laufen (RX 6600 XT, 59 fps), Gamepad über Adapter erkannt
- [ ] Spike-Tag Android: Mobile-Renderer, 5-min-Runde ≥ 30 fps, APK-Gate, Gamepad per OTG
- [x] Töne per Code (ADR 0010)
- [ ] Elternmenü: Lautstärke Musik/Effekte getrennt, Lizenzen anzeigen
- [ ] Entscheidung: Grenze für Rad-Einsinken (2 cm statt 0, siehe ADR 0002)
- [ ] Konkretes Einsteiger-Android-Zielgerät benennen (ADR 0004)
- [ ] GUT-Version pinnen
- [x] CI: Windows-Exe als Artefakt nach grünen Tests (Export-Vorlagen gecacht)
- [ ] CI-Teil 2: Android-Export und Manifest-Gate (`tools/check_apk_permissions.sh`)
- [ ] Godot-MCP-Server auswählen und pinnen (M2)
- [ ] Sub-Agent-Definitionen in `.claude/agents/` mit eingebetteten Regeln (M3)
- [x] `InputSource`-Abstraktion für Touch-UI, Tastatur und Fahrbot (M1)
- [ ] Touch-Steuerung ausbauen: Handballen-Erkennung am Rand, Lenkhilfe, Linkshänder-Modus
- [x] Crawler-Baukasten mit Garage, 46 Teilen, 6 Vorlagen, Baukasten-Matrix im Fahrbot (ADR 0008)
- [x] Gamepad-Unterstützung 8BitDo SN30 Pro inkl. Garagen-Navigation (ADR 0009)
- [ ] 8BitDo SN30 Pro am Spike-Tag mit echtem Gerät prüfen (Windows + Android), direkt und über USB Wireless Adapter 2
- [x] Logo und App-Symbol (`icon.svg`, `docs/logo/`)
- [ ] Garage: mehrere Stellplätze; echte Modelle statt Grundformen (M7 / Kenney Car Kit, CC0)
- [ ] Release-Keystore erzeugen, offline sichern, als CI-Secret hinterlegen
- [ ] Zustimmung beider Elternteile für Kinderzeichnungen schriftlich einholen

## Verlauf

- **2026-10-25** – Repo angelegt. Priorisierte Verbesserungen (Stand Oktober 2026) als
  `docs/plan-verbesserungen-2026-10.md` übernommen und in ADRs 0001–0007, `CLAUDE.md`,
  `project.godot`, Physik-Konstanten, Lizenzdateien und Pre-commit-Hook umgesetzt.
- **2026-10-25** – Spike-Tag vorbereitet:
  - Terrain3D 1.0.2 gepinnt; es nennt jetzt Godot 4.4–4.7 als unterstützt.
  - Rad-Controller-Prototyp, InputSource, Touch-Tasten, Terrain3D-Region per Code, Spike-Szene mit
    5-min-FPS-Runde, Fahrbot mit 7 Szenarien und 14 Metriken (alle grün), CI-Workflow, Export-Presets,
    APK-Berechtigungs-Gate.
  - In der Cloud geprüft: Terrain3D lädt, Kollision mit Jolt funktioniert, Rendering im
    Compatibility-Renderer läuft.
  - Vulkan/Mobile ist nur auf echter Hardware prüfbar.
- **2026-10-26** – Crawler-Baukasten und Gamepad:
  - Garage als Startszene mit 10 Kategorien, 46 Teilen und 6 Vorlagen; nur Antippen, keine Texte.
  - Vorbilder recherchiert (`docs/referenzen.md`):
    - SnapRacers: nur Ideen, da GPL.
    - Traxxas TRX-4/TRX-6: Portalachsen, Ketten, 6×6.
    - Lindinger/Absima: Abschlepper, 6×6.
  - Die Baukasten-Matrix (105 Baupläne) hat Kippen, Überschlagen und Nachwippen aufgedeckt. Gelöst durch
    breitere Spur und längeren Radstand bei großen Rädern, effektive Kontaktmasse, mehr Dämpfung und eine
    PD-Aufstellhilfe.
  - 8BitDo SN30 Pro mit Knopf-Paaren gegen den A/B-Tausch. Godot 4.7 belegt Menüs nicht mit Gamepad-Knöpfen,
    das ist jetzt ergänzt. UI-Test mit 208 Checks und Skriptfehler-Zähler.
  - CI ohne `--quit-after`: das hätte unvollständige Läufe grün gemeldet.
  - Erster CI-Lauf auf GitHub grün. Der Fehlschlag vom 25.10. (kein Runner zugewiesen) war vorübergehend.
- **2026-10-26** – Logo und 8BitDo USB Wireless Adapter 2:
  - Logo: orangefarbener Crawler kraxelt einen Felshang hinauf. Schriftzug „Kraxl“ mit orangem x,
    Unterzeile „kraxeln · bauen · losfahren“, Varianten für hell und dunkel.
  - Das Logo ist gleichzeitig das App-Symbol und wird reproduzierbar per Skript erzeugt.
  - Adapter 2: Godot 4.7.2 kennt ihn bereits auf Windows, macOS, Linux und Android (OTG).
  - Absicherung gegen unbekannte Firmware: Controller-Statuszeile mit GUID und
    `data/gamecontrollerdb_extra.txt`.
  - UI-Test: 212 Checks.
  - Absturz beim Beenden behoben (Lambda am Input-Singleton), Regel in CLAUDE.md.
- **2026-10-26** – Erste Windows-Exe:
  - Exe (110 MB) plus Terrain3D-DLL, als ZIP mit LIESMICH an den PO.
  - Geprüft: Das Paket enthält Szenen und Controller-Mappings, aber keine Tests und keine Doku; das
    exportierte Spielpaket startet ohne Skriptfehler.
  - CI baut die Exe ab jetzt automatisch.
- **2026-10-26** – Erster Test am PC (PO):
  - Windows-Exe startet; Mobile-Renderer mit Vulkan auf AMD RX 6600 XT, 59 fps.
  - Terrain3D rendert korrekt; der Kettenfahrer fährt den 35°-Hang hinauf.
  - 8BitDo SN30 Pro über USB Wireless Adapter 2 wird als „XInput Controller (bekannt)“ erkannt.
  - → Windows-Teil von H1 bestanden (ADR 0001).
- **2026-10-26** – Töne (ADR 0010):
  - Motor je Motor-Teil (Tonhöhe folgt Tempo), Ketten-Rattern, Hupe (L3/R3, H, Touch-Taste), Plumps beim
    Aufsetzen, Dreiklang nach dem Aufstellen, Klick auf Touch-Tasten.
  - Alles läuft über einen Effekte-Bus mit Begrenzer.
  - Statuszeile bricht vor dem Fahrbot-Knopf um. UI-Test: 262 Checks.
- **2026-10-26** – Wünsche nach dem PC-Test (ADR 0011):
  - **Bessere Modelle:** Kenney Car Kit (CC0) für Karosserien und Räder, in der Garage-Farbe lackiert
    (Shader auf der Palettenkachel). Buggy, Bagger und Ketten bleiben gezeichnet.
  - **Bagger und Radlader:** neue Aufbauten und Vorlagen (48 Teile, 8 Vorlagen).
    - Werkzeug-Taste: R3 bzw. rechter Stick nach unten, E, Touch-Schaufel.
    - Das Werkzeug ist reine Optik ohne Kollision.
  - **Licht schaltbar:** Start im Gelände, L, Touch-Lampe. Die Hupe liegt nur noch auf L3.
  - **Auspuffrauch:** graue Wölkchen, mehr bei Gas; mit Extra „Auspuff“ aus zwei Rohren.
  - **PC:** große Pfeil-Tasten nur auf Touch-Geräten; Tastatur oder Gamepad blendet sie aus. Die
    Entwickler-Anzeige (FPS, Controller, Fahrbot-Knopf) ist in der Exe aus, F3 schaltet sie ein.
  - Fahrbot: 109 Baupläne, 19 Metriken, 0 verfehlt.
    - Die bisherigen Werte sind unverändert.
    - Neu schlechtester quer: Vorlage Radlader, Drift 0,0 mm.
  - UI-Test: 347 Checks. Spielszenen-Rauchtest grün.
- **2026-10-26** – Zwei Spieler, Farben, Weltrand, Updater (ADR 0012):
  - **Zwei Spieler:** geteilter Bildschirm links/rechts.
    - Garage: Figuren-Karte schaltet 1/2 Spieler, Helm-Karten (1 bzw. 2 Punkte) wählen den Crawler.
    - Eingabe: je Spieler ein Gamepad, eine Tastaturhälfte (WASD bzw. Pfeiltasten) und eine Touch-Hälfte.
  - **Bunt:** 13 Lackfarben inkl. Regenbogen (wandert beim Fahren); farbige Felgen und Zierteile.
    Welt mit Blumenwiese, Kegel-Slalom, Kistenturm (umschubsbar), kräftigerem Himmel.
  - **„Der Fahrer fällt“:** Am Geländerand ging es ins Leere. Jetzt hält ein bunter Zaun mit unsichtbarer
    Wand auf. Wer trotzdem hinausfällt, steht sofort wieder am Start. Neues Fahrbot-Szenario
    `terrain3d_rand`.
  - **Updater:** Das Spiel bleibt offline (Kinder-Regel 3).
    - Die CI veröffentlicht bei jedem grünen main-Push ein Release.
    - `Kraxl-Update.cmd` im Spielordner holt es, prüft die SHA-256-Prüfsumme und ersetzt die Dateien.
    - Mit PowerShell 7.4 gegen einen lokalen Testserver geprüft: Update, „aktuell“, beschädigt.
  - Tests: Fahrbot 22 Metriken, 0 verfehlt (109 Baupläne, neu `terrain3d_rand`: 4,2 m vor dem Rand gestoppt).
    UI-Test 378 Checks. Rauchtest mit einem und zwei Spielern grün.
  - Fahrbot-Frage des PO beantwortet: Der Fahrbot ist der automatische Testfahrer der CI. Im Spiel steckt
    nur die FPS-Messrunde, versteckt hinter F3.
