# Kraxl

Offline-Sandkasten-Fahrspiel für Kinder ab 4 Jahren (Windows + Android), gebaut mit Godot.
Kein Scheitern, keine Werbung, keine Käufe, kein Internet, keine Datenerfassung.

## Status

Spike-Stand (Oktober 2026):
- Fahrbares Prototyp-Fahrzeug auf einem Terrain3D-Gelände, mit Touch-Steuerung und FPS-Messung.
- Der Fahrbot besteht alle 14 Physik-Metriken (Godot 4.7.2 + Jolt + Terrain3D 1.0.2).

Offen ist der Hardware-Test am **Spike-Tag**: Windows und Android im Mobile-Renderer
(Ablauf: [docs/spike/spike-tag.md](docs/spike/spike-tag.md)).

## Technik-Eckdaten

| Bereich | Festlegung |
|---|---|
| Engine | Godot **4.7.2-stable** (Rückfallebene 4.6.3), siehe `.tool-versions` |
| Physik | Jolt Physics (explizit gesetzt), 120 Ticks/s, Physik-Interpolation an |
| Fahrzeuge | Eigener Rad-Controller mit ShapeCast3D + „Parkbremse“, kein VehicleBody3D |
| Renderer | Mobile (Windows und Android) |
| Terrain | Terrain3D 1.0.2-stable (per Skript gepinnt), max. 8 Boden-Texturen ≤ 1024² |
| Steuerung | „Kleine Hände“: große Halte-Tasten, Auslösen bei Touch-Down; Joystick nur optional |
| Tests | Fahrbot (headless, CI), später GUT passend zur Godot-Minor |
| Android | APK ohne jede `uses-permission` (Prüfskript `tools/check_apk_permissions`, CI-Gate folgt) |

## Struktur

```
docs/
  plan-verbesserungen-2026-10.md   priorisierte Verbesserungen (H1–H6, M1–M7, L1–L4)
  decisions/                        Architekturentscheidungen (ADRs)
  spike/spike-tag.md                Ablauf und Messprotokoll für den Spike-Tag
  feel-check.md                     Checkliste für die Probefahrt des Product Owners
  dependencies.md                   Abhängigkeiten inkl. Prüfung „sammelt Daten?“
assets/                             eigene Assets (CC BY 4.0), Kinderzeichnungen, Herkunftsliste
scenes/spike/terrain_spike.tscn     Hauptszene: Terrain + Fahrzeug + Touch + FPS-Runde
src/
  input/                            InputSource-Abstraktion: Touch, Tastatur, Fahrbot
  vehicle/                          Rad-Controller; vehicle_constants.gd = einziger Ort für Physik-Werte
  world/spike_terrain.gd            Terrain3D-Region per Code (35°-Hang, Wiese, Hügel)
  spike/terrain_spike.gd            Spike-Szene inkl. 5-min-Fahrbot-Runde
tests/fahrbot/                      Physik-Szenarien mit Messwerten (headless, CI)
tools/                              Terrain3D laden, APK-Berechtigungen prüfen
scripts/hooks/pre-commit            Schutz für Kinderbeiträge
.github/workflows/fahrbot.yml       CI: Import + Fahrbot
CLAUDE.md                           nicht verhandelbare Regeln für Agenten
Projektinhalt.md                    laufende Projektübersicht
```

## Einrichtung

```sh
git clone https://github.com/brummilab/Kraxl
cd Kraxl
sh tools/fetch_terrain3d.sh   # Windows: .\tools\fetch_terrain3d.ps1
sh scripts/install-hooks.sh   # Pre-commit-Hook für Kinderbeiträge aktivieren
```

Dann das Projekt mit Godot 4.7.2-stable öffnen. **F5** startet die Spike-Szene:
- Steuerung mit Pfeiltasten/WASD oder den Touch-Tasten.
- Der Knopf „Fahrbot 5 min“ startet die FPS-Messrunde.

## Fahrbot (Physik-Tests)

```sh
godot --headless --fixed-fps 120 res://tests/fahrbot/fahrbot.tscn -- [--only=hang_35_quer] [--json=ergebnis.json]
```

Gibt eine Messwert-Tabelle aus und endet mit Exit-Code 1, wenn eine Metrik verfehlt wird.
Läuft in GitHub Actions bei jedem Push auf `main` und in Pull Requests. Im Editor: Szene öffnen und **F6** drücken.

Wichtig beim Starten von der Kommandozeile: `--rendering-driver` nie allein übergeben, sonst schaltet
Godot auf Forward+ statt Mobile.

## Kinderbeiträge

Zeichnungen dürfen ins Repo (gescannt, ohne Namen, Signatur, Alter oder Metadaten, Credit nur per Pseudonym).
**Sprachaufnahmen, Fotos und Videos der Kinder kommen nie ins öffentliche Repo.** `assets/kids_voice/`
steht in `.gitignore`, und der Pre-commit-Hook blockiert solche Dateien. Details: [ADR 0005](docs/decisions/0005-kinderbeitraege.md).

## Lizenzen

- Code: [MIT](LICENSE)
- Eigene Assets: [CC BY 4.0](assets/LICENSE)
- Fremdsoftware (Godot, Terrain3D, GUT): [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
