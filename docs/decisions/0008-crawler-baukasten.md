# ADR 0008 – Crawler-Baukasten (Garage)

**Status:** angenommen – Prototyp umgesetzt, Feel-Check und Kindertest offen
**Datum:** 2026-10-26
**Quelle:** Wunsch des Product Owners; Vorbilder in [docs/referenzen.md](../referenzen.md)

## Entscheidung

- **Garage als Startszene** (`scenes/garage/garage.tscn`). Links stehen die Kategorien, unten die Teile,
  oben rechts Würfel (Zufalls-Crawler) und Zielflagge (losfahren). Der Crawler steht auf einer Drehscheibe
  und wird bei jeder Änderung sofort neu gebaut.
- **Bedienung für 4-Jährige:**
  - Nur Antippen, kein Ziehen (ADR 0003); Auslösen bei Touch-Down.
  - Kein Text, nur gezeichnete Symbole.
  - Die Auswahl zeigt ein dicker Rahmen mit Haken, nicht nur eine Farbe.
  - Jede Berührung gibt Ton und Hüpfer (M5).
  - Alle Teile einer Kategorie passen in eine Reihe, Wischen ist nicht nötig.
- **Teile als Daten** in `src/vehicle/parts/part_catalog.gd`:
  - 10 Kategorien und 8 Vorlagen, insgesamt 48 Teile.
  - Fahrgestell 5, Räder 4, Achsen 2, Reifen 4, Federung 4, Motor 3, Lenkung 3, Aufbau 9 (inkl. Bagger und
    Radlader, ADR 0011), Farbe 8, Extras 6
    (mehrfach wählbar).
  - Physik-Werte stehen nur hier und in `vehicle_constants.gd`.
- **Bauplan → Fahrwerte:** `CrawlerDesign` (gewählte Teile) → `VehicleSpec` (berechnete Werte) → `KraxlVehicle`.
  - Feder, Dämpfer, Motor, Bremse und Parkbremse skalieren mit Radlast bzw. Masse.
  - Der Standard-Crawler entspricht den Werten aus ADR 0002.
- **Speichern** nur lokal unter `user://garage/crawler.json`. Keine Berechtigung, kein Netz.

## „Kein Scheitern“ für jede Kombination

Ein Kind darf keinen Crawler bauen können, der am Hang wegrutscht oder liegen bleibt. Deshalb prüft der
Fahrbot (Szenario `baukasten`) **109 Baupläne**:
- die volle Matrix aus Fahrgestell × Räder × Federung im ungünstigsten Aufbau (schwer, hoch, Portalachsen,
  glatte Reifen, alle Extras),
- jedes übrige Teil einzeln,
- alle Vorlagen.

Pflicht für jeden Bauplan:
- parken am 35°-Hang quer und bergauf (Drift ≤ 2 cm, Zittern ≤ 0,01 rad/s),
- nach dem Umkippen in < 3 s wieder aufrecht.

Die 30-cm-Stufe ist eine Eigenschaft und kein Pflichtwert; aktuell schaffen sie alle 109 Baupläne.

Was die Matrix aufgedeckt hat und wie es gelöst ist:

| Problem | Lösung |
|---|---|
| Monster-Räder + hohe Federung kippen quer am Hang (16 m gerollt) | Spur wächst mit dem Radius (`TRACK_WIDENING_PER_RADIUS`) |
| Kurz + Monster + Portal überschlägt sich bergauf nach hinten | Radstand wächst mit dem Radius (`WHEELBASE_STRETCH_PER_RADIUS`) |
| Leichtes Zittern bei kurzem Radstand und hohem Schwerpunkt | Parkbremse und Seitenführung rechnen mit der **effektiven Masse** am Kontaktpunkt (inkl. Drehträgheit) statt „Masse ÷ Räder“ |
| Nachwippen um die Querachse (1 Hz) bei weicher Federung | Dämpfung 13 → 18 N·s/m pro kg; weiche Federn behalten volle Dämpfer |
| Aufstellen 3–4 s, bei mehr Kraft Überschwingen | Aufstellhilfe als PD-Regler auf den Kippwinkel, umgerechnet über den Trägheitstensor |
| Schwerpunkt unabhängig von schweren Rädern | Schwerpunkt aus Aufbau und Rädern gewichtet |

## Offene Punkte

- Feel-Check der neuen Teile, vor allem Ketten (langsam), Krebsgang und Monster-Räder.
- Echte Modelle statt Grundformen (M7 bzw. Kenney Car Kit, CC0).
- Mehrere Stellplätze in der Garage (heute wird nur der letzte Crawler gespeichert).
