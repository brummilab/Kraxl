class_name VehicleConstants
## Einziger Ort für Fahrphysik-Konstanten (ADR 0002).
## Änderungen nur mit Vorher/Nachher-Metriktabelle und Feel-Check.

## Muss mit physics/common/physics_ticks_per_second in project.godot übereinstimmen.
const PHYSICS_TICKS_PER_SECOND := 120

## Unterhalb dieser Kontaktgeschwindigkeit (m/s) und ohne Gas-Input greift die Parkbremse.
const PARK_SPEED_THRESHOLD := 0.3

## Untergrenze für |v| in Schlupf-Berechnungen; verhindert Division durch Werte nahe 0.
const MIN_SLIP_SPEED := 0.5

## Abnahme-Metriken des Fahrbots.
const TARGET_HILL_ANGLE_DEG := 35.0
const MAX_PARKED_DRIFT_M := 0.02          # in 10 s am 35°-Hang
const MAX_PARKED_ANGULAR_VELOCITY := 0.01 # rad/s im Stand
const TEST_GAP_WIDTH_M := 0.15            # Rad darf darin nicht einsinken
const TARGET_STEP_HEIGHT_M := 0.30
const MAX_SELF_RIGHT_TIME_S := 3.0
