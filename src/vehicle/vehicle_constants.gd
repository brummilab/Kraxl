class_name VehicleConstants
## Fahrphysik-Grundwerte (ADR 0002). Zusammen mit dem Teilekatalog der einzige Ort für Physik-Werte.
## Änderungen nur mit Vorher/Nachher-Metriktabelle und Feel-Check.

## Muss mit physics/common/physics_ticks_per_second in project.godot übereinstimmen.
const PHYSICS_TICKS_PER_SECOND := 120

# Fahrzeug-Maße, Massen und Teile-Faktoren stehen im Teilekatalog (src/vehicle/parts/part_catalog.gd).
# Hier stehen die Grundwerte pro kg Radlast bzw. Fahrzeugmasse. Der Standard-Crawler
# (400 kg, 4 Räder, also 100 kg Radlast) ergibt damit genau die Werte aus ADR 0002:
# Feder 9000 N/m, Dämpfer 1800 N·s/m, Motor 3200 N, Bremse 4000 N.

const CENTER_OF_MASS_Y_M := -0.35  # tiefer Schwerpunkt gegen Umkippen
const WHEEL_MOUNT_Y_M := -0.1  # Aufhängungspunkt relativ zum Karosserie-Ursprung
const SPRING_RATE_PER_KG := 90.0  # N/m pro kg Radlast (≈ 11 cm Einfederung im Stand)
const DAMPING_PER_KG := 18.0  # N·s/m pro kg Radlast (~kritisch; bei 13 wippen kurze, hohe Baupläne nach)
const MAX_SUSPENSION_FORCE_PER_KG := 120.0  # Schutz bei ShapeCast-Überlappung
const ENGINE_FORCE_PER_KG := 8.0  # N pro kg Fahrzeugmasse, Allrad
const BRAKE_FORCE_PER_KG := 10.0  # N pro kg, wenn Gas gegen Fahrtrichtung
const TRACK_WIDENING_PER_RADIUS := 0.6  # m Achsverbreiterung je Seite pro m Radius über 0,4 m
const WHEELBASE_STRETCH_PER_RADIUS := 1.0  # m Radstand-Verlängerung je Achse pro m Radius über 0,4 m

# --- Antrieb und Reifen ---
const REVERSE_SPEED_FACTOR := 0.5
## Anteil der Querbewegung, der pro Tick abgebaut wird. Über 4 Räder koppelt das in die
## Gierdrehung mit etwa Faktor 2 ein; Werte ≥ 1 schwingen deshalb im 2-Tick-Takt.
const LATERAL_GRIP := 0.5
const MAX_STEER_ANGLE_DEG := 30.0
const STEER_SPEED_DEG_PER_S := 120.0

## Unterhalb dieser Kontaktgeschwindigkeit (m/s) und ohne Gas-Input greift die Parkbremse.
const PARK_SPEED_THRESHOLD := 0.3
## Anteil der Kontaktgeschwindigkeit, den die Parkbremse pro Tick aufhebt (siehe LATERAL_GRIP).
const PARK_GAIN := 0.5
## Rückstellsteifigkeit zur gemerkten Parkposition (N/m pro kg Radlast, ~3 Hz).
const PARK_HOLD_STIFFNESS_PER_KG := 350.0
## Ab dieser Verschiebung (m) wandert der Parkanker mit, statt zurückzuziehen.
const PARK_SLIP_DISTANCE := 0.1
## Gas-Werte darunter zählen als „kein Gas“.
const THROTTLE_DEADZONE := 0.05

# --- Aufstellen nach Umkippen ---
const UPRIGHT_DOT_LIMIT := 0.3  # cos des Kippwinkels, ab dem das Fahrzeug als gekippt gilt
const UPRIGHT_DELAY_S := 0.4  # so lange gekippt, bevor die Aufstellhilfe greift
## Aufstellhilfe als PD-Regler auf den Kippwinkel, umgerechnet über das Trägheitsmoment, damit
## kurze, lange und schwere Baupläne gleich schnell und ohne Überschwingen aufstehen.
const UPRIGHT_STIFFNESS := 16.0  # 1/s² (Eigenfrequenz 4 rad/s)
const UPRIGHT_ANGULAR_DAMPING := 8.0  # 1/s (= 2·√Steifigkeit, kritisch gedämpft)
const UPRIGHT_LIFT_ACCEL := 9.0  # m/s², hebt das Fahrzeug während der Aufstellhilfe an

# --- Geräusch-Auslöser (keine Physik, nur wann ein Ton kommt) ---
const LANDING_MIN_AIR_S := 0.25  # so lange ohne Bodenkontakt, bevor Aufsetzen „Plumps“ macht
const LANDING_FULL_SPEED := 6.0  # m/s Fallgeschwindigkeit für volle Lautstärke

# --- Werkzeug (Bagger, Radlader; nur Optik) ---
const TOOL_SPEED := 1.5  # volle Bewegung pro Sekunde

# --- Graben mit dem Bagger (Terrain3D-Höhen, ADR 0013) ---
const DIG_TRIGGER := 0.85  # Werkzeug-Stellung, ab der der Löffel gräbt bzw. auskippt
const DIG_REACH := 0.8  # m: so weit über dem Boden darf die Löffelspitze sein und trotzdem greifen
const DIG_RADIUS := 1.7  # m Radius der Mulde bzw. des Haufens (Gitter des Geländes: 1 m)
const DIG_DEPTH := 0.45  # m pro Löffel
const DIG_MAX_DEPTH := 1.5  # m höchstens unter dem Ursprungsboden (Crawler kommen immer heraus)
const PILE_HEIGHT := 0.4  # m pro ausgekipptem Löffel
const PILE_MAX_HEIGHT := 1.5  # m höchstens über dem Ursprungsboden

# --- Flieger (Arcade-Flug ohne Absturz, ADR 0013) ---
const PLANE_TAKEOFF_SPEED := 9.0  # m/s, ab hier hebt er mit Gas ab
const PLANE_CRUISE_SPEED := 13.0  # m/s in der Luft
const PLANE_ACCEL := 4.0  # m/s²
const PLANE_BRAKE := 6.0  # m/s² am Boden ohne Gas
const PLANE_TAXI_REVERSE_SPEED := 2.0  # m/s rückwärts rollen
const PLANE_TAXI_TURN := 1.3  # rad/s am Boden
const PLANE_AIR_TURN := 0.8  # rad/s in der Luft
const PLANE_CLIMB_RATE := 3.0  # m/s steigen
const PLANE_SINK_RATE := 3.0  # m/s sinken
const PLANE_CLIMB_ACCEL := 5.0  # m/s², wie schnell Steigen/Sinken einsetzt
const PLANE_MAX_ALTITUDE := 30.0  # m über Grund (unter der 64 m hohen Weltrand-Wand)
const PLANE_GROUND_STICK := 3.0  # m/s nach unten am Boden, damit er auf Hängen bleibt
const PLANE_FLOOR_MAX_ANGLE_DEG := 46.0  # steilerer Boden zählt als Wand
const PLANE_VISUAL_BANK := 0.5  # rad Schräglage in der Kurve (nur Optik)
const PLANE_ENGINE_HZ := 95.0  # Grundton des Motors

# --- Spielzeug in der Welt (bunte Kegel und Kisten zum Umschubsen, ADR 0012) ---
const TOY_CONE_MASS := 4.0  # kg; leicht genug, dass jeder Crawler ihn wegschiebt
const TOY_BOX_MASS := 10.0  # kg
const TOY_FRICTION := 0.8

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
