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
| [0001](docs/decisions/0001-godot-version-pin.md) | Godot 4.7.2 + Terrain3D 1.0.2 pinnen | vorläufig, Hardware-Test offen |
| [0002](docs/decisions/0002-rad-controller.md) | Eigener Rad-Controller mit ShapeCast + Parkbremse | angenommen, Prototyp besteht 14/14 |
| [0003](docs/decisions/0003-steuerung-kleine-haende.md) | Halte-Tasten statt Joystick | angenommen |
| [0004](docs/decisions/0004-renderer-und-zielgeraet.md) | Mobile-Renderer, schwaches Zielgerät | angenommen, Gerät offen |
| [0005](docs/decisions/0005-kinderbeitraege.md) | Kinderbeiträge: Zeichnungen ja, Stimmen nein | angenommen |
| [0006](docs/decisions/0006-lizenzen.md) | MIT für Code, CC BY 4.0 für Assets | angenommen |
| [0007](docs/decisions/0007-ci-und-tests.md) | CI-Ablauf, Secrets, Manifest-Gate, GUT | angenommen, Umsetzung offen |
| [0008](docs/decisions/0008-crawler-baukasten.md) | Crawler-Baukasten (Garage), 46 Teile, 6 Vorlagen | angenommen, Feel-Check offen |
| [0009](docs/decisions/0009-gamepad-8bitdo.md) | Gamepad 8BitDo SN30 Pro, Knopf-Paare | angenommen, Hardware-Test offen |

## Fahrphysik-Ziele (Spike)

Messung vom 26.10.2026 (Details in ADR 0002/0008):

| Ziel | Gemessen | |
|---|---|---|
| 30-cm-Stufe überwinden | 1,8 s | ✅ |
| 35°-Hang: Drift < 2 cm in 10 s (bergauf, quer, Terrain3D) | 0,0 mm | ✅ |
| Winkelgeschwindigkeit im Stand < 0,01 rad/s | 0,0001 rad/s | ✅ |
| Rad-Einsinken in 15-cm-Spalt | 16,9 mm (Plan: 0, geometrisch ≥ 7 mm) | ⚠️ PO-Entscheidung |
| Aufstellen nach Umkippen < 3 s | 2,0 s | ✅ |
| Alle 105 Baupläne: parken am 35°-Hang + aufstellen | schlechtester: 0,2 mm / 2,2 s | ✅ |
| Android-Zielgerät: ≥ 30 fps über 5 min Fahrbot-Runde | – | offen (Spike-Tag) |

## Offene Aufgaben

- [x] Spike-Tag vorbereiten: Spike-Szene, Fahrbot, Export-Presets, Ablaufplan (`docs/spike/spike-tag.md`)
- [x] Terrain3D 1.0.2-stable pinnen (Skript mit SHA-256), Lizenztexte in `THIRD_PARTY_NOTICES.md`
- [x] CI-Teil 1: Import + Fahrbot (`.github/workflows/fahrbot.yml`)
- [ ] Spike-Tag durchführen: Windows + Android im Mobile-Renderer, Ergebnis in ADR 0001
- [ ] Entscheidung: Grenze für Rad-Einsinken (2 cm statt 0, siehe ADR 0002)
- [ ] Konkretes Einsteiger-Android-Zielgerät benennen (ADR 0004)
- [ ] GUT-Version pinnen
- [ ] CI-Teil 2: Export Windows + Android und Manifest-Gate (`tools/check_apk_permissions.sh`)
- [ ] Godot-MCP-Server auswählen und pinnen (M2)
- [ ] Sub-Agent-Definitionen in `.claude/agents/` mit eingebetteten Regeln (M3)
- [x] `InputSource`-Abstraktion für Touch-UI, Tastatur und Fahrbot (M1)
- [ ] Touch-Steuerung ausbauen: Handballen-Erkennung am Rand, Lenkhilfe, Linkshänder-Modus
- [x] Crawler-Baukasten mit Garage, 46 Teilen, 6 Vorlagen, Baukasten-Matrix im Fahrbot (ADR 0008)
- [x] Gamepad-Unterstützung 8BitDo SN30 Pro inkl. Garagen-Navigation (ADR 0009)
- [ ] 8BitDo SN30 Pro am Spike-Tag mit echtem Gerät prüfen (Windows + Android)
- [ ] Garage: mehrere Stellplätze; echte Modelle statt Grundformen (M7 / Kenney Car Kit, CC0)
- [ ] GitHub Actions: Job bekommt keinen Runner (Repo-/Konto-Einstellungen prüfen)
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
