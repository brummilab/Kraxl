# ADR 0009 – Gamepad-Unterstützung (8BitDo SN30 Pro, USB Wireless Adapter 2)

**Status:** angenommen – Windows mit Adapter 2 bestätigt („XInput Controller, bekannt“), Android offen
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
| Hupe | linken Stick drücken (L3) | H / Leertaste |
| Licht an/aus (im Gelände) | Start | L |
| Werkzeug senken (Bagger, Radlader) | rechten Stick nach unten oder drücken (R3) | E |
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

- Seit ADR 0011 liegt die Hupe nur noch auf L3; R3 und der rechte Stick bedienen das Werkzeug.
- Zwei Spieler (ADR 0012): Das erste angeschlossene Gamepad steuert Spieler 1, das zweite Spieler 2,
  mit derselben Belegung. Tastatur: Spieler 1 WASD, Spieler 2 Pfeiltasten.

## 8BitDo USB Wireless Adapter 2

Der Adapter (USB-Dongle, am Handy per OTG-Kabel) koppelt einen Controller per Bluetooth: SN30 Pro,
Xbox-, PlayStation- oder Switch-Pro-Controller. Er meldet sich dann selbst als Gamepad. Abdeckung in
Godot 4.7.2 (geprüft in `core/input/gamecontrollerdb.txt`, Tag 4.7.2-stable):

| System / Modus | Eintrag in Godots Datenbank |
|---|---|
| Windows, X-Input (Standard des Adapters) | allgemeiner XInput-Controller |
| Windows, D-Input | „8BitDo Adapter 2“ (`03000000c82d00000531…`) |
| macOS | „8BitDo Adapter 2“ |
| Linux | „8BitDo Adapter 2“ (`03000000c82d00000631…`) |
| Android (OTG) | „8BitDo Adapter 2“ |

- Auch der Adapter meldet je nach Modus A/B vertauscht; die Knopf-Paare decken das ab.
- Android braucht für einen USB- oder Bluetooth-Controller **keine** App-Berechtigung, weil das System ihn
  als Eingabegerät einbindet. Das APK bleibt ohne `uses-permission`.
- **Absicherung gegen unbekannte Firmware-IDs:**
  - Die Statuszeile im Spiel und das Log (`[Gamepad] verbunden: …`) zeigen Name, bekannt/UNBEKANNT und GUID.
  - Für ein unbekanntes Gerät eine SDL-Mapping-Zeile in `data/gamecontrollerdb_extra.txt` eintragen; sie
    wird beim Start geladen (`KraxlInput.load_extra_mappings`).
  - Die Datei ist per `include_filter` in beiden Export-Presets enthalten.
- Mehrere Controller gleichzeitig (Adapter + Bluetooth-Pad) steuern dasselbe Fahrzeug (Actions mit
  `device = -1`).

## Tests

`tests/ui/ui_test.tscn` speist Gamepad-Events ein und prüft:
- alle Fahraktionen, Trigger, Stick und Totzone,
- Select → Garage,
- die Menü-Belegung.

Der Test schlägt bei jedem Skriptfehler fehl (Logger-API).

## Am Spike-Tag mit dem echten SN30 Pro prüfen

1. Windows, X-Input (Start + X): alle Zeilen der Tabelle oben.
2. Android, Bluetooth (Start + B koppeln): dasselbe.
3. 8BitDo USB Wireless Adapter 2 am PC (USB) und am Android-Gerät (OTG-Kabel), jeweils mit dem SN30 Pro
   gekoppelt. Die Statuszeile muss „bekannt“ zeigen; dann die Belegungstabelle durchgehen.
4. Falls ein Knopf nichts tut: Firmware des Controllers aktualisieren (8BitDo Ultimate Software). Alte
   Firmware hat laut Moonlight-Issue #978 falsche Mappings. Danach neu koppeln.
5. Zeigt die Statuszeile „UNBEKANNT“: GUID notieren und eine Mapping-Zeile in
   `data/gamecontrollerdb_extra.txt` ergänzen (siehe Kopf der Datei).
