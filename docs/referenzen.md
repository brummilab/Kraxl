# Referenzen und Vorbilder

Stand: 26.10.2026. Hier steht, was wir übernommen haben und was bewusst nicht. Code aus fremden Projekten
kommt nur mit passender Lizenz ins Repo (MIT/CC0, ADR 0006). Bei allem anderen übernehmen wir nur Ideen.
Marken- und Modellnamen kommen nie ins Spiel.

## Open-Source-Projekte (GitHub)

| Projekt | Lizenz | Was wir daraus mitnehmen |
|---|---|---|
| [roge-rm/SnapRacers](https://github.com/roge-rm/SnapRacers) – Kart-Spiel mit Teile-Garage, Godot 4.7.2 + Jolt, für ein Kind gebaut | GPL-3.0 → **kein Code** | Ideen: Teile als Daten statt Code; Fertigfahrzeuge (→ unsere Vorlagen); direkt aus der Garage losfahren; Headless-Tests, die jedes Fahrzeug fahren (→ Baukasten-Matrix). Anders als dort: kein Drag & Drop, nur Antippen (ADR 0003) |
| [Dechode/Godot-Advanced-Vehicle](https://github.com/Dechode/Godot-Advanced-Vehicle) – Raycast-Fahrzeug, Reifenmodelle | MIT | Bestätigt die Wahl: eigener Rigidbody-Controller statt VehicleBody3D und Physik-Takt ≥ 120 Hz |
| [Kenney Car Kit](https://www.kenney.nl/assets/car-kit) (verlinkt von Dechode) | CC0 | Kandidat für Platzhalter-Modelle, bis eigene Blender-Modelle kommen (M7); vor Nutzung in `assets/SOURCES.md` eintragen |
| [Saitodepaula/Godot-6DOF-Vehicle-Demo](https://github.com/Saitodepaula/Godot-6DOF-Vehicle-Demo) – Monstertruck mit Gelenken | – | Gegenbeispiel: Gelenk-Fahrwerke sind instabiler als unser Ansatz, nicht übernommen |
| [libsdl-org/SDL #9916](https://github.com/libsdl-org/sdl/issues/9916), [#7524](https://github.com/libsdl-org/sdl/issues/7524) | – | 8BitDo-Controller melden je nach Modus A/B bzw. X/Y vertauscht → Knopf-Paare in ADR 0009 |

## Echte RC-Crawler (Modellbau)

Quellen:
- [Traxxas TRX-Series Truck Guide](https://traxxas.com/articles/trx4-truck-guide) mit TRX-4, TRX-6 und TRX-4M.
- Sortiment von [Modellbau Lindinger](https://www.lindinger.at/) laut Suchergebnissen, u. a. Absima CR18P,
  Arktos 6×6 und Tow Truck. Die Kategorieseite war per Abruf nicht erreichbar (Serverfehler 500).

| Vorbild | Im Baukasten |
|---|---|
| Portalachsen: Differential höher, mehr Bodenfreiheit, breitere Spur | Kategorie **Achsen**: normal / portal |
| Lift-Kit und lange Dämpfer (High Trail Edition) | Federung **hoch** |
| Große 2.2″-Reifen, Monstertrucks | Räder **groß** / **monster**, mit breiterer Spur und längerem Radstand |
| Verstellbarer Radstand (300–336 mm), lange Pickups | Fahrgestell **kurz** / **mittel** / **lang** |
| 6×6 mit Mittelachse (TRX-6, Absima Arktos) | Fahrgestell **sechsrad** |
| Ketten-Laufwerke (TRX-4 Sport mit Traxx) | Reifen **ketten** |
| 45°-Lenkeinschlag, Allradlenkung bei Mini-Crawlern | Lenkung **allrad** / **krebs** |
| Abschleppwagen mit Kran (Absima CR18P Tow Truck) | Aufbau **abschlepper** |
| LED-Licht, Seilwinde, Dachträger (Expedition Rack) | Extras **licht** / **seilwinde** / **dachtraeger** |
| Fertigmodelle (RTR) | **Vorlagen**: Geländewagen, Hochbeiner, Sechsrad-Riese, Kettenfahrer, Mini-Krabbler, Abschlepper |

Nicht übernommen, weil für 4-Jährige zu komplex: 2-Gang-Getriebe, Differenzialsperren, Kupplung,
Reifendruck. Die Motor-Stufen „gemütlich / normal / stark“ decken das spielerisch ab.
