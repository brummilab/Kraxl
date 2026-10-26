class_name VehicleSpec
extends RefCounted
## Fahrwerte eines Crawlers, berechnet aus Bauplan + Teilekatalog + Grundwerten (ADR 0008).
## KraxlVehicle liest nur diese Werte; dadurch bleibt die Physik an einer Stelle nachvollziehbar.

const C := preload("res://src/vehicle/vehicle_constants.gd")

var mass := 400.0
var body_size := Vector3(1.4, 0.6, 2.4)
var cab_size := Vector3(1.2, 0.6, 1.0)
var cab_z := 0.2
var center_of_mass := Vector3(0, C.CENTER_OF_MASS_Y_M, 0)

## Aufhängungspunkte (lokal) und Lenkfaktor je Rad: 1 = Vorderachse, 0 = starr.
var wheel_mounts: Array[Vector3] = []
var steer_factors: Array[float] = []
var wheel_radius := 0.4
var wheel_width := 0.3
var travel := 0.35

var spring := 9000.0
var damping := 1300.0
var max_suspension_force := 12000.0
var park_hold_stiffness := 35000.0
var engine_force := 3200.0
var brake_force := 4000.0
var max_speed := 6.0
var tire_friction := 1.1
var tracks := false
var rolling_resistance := 0.03
var color := Color(0.95, 0.55, 0.1)


static func from_design(design: CrawlerDesign) -> VehicleSpec:
	var s := VehicleSpec.new()
	var chassis := design.get_part(&"fahrgestell")
	var wheels := design.get_part(&"raeder")
	var tires := design.get_part(&"reifen")
	var axle := design.get_part(&"achsen")
	var suspension := design.get_part(&"federung")
	var motor := design.get_part(&"motor")
	var steering := design.get_part(&"lenkung")
	var body := design.get_part(&"aufbau")

	var axles: Array = chassis.achsen
	# Große Räder sitzen auf breiteren Achsen (wie bei Monstertrucks), sonst kippt ein hoher
	# Crawler quer am 35°-Hang: Kippgrenze tan(Hang) < halbe Spur / Schwerpunkthöhe.
	var x: float = chassis.spur * 0.5 + maxf(0.0, wheels.radius - 0.4) * C.TRACK_WIDENING_PER_RADIUS + axle.spur_plus
	var mount_y: float = C.WHEEL_MOUNT_Y_M - axle.tiefer
	# Ebenso wandern die äußeren Achsen bei großen Rädern nach außen, sonst überschlägt sich ein
	# kurzer, hoher Crawler am 35°-Hang nach hinten (gleiche Kippgrenze längs).
	var stretch: float = maxf(0.0, wheels.radius - 0.4) * C.WHEELBASE_STRETCH_PER_RADIUS
	for i in axles.size():
		var z: float = axles[i]
		z += signf(z) * stretch
		var factor := 0.0
		if i == 0:
			factor = 1.0
		elif i == axles.size() - 1:
			factor = steering.hinten
		for side in [-x, x]:
			s.wheel_mounts.append(Vector3(side, mount_y, z))
			s.steer_factors.append(factor)

	var wheel_count := s.wheel_mounts.size()
	s.mass = chassis.masse + wheel_count * wheels.masse + body.masse + axle.masse
	for id in design.selected_extras():
		s.mass += PartCatalog.part(&"extras", id).masse
	var wheel_load := s.mass / wheel_count

	s.body_size = chassis.groesse
	s.cab_size = body.kabine
	s.cab_z = body.kabine_z
	# Schwerpunkt aus Aufbau und Rädern gewichtet: schwere große Räder ziehen ihn nach unten.
	var wheel_mass: float = wheel_count * wheels.masse
	var sag: float = 9.81 / (C.SPRING_RATE_PER_KG * suspension.federrate)
	var wheel_y: float = mount_y - (suspension.weg - sag)
	var body_y: float = C.CENTER_OF_MASS_Y_M + body.schwerpunkt
	s.center_of_mass = Vector3(0, (body_y * (s.mass - wheel_mass) + wheel_y * wheel_mass) / s.mass, 0)
	s.wheel_radius = wheels.radius
	s.wheel_width = wheels.breite * tires.breite_faktor
	s.travel = suspension.weg

	s.spring = C.SPRING_RATE_PER_KG * wheel_load * suspension.federrate
	# Weiche Federn behalten die vollen Dämpfer, sonst wippen kurze, hohe Baupläne lange nach.
	s.damping = C.DAMPING_PER_KG * wheel_load * maxf(1.0, sqrt(suspension.federrate))
	s.max_suspension_force = C.MAX_SUSPENSION_FORCE_PER_KG * wheel_load * suspension.federrate
	s.park_hold_stiffness = C.PARK_HOLD_STIFFNESS_PER_KG * wheel_load
	s.engine_force = C.ENGINE_FORCE_PER_KG * s.mass * motor.kraft
	s.brake_force = C.BRAKE_FORCE_PER_KG * s.mass
	s.max_speed = motor.tempo * tires.get("tempo_faktor", 1.0)
	s.tracks = tires.id == &"ketten"
	s.tire_friction = tires.reibung
	s.rolling_resistance = tires.rollwiderstand
	s.color = design.get_part(&"farbe").farbe
	return s
