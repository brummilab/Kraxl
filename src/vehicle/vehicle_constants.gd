class_name VehicleConstants
## Einziger Ort für Fahrphysik-Konstanten (ADR 0002).
## Änderungen nur mit Vorher/Nachher-Metriktabelle und Feel-Check.

## Muss mit physics/common/physics_ticks_per_second in project.godot übereinstimmen.
const PHYSICS_TICKS_PER_SECOND := 120

# --- Karosserie (Spike-Fahrzeug: kleiner Geländewagen) ---
const MASS_KG := 400.0
const BODY_SIZE_M := Vector3(1.4, 0.6, 2.4)  # Breite, Höhe, Länge
const CENTER_OF_MASS_Y_M := -0.35  # tiefer Schwerpunkt gegen Umkippen

# --- Räder und Federung ---
const WHEEL_RADIUS_M := 0.4
const WHEEL_TRACK_M := 1.5  # Abstand linkes/rechtes Rad
const WHEEL_BASE_M := 1.8  # Abstand Vorder-/Hinterachse
const WHEEL_MOUNT_Y_M := -0.1  # Aufhängungspunkt relativ zum Karosserie-Ursprung
const SUSPENSION_TRAVEL_M := 0.35
const SPRING_STIFFNESS := 9000.0  # N/m pro Rad
const SPRING_DAMPING := 1300.0  # N·s/m pro Rad (~0,7 × kritisch)
const MAX_SUSPENSION_FORCE := 12000.0  # N pro Rad, Schutz bei ShapeCast-Überlappung

# --- Antrieb und Reifen ---
const ENGINE_FORCE := 3200.0  # N gesamt, Allrad
const MAX_SPEED_MPS := 6.0  # ~22 km/h, kindgerecht
const REVERSE_SPEED_FACTOR := 0.5
const BRAKE_FORCE := 4000.0  # N gesamt, wenn Gas gegen Fahrtrichtung
const ROLLING_RESISTANCE := 0.03  # × Normalkraft
const TIRE_FRICTION := 1.1  # Haftreibungsbeiwert (tan 35° ≈ 0,70)
## Anteil der Querbewegung, der pro Tick abgebaut wird. Über 4 Räder koppelt das in die
## Gierdrehung mit etwa Faktor 2 ein; Werte ≥ 1 schwingen deshalb im 2-Tick-Takt.
const LATERAL_GRIP := 0.5
const MAX_STEER_ANGLE_DEG := 30.0
const STEER_SPEED_DEG_PER_S := 120.0

## Unterhalb dieser Kontaktgeschwindigkeit (m/s) und ohne Gas-Input greift die Parkbremse.
const PARK_SPEED_THRESHOLD := 0.3
## Anteil der Kontaktgeschwindigkeit, den die Parkbremse pro Tick aufhebt (siehe LATERAL_GRIP).
const PARK_GAIN := 0.5
## Rückstellsteifigkeit pro Rad zur gemerkten Parkposition (N/m), ~3 Hz bei 100 kg Radanteil.
const PARK_HOLD_STIFFNESS := 35000.0
## Ab dieser Verschiebung (m) wandert der Parkanker mit, statt zurückzuziehen.
const PARK_SLIP_DISTANCE := 0.1
## Gas-Werte darunter zählen als „kein Gas“.
const THROTTLE_DEADZONE := 0.05

# --- Aufstellen nach Umkippen ---
const UPRIGHT_DOT_LIMIT := 0.3  # cos des Kippwinkels, ab dem das Fahrzeug als gekippt gilt
const UPRIGHT_DELAY_S := 0.4  # so lange gekippt, bevor die Aufstellhilfe greift
const UPRIGHT_TORQUE := 9000.0
const UPRIGHT_DAMPING := 2500.0
const UPRIGHT_LIFT_ACCEL := 9.0  # m/s², hebt das Fahrzeug während der Aufstellhilfe an

# --- Abnahme-Metriken des Fahrbots ---
const TARGET_HILL_ANGLE_DEG := 35.0
const MAX_PARKED_DRIFT_M := 0.02  # in 10 s am 35°-Hang
const MAX_PARKED_ANGULAR_VELOCITY := 0.01  # rad/s im Stand
const TEST_GAP_WIDTH_M := 0.15
## Rundes Rad (r = 0,4 m) sinkt im 15-cm-Spalt geometrisch 7 mm ein; Jolt meldet Kontaktpunkte an
## Kanten zusätzlich ~6 mm ungenau. Ziel „0“ aus dem Plan ist physikalisch nicht erreichbar (ADR 0002).
const MAX_GAP_SINK_M := 0.02
const TARGET_STEP_HEIGHT_M := 0.30
const MAX_SELF_RIGHT_TIME_S := 3.0
