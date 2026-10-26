# ADR 0009 – Gamepad-Unterstützung (8BitDo SN30 Pro)

**Status:** angenommen – im Code und per Test abgesichert, Test mit echtem Controller offen
**Datum:** 2026-10-26

## Kontext

Der 8BitDo SN30 Pro hat mehrere Modi und meldet je nach Modus und System die Knöpfe unterschiedlich:
- X-Input (Start + X) unter Windows,
- D-Input/Android (Start + B),
- Switch (Start + Y),
- macOS (Start + A).

Die Beschriftung folgt Nintendo (A rechts, B unten). Je nach Modus meldet SDL A/B und X/Y vertauscht
(SDL-Issues #9916, #7524). Godot nutzt die SDL-Controller-Datenbank. Außerdem belegt Godot 4.7 die
Menü-Actions (`ui_accept`, `ui_left` …) **nicht** mit Gamepad-Knöpfen; das hat der UI-Test aufgedeckt.

## Entscheidung

Belegung in `src/input/kraxl_input.gd`, ausgelesen über `ActionInputSource` (eine `InputSource`, M1):

| Aktion | Gamepad | Tastatur |
|---|---|---|
| Vorwärts | A **und** B (beide rechten Knöpfe), R, R2 | ↑ / W |
| Rückwärts | X **und** Y (beide linken Knöpfe), L, L2 | ↓ / S |
| Lenken | Steuerkreuz, linker Stick (Totzone 0,3) | ← → / A D |
| Garage | Select | G / Esc |
| Garage: Karte wechseln | Steuerkreuz, linker Stick | Pfeiltasten |
| Garage: auswählen | A **und** B | Enter / Leertaste |
| Garage: losfahren | Start | – |

- **Knopf-Paare:** Ein Tausch A↔B oder X↔Y ändert nichts an der Bedeutung. Das Kind muss keine Buchstaben
  lesen: rechte Daumen-Knöpfe fahren vorwärts, linke rückwärts.
- **Trigger** werden als Achse gelesen (analog oder digital, je nach Modus).
- **Keine Vibration:** Auf Android braucht sie die Berechtigung `VIBRATE`, und das APK muss ohne
  Berechtigungen auskommen (ADR 0007). Bluetooth-Gamepads brauchen keine App-Berechtigung, weil das System
  sie als Eingabegerät einbindet.
- Knöpfe in der Spielszene haben `focus_mode = NONE`, damit der Gas-Knopf nicht versehentlich
  „Fahrbot 5 min“ auslöst.

## Tests

`tests/ui/ui_test.tscn` speist Gamepad-Events ein und prüft:
- alle Fahraktionen, Trigger, Stick und Totzone,
- Select → Garage,
- die Menü-Belegung.

Der Test schlägt bei jedem Skriptfehler fehl (Logger-API).

## Am Spike-Tag mit dem echten SN30 Pro prüfen

1. Windows, X-Input (Start + X): alle Zeilen der Tabelle oben.
2. Android, Bluetooth (Start + B koppeln): dasselbe.
3. Falls ein Knopf nichts tut: Firmware des Controllers aktualisieren (8BitDo Ultimate Software). Alte
   Firmware hat laut Moonlight-Issue #978 falsche Mappings. Danach neu koppeln.
