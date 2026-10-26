# ADR 0012 – Zwei Spieler, bunte Farben, Weltrand, Updater

**Status:** angenommen – Feel-Check des Product Owners offen
**Datum:** 2026-10-26
**Quelle:** Wünsche des Product Owners nach dem zweiten PC-Test: „Zwei-Spieler-Modus“, „bunte Farben“,
„automatisches Update, das mit GitHub synct“, „der Fahrer fällt noch“ (= fährt über den Geländerand ins Leere)

## Entscheidung

### Zwei Spieler: geteilter Bildschirm

- In der Garage schaltet die **Figuren-Karte** zwischen einem und zwei Spielern um. Bei zwei Spielern
  wählen zwei **Helm-Karten** (Helm mit einem bzw. zwei Punkten), wessen Crawler gebaut wird.
  Jeder Spieler hat einen eigenen Bauplan (`user://garage/crawler.json` bzw. `crawler_2.json`).
  Die Spielerzahl steht in `user://garage/spieler.json`.
- Im Gelände ist der Bildschirm links/rechts geteilt (zwei `SubViewport`s in derselben 3D-Welt, weiße
  Trennlinie). Jede Hälfte hat eigene Kamera und eigene Touch-Tasten.
- Die Hauptansicht zeichnet dann kein 3D. Ihre Kamera steht in der Mitte zwischen beiden Crawlern; an ihr
  richtet Terrain3D seine Detailstufen aus, und sie ist der Hörpunkt für die Geräusche.
- **Eingabe** (`ActionInputSource.new(spieler)`):

| | Spieler 1 (links) | Spieler 2 (rechts) |
|---|---|---|
| Gamepad | erstes angeschlossenes | zweites angeschlossenes |
| Fahren | W A S D | Pfeiltasten |
| Hupe / Licht / Werkzeug | Leertaste / Q / E | Enter / Ende / Bild ab |
| Touch | linke Bildschirmhälfte | rechte Bildschirmhälfte |

  - Die Gamepads werden direkt je Gerät abgefragt (`KraxlInput.pad_strength`). Die Knopf-Belegung
    (`KraxlInput.PAD`) ist dieselbe wie im Ein-Spieler-Modus.
  - Select (Garage) gilt für beide Spieler.
- Im Ein-Spieler-Modus bleibt alles wie bisher: alle Tasten und alle Gamepads steuern den einen Crawler.

### Bunte Farben

- **Lack:** 13 Farben, darunter Hellgrün, Türkis, Himmelblau, Pink und **Regenbogen**. Die bisherigen
  Farben sind satter.
  - Mehr als 9 Teile stehen in der Garage in zwei Reihen; Wischen bleibt unnötig.
  - Regenbogen-Lack (`Paint`) hängt an der Weltposition: Die Farben wandern beim Fahren über den Crawler.
- **Kräftigere Fahrzeuge:**
  - Kenney-Karosserien: Die grauen Zierteile (Stoßstangen, Schweller) bekommen einen dunkleren Ton des
    Lacks.
  - Die Felgen bekommen den Lack selbst.
- **Buntere Welt** (`src/world/playground.gd`):
  - Kräftigerer Himmel und sattere Wiese; außerhalb des Geländes eine flache Fläche bis zum Horizont
    statt Leere.
  - 1800 Blumen in sechs Farben (MultiMesh, nur Optik, ohne Kollision).
  - Bunte Kegel (Slalom, Kreis) und ein Kistenturm aus dem Kenney Car Kit zum Umschubsen. Massen in
    `vehicle_constants.gd` (`TOY_*`).
  - Feste Zufallszahl: Die Welt sieht immer gleich aus, die FPS-Messrunde bleibt vergleichbar.

### Weltrand („der Fahrer fällt“)

- Die Region ist 256 × 256 m groß; dahinter gab es keinen Boden, ein Crawler fiel ins Leere.
- Jetzt steht 3 m vor dem Rand ein bunter Zaun (Pfosten mit Kugeln) mit einer unsichtbaren, 80 m hohen
  Wand (`src/world/world_border.gd`). Der Crawler fährt einfach dagegen.
- Sicherheitsnetz: Ist ein Crawler doch außerhalb oder mehr als 6 m unter dem Boden, steht er sofort
  wieder an seinem Startplatz (`KraxlVehicle.reset_to`). Es gibt keine Meldung und keinen Ton – kein
  Scheitern.
- Fahrbot-Szenario `terrain3d_rand`: 10 s Vollgas auf den Rand zu. Pflicht: mindestens 1 m Abstand zum
  Rand, nie aus der Welt.

### Updater neben der Exe (das Spiel bleibt offline)

- Kinder-Regel 3 und ADR 0007 bleiben: **Das Spiel selbst geht nie ins Internet**, und das APK hat keine
  Berechtigung.
- **CI:**
  - Bei jedem grünen Push auf `main` veröffentlicht die CI ein öffentliches GitHub-Release `build-<Nummer>`
    mit `Kraxl-windows.zip`, der SHA-256-Prüfsumme und `version.txt`.
  - Das Release wird als „latest“ markiert; nur die letzten 5 Builds bleiben.
- **`Kraxl-Update.cmd`** liegt im Spielordner; ein Erwachsener startet es per Doppelklick.
  `Kraxl-Update.ps1` (PowerShell 5.1, ohne Zusatzprogramme, ohne Anmeldung):
  1. Vergleicht die eigene `version.txt` mit `releases/latest/download/version.txt`.
  2. Wartet, bis Kraxl beendet ist.
  3. Lädt die ZIP und prüft die SHA-256-Prüfsumme. Bei Fehlern wird nichts verändert.
  4. Ersetzt die Dateien. Gespeicherte Crawler in `%APPDATA%` bleiben erhalten.
  5. Bietet an, Kraxl zu starten.
- Die Versionsnummer („Build 42 (2b6a8bc, 2026-10-26)“) steht auch in der F3-Anzeige des Spiels.
- In der Cloud mit PowerShell 7.4 und einem lokalen Testserver geprüft: Update, „schon aktuell“ und
  beschädigter Download (Exit 1, nichts verändert).
- Android: Updates später über den Store bzw. per APK-Installation; dort kein Updater.

## Tests

- `tests/ui/ui_test.tscn`:
  - Tastenhälften und Gamepads je Spieler; Touch-Hälften
  - Spielerzahl und Bauplan je Spieler, Farben in zwei Reihen
  - Regenbogen-Shader, Felgen-Lack
  - Weltrand: `is_lost`, Wände und Zaun
  - Blumen und Spielzeug
- Fahrbot: Szenario `terrain3d_rand`; die Baukasten-Matrix prüft auch alle neuen Farben.
- CI: zusätzlicher Rauchtest der Spielszene mit `--spieler=2`.

## Offen

- Feel-Check: geteilter Bildschirm am Fernseher bzw. Tablet, zwei Gamepads, Farben.
- Ton im Zwei-Spieler-Modus: Der Hörpunkt liegt in der Mitte. Bei großem Abstand klingen beide Crawler
  leiser.
