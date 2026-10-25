# Kraxl

Offline-Sandkasten-Fahrspiel für Kinder ab 4 Jahren (Windows + Android), gebaut mit Godot.
Kein Scheitern, keine Werbung, keine Käufe, kein Internet, keine Datenerfassung.

## Status

Projektfundament angelegt (Oktober 2026). Noch kein spielbarer Stand. Nächster Schritt ist der
**Spike-Tag**: Terrain3D auf Godot 4.7.2 prüfen (siehe [ADR 0001](docs/decisions/0001-godot-version-pin.md)).

## Technik-Eckdaten

| Bereich | Festlegung |
|---|---|
| Engine | Godot **4.7.2-stable** (Rückfallebene 4.6.3), siehe `.tool-versions` |
| Physik | Jolt Physics (explizit gesetzt), 120 Ticks/s, Physik-Interpolation an |
| Fahrzeuge | Eigener Rad-Controller mit ShapeCast3D + „Parkbremse“, kein VehicleBody3D |
| Renderer | Mobile (Windows und Android) |
| Terrain | Terrain3D (Version wird am Spike-Tag gepinnt), max. 8 Boden-Texturen ≤ 1024² |
| Steuerung | „Kleine Hände“: große Halte-Tasten, Auslösen bei Touch-Down; Joystick nur optional |
| Tests | GUT (passend zur Godot-Minor), `-gexit`, JUnit-XML |
| Android | APK ohne jede `uses-permission` (wird im CI-Gate geprüft) |

## Struktur

```
docs/
  plan-verbesserungen-2026-10.md   priorisierte Verbesserungen (H1–H6, M1–M7, L1–L4)
  decisions/                        Architekturentscheidungen (ADRs)
  feel-check.md                     Checkliste für die Probefahrt des Product Owners
  dependencies.md                   Abhängigkeiten inkl. Prüfung „sammelt Daten?“
assets/
  LICENSE                           CC BY 4.0 für eigene Assets
  SOURCES.md                        Herkunft von Fremd-Assets (nur CC0)
  kids_drawings/                    Kinderzeichnungen (ohne Namen/Metadaten)
src/vehicle/vehicle_constants.gd    Physik-Konstanten (einziger Ort dafür)
scripts/hooks/pre-commit            Schutz für Kinderbeiträge
CLAUDE.md                           nicht verhandelbare Regeln für Agenten
Projektinhalt.md                    laufende Projektübersicht
```

## Einrichtung

```sh
git clone https://github.com/brummilab/Kraxl
cd Kraxl
sh scripts/install-hooks.sh   # Pre-commit-Hook für Kinderbeiträge aktivieren
```

Dann das Projekt mit Godot 4.7.2-stable öffnen.

## Kinderbeiträge

Zeichnungen dürfen ins Repo (gescannt, ohne Namen, Signatur, Alter oder Metadaten, Credit nur per Pseudonym).
**Sprachaufnahmen, Fotos und Videos der Kinder kommen nie ins öffentliche Repo.** `assets/kids_voice/`
steht in `.gitignore`, und der Pre-commit-Hook blockiert solche Dateien. Details: [ADR 0005](docs/decisions/0005-kinderbeitraege.md).

## Lizenzen

- Code: [MIT](LICENSE)
- Eigene Assets: [CC BY 4.0](assets/LICENSE)
- Fremdsoftware (Godot, Terrain3D, GUT): [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
