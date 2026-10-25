class_name VehicleWheel
extends ShapeCast3D
## Ein Rad als Kugel-ShapeCast vom Aufhängungspunkt nach unten (ADR 0002).
## Die Kugel erkennt Kanten von Steinen und Stufen früher als ein einzelner Strahl
## und kann nicht in Spalten schmaler als der Raddurchmesser fallen.

var radius := VehicleConstants.WHEEL_RADIUS_M
var travel := VehicleConstants.SUSPENSION_TRAVEL_M
var is_front := false

## Ergebnis des letzten Ticks.
var grounded := false
var compression := 0.0
var contact_point := Vector3.ZERO
var contact_normal := Vector3.UP

var _previous_compression := 0.0
var _visual: Node3D
var _spin := 0.0


func _ready() -> void:
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape = sphere
	target_position = Vector3(0, -travel, 0)
	max_results = 1
	enabled = false  # Abfrage nur per force_shapecast_update() im Tick des Fahrzeugs

	_visual = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.3
	_visual.mesh = mesh
	add_child(_visual)


## Fragt den Boden ab und liefert die Kompressionsgeschwindigkeit (m/s).
func probe(delta: float) -> float:
	force_shapecast_update()
	grounded = is_colliding()
	var distance := travel
	if grounded:
		contact_point = get_collision_point(0)
		contact_normal = get_collision_normal(0)
		distance = _exact_distance()
	compression = travel - distance
	var compression_velocity := (compression - _previous_compression) / delta
	_previous_compression = compression
	_visual.position = Vector3(0, -distance, 0)
	return compression_velocity


## Die safe_fraction des ShapeCasts ist grob gerastert (mm-Sprünge pro Tick), was über den
## Dämpfer zu Zittern führt. Exakt: Kugelmittelpunkt liegt auf der Cast-Linie und hat den
## Abstand `radius` zur Kontaktebene.
func _exact_distance() -> float:
	var down := -global_basis.y
	var facing := down.dot(-contact_normal)
	if facing < 0.2:
		# Kontakt fast seitlich (Wand, Stufenkante): Rasterwert ist hier gut genug.
		return get_closest_collision_safe_fraction() * travel
	var height := (global_position - contact_point).dot(contact_normal)
	return clampf((height - radius) / facing, 0.0, travel)


## Mittelpunkt des Rads in Weltkoordinaten.
func center() -> Vector3:
	return _visual.global_position


func update_visual(forward_speed: float, delta: float) -> void:
	_spin -= forward_speed / radius * delta
	_visual.basis = Basis(Vector3.RIGHT, _spin) * Basis(Vector3.FORWARD, PI / 2)
