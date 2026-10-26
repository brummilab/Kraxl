# ADR 0013 – Graben mit dem Bagger, Flieger

**Status:** angenommen – Feel-Check des Product Owners offen
**Datum:** 2026-10-26
**Quelle:** Wünsche des Product Owners: „mit dem Bagger in die Erde graben“, „einen Flieger einbauen“

## Entscheidung

### Graben mit dem Bagger

- **Bedienung** (wie bisher die Werkzeug-Taste):
  - Gamepad: rechten Stick nach unten halten oder rechten Stick drücken (R3).
  - Tastatur: E (zu zweit: E bzw. Bild ab). Touch: Schaufel-Taste.
- **Ablauf** (`src/world/digging.gd`), immer wenn der Arm ganz unten ankommt (`DIG_TRIGGER`) und die
  Löffelspitze den Boden erreicht:
  - Leerer Löffel: gräbt eine weiche Mulde (Radius 1,7 m, 0,45 m tief). Danach ist Erde im Löffel
    sichtbar, mit tiefem „Plumps“.
  - Voller Löffel: kippt einen Haufen aus (0,4 m hoch). Danach ist der Löffel leer, mit hellerem „Plumps“.
  - Also: graben, Arm hoch, ein Stück fahren, Arm runter = auskippen.
- Gegrabene Stellen werden erdbraun: Terrain3D-Textur „Erde“, Auto-Shader dort aus.
- **Grenzen gegen Steckenbleiben:**
  - höchstens 1,5 m tiefer bzw. höher als der Ursprungsboden (`DIG_MAX_DEPTH`, `PILE_MAX_HEIGHT`);
  - weiche Ränder, die Crawler hinein- und herausfahren lassen.
- **Technik:**
  - `Terrain3DData.set_height` und `update_maps(..., all_regions = true)`. Mit `false` aktualisiert
    Terrain3D 1.0.2 die Grafik nicht; im Kontrollbild aufgefallen.
  - Danach einmal `collision.update()`, damit Crawler in die Mulde fahren können. Das kostet am PC ca.
    17 ms pro Löffel, also nur einmal je Löffel und nicht pro Bild.
- Der Radlader schiebt weiterhin nur optisch. Mit der Schaufel zu schieben wäre eine eigene Erweiterung.

### Flieger

- Neuer Aufbau **„flieger“** und eine Vorlage (roter Flieger).
  - In der Garage blendet der Flieger alle Crawler-Kategorien aus; nur Vorlagen, Aufbau und Farbe
    bleiben. Regenbogen-Lack geht auch.
  - Im Gelände entsteht statt eines Crawlers ein `KraxlPlane` (`src/vehicle/kraxl_plane.gd`).
- **Spielzeug-Flug ohne Absturz** (`CharacterBody3D`, kein Rad-Controller):
  - ▲ (A/B, R, R2, W, ↑): Gas. Ab 9 m/s hebt er ab und steigt.
  - ▼ (X/Y, L, L2, S, ↓): in der Luft sinken, am Boden bremsen und langsam zurückrollen.
  - ◀ ▶: Kurve, in der Luft mit Schräglage (nur Optik).
  - Ohne Eingabe hält er Tempo (13 m/s) und Höhe.
  - Höchstens 30 m über Grund, also unter der 64 m hohen Weltrand-Wand.
  - Jede Bodenberührung ist eine Landung. Hänge bis 46° sind Rollbahn, steilere Flächen und Wände
    lassen ihn entlanggleiten.
- Flugwerte nur in `vehicle_constants.gd` (`PLANE_*`).
- Ton: Propellermotor (Tonhöhe folgt dem Tempo), Hupe etwas höher.
- Zwei Spieler: Jeder kann Flieger oder Crawler wählen.
- **Ausgenommen:**
  - Die Baukasten-Matrix prüft nur Crawler.
  - Der Flieger hat ein eigenes Fahrbot-Szenario: abheben, Höhe halten, Kurve, Höchstgrenze, nie unter
    den Boden, landen und stehen.

## Tests

- Fahrbot `terrain3d_graben`: Mulde ≥ 0,25 m, Löffel voll; Haufen ≥ 0,2 m, Löffel leer; Durchfahren
  aufrecht, nicht aus der Welt.
- Fahrbot `flieger`: 6 Pflichtwerte (siehe oben).
- UI-Test: Flieger in der Garage (steht still, Kategorien ausgeblendet und wieder da); Bagger-Spitze
  senkt sich, Erde im Löffel, Signal `bucket_changed`.
- Rauchtest der Spielszene mit Flieger (ein und zwei Spieler) lokal grün.

## Offen

- Feel-Check: Ist die Flug-Steuerung für 4-Jährige verständlich? Tempo, Steigrate, Kurve.
- Graben: Tiefe pro Löffel, Bedienung „Arm runter = graben bzw. auskippen“.
