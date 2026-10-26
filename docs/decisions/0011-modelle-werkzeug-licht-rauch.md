# ADR 0011 – Bessere Modelle, Bagger und Radlader, Licht, Auspuffrauch, PC-Bildschirm

**Status:** angenommen – Feel-Check des Product Owners offen
**Datum:** 2026-10-26
**Quelle:** Wünsche des Product Owners nach dem ersten Windows-Test („Lichter ausschalten“, „bessere
3D-Modelle“, „die großen Pfeile stören am PC“, „auch einen Bagger“, „Auspuffrauch“)

## Entscheidung

### 3D-Modelle: Kenney Car Kit (CC0)

- Karosserien und Räder stammen aus dem **Kenney Car Kit** (https://kenney.nl/assets/car-kit, CC0) und liegen
  in `assets/models/kenney/`. CC0 passt zu ADR 0006; die Herkunft ist in `assets/SOURCES.md` eingetragen.
- Die Physik bleibt beim Bauplan (`VehicleSpec`). `src/vehicle/kenney_models.gd` richtet die Modelle nur aus:
  - Die Karosserie wird so skaliert, dass ihre Radkästen über unseren Rädern in Ruhelage sitzen.
    Kenney blickt nach +Z, wir nach −Z.
  - Die Kenney-Räder der Karosserie entfallen, unsere eigenen Räder drehen sich.
  - Linke Räder werden um 180° gedreht, nicht negativ skaliert. So zeigt die Nabe nach außen.
- **Lackfarbe:** Die Modelle nutzen eine gemeinsame Palette (8 × 4 Kacheln). Ein Shader färbt die
  vorherrschende bunte Kachel jedes Modells in der Garage-Farbe um und behält die Schattierung. Glas, Grau,
  Weiß und Schwarz bleiben unverändert.
- Zuordnung:
  - Geländewagen → `suv`, Pickup → `truck`, Traktor → `tractor`
  - Kipper und Abschlepper → `truck-flat` mit gezeichneter Mulde bzw. gezeichnetem Kran
  - Feuerwehr → `firetruck`, Radlader → `tractor-shovel`
  - Reifen: Stollen → `wheel-truck`, glatt → `wheel-default`, Matsch → `wheel-tractor-back`
- Buggy, Bagger und Ketten bleiben gezeichnet, weil das Kit dafür nichts Passendes hat.

### Bagger und Radlader

- Zwei neue Aufbauten mit eigenen Vorlagen. Danach gibt es 9 Aufbauten, 8 Vorlagen und 48 Teile.
- **Werkzeug-Taste:**
  - Gamepad: rechten Stick nach unten oder R3 drücken; Tastatur: E; Touch: Schaufel-Taste.
  - Solange gedrückt, senkt sich der Bagger-Arm (Ausleger, Stiel, Löffel) bzw. die Radlader-Schaufel. Beim
    Loslassen fährt das Werkzeug langsam wieder hoch (`TOOL_SPEED`).
- Das Werkzeug ist **reine Optik ohne Kollision**. Es kann das Fahrzeug nicht anheben oder umwerfen, also
  gilt die Baukasten-Matrix unverändert. Echtes Graben ist ein eigenes, späteres Thema.
- Masse, Kabine und Schwerpunkt stehen im Teilekatalog. Beide Aufbauten bestehen die Baukasten-Matrix.

### Licht schaltbar

- Gamepad: Start; Tastatur: L; Touch: Lampen-Taste (nur sichtbar, wenn das Extra „Licht“ verbaut ist).
- Jeder Druck schaltet einmal um (steigende Flanke). Das Licht ist beim Losfahren an.
- In der Garage startet Start weiterhin das Losfahren; im Gelände schaltet Start das Licht.
- Die Hupe liegt deshalb nur noch auf L3; R3 gehört dem Werkzeug.

### Auspuffrauch

- Jedes Fahrzeug pafft graue Wölkchen, die aufsteigen, wachsen und verblassen (`src/vehicle/exhaust_smoke.gd`).
  - Ohne Extra „Auspuff“: ein kurzes Endrohr hinten.
  - Mit Extra: aus beiden senkrechten Rohren.
- Im Leerlauf raucht es leise (25 %), mit Gas kräftiger. Das ist eine Rückmeldung ohne Text.
- `GPUParticles3D` mit `amount_ratio`. Das läuft im Mobile- und im Compatibility-Renderer. `CPUParticles3D`
  kennt `amount_ratio` nicht.
- Der Rauch ist reine Optik. Im Fahrbot ist er aus (`vehicle.smoke = false`).

### PC-Bildschirm: Touch-Tasten nur bei Touch

- Die großen Pfeil-Tasten erscheinen beim Start nur, wenn das Gerät einen Touchscreen hat.
- Ein Tastatur- oder Gamepad-Druck blendet sie aus, eine Berührung blendet sie wieder ein. Ausgeblendet wird
  nur, solange kein Finger auf einer Taste liegt; so verschwinden sie nicht unter einem haltenden Kind.
- **Entwickler-Anzeige** (Statuszeile mit FPS und Controller, Knopf „Fahrbot 5 min“): in Release-Builds
  aus, mit **F3** umschaltbar und mit `-- --dev` von Anfang an sichtbar.

## Tests

`tests/ui/ui_test.tscn` prüft:
- Kenney-Kacheln und -Räder; jede Vorlage mit Kenney-Karosserie,
- das Umschalten von Licht und Scheinwerfern,
- Werkzeug-Bewegung bei Bagger und Radlader,
- Rauch: ein Endrohr ohne Extra, zwei Rohre mit Extra, mehr Rauch bei Gas,
- Ein- und Ausblenden der Touch-Tasten, keine Überlappung mit Licht- und Werkzeug-Taste.

## Offen

- Feel-Check (`docs/feel-check.md`): Werkzeug-Taste, Licht-Taste, Rauchmenge.
- Bagger-Pose und Lampenposition an den Kenney-Karosserien optisch nachjustieren, falls nötig.
