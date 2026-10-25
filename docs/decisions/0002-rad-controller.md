# ADR 0002 – Eigener Rad-Controller mit ShapeCast, Parkbremse und 120 Hz

**Status:** angenommen
**Datum:** 2026-10-25
**Quelle:** Plan-Verbesserungen H2

## Kontext

`VehicleBody3D` rutscht am Hang auch gebremst und sinkt in Spalten ein (Godot-Issues #88998, #98079);
ein Wechsel auf Jolt behebt das nicht. Eigene Raycast-Controller zittern im Stand, wenn das Reifenmodell
bei v ≈ 0 durch kleine Werte teilt, und liefern mit veralteten Raycasts Versatz.

## Entscheidung

1. Pro Rad ein `ShapeCast3D` (Kugel/Zylinder in Radgröße) statt `RayCast3D`;
   Abfrage per `force_shapecast_update()` im `_physics_process`.
2. Reifenmodell mit Haftreibungszone: unter `PARK_SPEED_THRESHOLD` (0,3 m/s) und ohne Gas-Input wird die
   Kontaktgeschwindigkeit pro Rad per Gegen-Impuls auf 0 gezogen („Parkbremse“). Keine Division durch |v| nahe 0.
3. Physics Ticks per Second = 120, Physik-Interpolation an. Werte in `src/vehicle/vehicle_constants.gd`.
4. Jolt-Sleep für Fahrzeuge deaktiviert, solange ein Kind drin sitzt.

## Abnahme-Metriken (Fahrbot)

| Metrik | Ziel |
|---|---|
| Drift am 35°-Hang im Stand | < 2 cm in 10 s |
| Winkelgeschwindigkeit im Stand | < 0,01 rad/s |
| Rad-Einsinken in 15-cm-Spalt | 0 |
| 30-cm-Stufe | überwindbar |
| Aufstellen nach Umkippen | < 3 s |

Achtung: Das Fahrverhalten ändert sich beim Wechsel der Tickrate – Tickrate nicht nachträglich anfassen,
ohne alle Metriken neu zu messen.
