# ADR 0002 – Eigener Rad-Controller mit ShapeCast, Parkbremse und 120 Hz

**Status:** angenommen – erster Prototyp umgesetzt, Feel-Check offen
**Datum:** 2026-10-25
**Quelle:** Plan-Verbesserungen H2

## Kontext

`VehicleBody3D` rutscht am Hang auch gebremst und sinkt in Spalten ein (Godot-Issues #88998, #98079);
ein Wechsel auf Jolt behebt das nicht. Eigene Raycast-Controller zittern im Stand, wenn das Reifenmodell
bei v ≈ 0 durch kleine Werte teilt, und liefern mit veralteten Raycasts Versatz.

## Entscheidung

1. Pro Rad ein `ShapeCast3D` (Kugel in Radgröße) statt `RayCast3D`;
   Abfrage per `force_shapecast_update()` im `_physics_process`.
2. Reifenmodell mit Haftreibungszone: unter `PARK_SPEED_THRESHOLD` (0,3 m/s) und ohne Gas-Input greift die
   „Parkbremse“. Keine Division durch |v| nahe 0.
3. Physics Ticks per Second = 120, Physik-Interpolation an. Werte in `src/vehicle/vehicle_constants.gd`.
4. Jolt-Sleep für Fahrzeuge deaktiviert, solange ein Kind drin sitzt (`KraxlVehicle.occupied`).

## Umsetzung (Prototyp)

Code: `src/vehicle/kraxl_vehicle.gd`, `src/vehicle/vehicle_wheel.gd`, Eingaben über `src/input/` (M1).

Beim Messen sind drei Fallstricke aufgetaucht. Sie stehen hier, damit niemand sie wieder einbaut:

| Problem | Ursache | Lösung |
|---|---|---|
| Fahrzeug rollte vom 35°-Hang (93 m in 10 s) | Ausroll-Bremse (500 N/Rad) schwächer als Hangabtrieb (≈ 563 N/Rad), Parkbremse griff nie | Hangabtrieb wird ohne Gas immer gegengehalten, verteilt nach Radlast |
| Zittern im Stand (0,07 rad/s) | `safe_fraction` des ShapeCasts ist grob gerastert (mm-Sprünge pro Tick) → Dämpfer erzeugt ±300 N Rauschen | Radabstand exakt aus Kontaktpunkt und -normale berechnet |
| Schwingung im 2-Tick-Takt (0,03 rad/s) | Geschwindigkeit pro Rad in einem Tick komplett aufheben koppelt über 4 Räder mit ~Faktor 2 in die Gierdrehung | `PARK_GAIN` und `LATERAL_GRIP` = 0,5 |
| Kriechen 4–7 cm / 10 s | Karosserie am Hang 1,8° geneigt → Federkräfte zeigen hangabwärts | Parkbremse hält eine gemerkte Lage (`PARK_HOLD_STIFFNESS_PER_KG`), Anker rutscht ab 10 cm mit |

Nachträge vom 26.10.2026 aus der Baukasten-Matrix (ADR 0008):
- Parkbremse und Seitenführung rechnen mit der **effektiven Masse** am Kontaktpunkt statt „Masse ÷ Räder“.
- Dämpfung 1300 → 1800 N·s/m beim Standard-Crawler.
- Die Aufstellhilfe ist jetzt ein PD-Regler auf den Kippwinkel.
- Alle Werte skalieren mit Radlast bzw. Masse (`*_PER_KG`).

## Abnahme-Metriken (Fahrbot)

Aufruf: `godot --headless --fixed-fps 120 res://tests/fahrbot/fahrbot.tscn` (läuft auch in der CI).
Messung vom 26.10.2026 (Standard-Crawler nach dem Baukasten-Umbau), Godot 4.7.2 + Jolt + Terrain3D 1.0.2:

| Szenario | Metrik | Wert | Ziel | ok |
|---|---|---|---|---|
| stand_eben | Winkelgeschw. im Stand | 0,0000 rad/s | ≤ 0,01 rad/s | ✅ |
| stand_eben | Drift in 5 s | 0,0 mm | ≤ 2 cm | ✅ |
| hang_35_bergauf | Drift in 10 s | 0,0 mm | ≤ 2 cm | ✅ |
| hang_35_bergauf | Winkelgeschw. im Stand | 0,0001 rad/s | ≤ 0,01 rad/s | ✅ |
| hang_35_quer | Drift in 10 s | 0,0 mm | ≤ 2 cm | ✅ |
| hang_35_quer | Winkelgeschw. im Stand | 0,0001 rad/s | ≤ 0,01 rad/s | ✅ |
| lenken | Drehung in 6 s (Vollausschlag) | 385° | ≥ 180° | ✅ |
| lenken | Kippen (cos Neigung) | 0,999 | ≥ 0,9 | ✅ |
| stufe_30cm | Zeit bis oben (Vollgas) | 1,8 s | ≤ 8 s | ✅ |
| spalt_15cm | Rad-Einsinken | 16,9 mm | ≤ 2 cm ¹ | ✅ |
| spalt_15cm | Strecke nach dem Spalt | 16,2 m | ≥ 3 m | ✅ |
| aufstellen | Zeit bis aufrecht | 2,0 s | ≤ 3 s | ✅ |
| terrain3d_hang_quer | Drift in 10 s | 0,0 mm | ≤ 2 cm | ✅ |
| terrain3d_hang_quer | Winkelgeschw. im Stand | 0,0002 rad/s | ≤ 0,01 rad/s | ✅ |
| baukasten (105 Baupläne) | schlechteste Drift / Zittern / Aufstehzeit | 0,2 mm / 0,002 rad/s / 2,2 s | ≤ 2 cm / 0,01 / 3 s | ✅ |

Vorher (25.10.) zum Vergleich: Einsinken 14,8 mm, Aufstellen 2,3 s, Drehung 392°; alle übrigen Werte gleich.

¹ **Abweichung vom Plan („Einsinken = 0“), Entscheidung des Product Owners nötig:**
- Ein rundes Rad mit r = 0,4 m sinkt in einen 15-cm-Spalt geometrisch zwangsläufig 7 mm ein.
- Jolt meldet Kontaktpunkte an Kanten zusätzlich um etwa 6 mm ungenau.
- Der Fehler aus dem Plan (VehicleBody3D: Rad fällt ganz in den Spalt) tritt nicht auf.
- Die Grenze ist daher auf 2 cm gesetzt.

## Offene Punkte

- **Fahrgefühl:** `LATERAL_GRIP` = 0,5 macht das Fahrzeug etwas rutschiger als 0,9. Beim Feel-Check prüfen.
- **Jolt-Warnung:** Einmal trat „job system exceeded the maximum number of jobs“ auf, als das Fahrzeug von
  einer Testplatte fiel. Danach kam sie nicht wieder. Beobachten.
- Die Schwellen der Metriken sind Startwerte und werden mit dem Fahrbot-Ergebnis auf Windows (Spike-Tag)
  abgeglichen.

Achtung: Das Fahrverhalten ändert sich beim Wechsel der Tickrate. Tickrate nicht nachträglich anfassen,
ohne alle Metriken neu zu messen.
