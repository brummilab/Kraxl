class_name VehicleWheel
extends ShapeCast3D
## Ein Rad als Kugel-ShapeCast vom Aufhängungspunkt nach unten (ADR 0002).
## Die Kugel erkennt Kanten von Steinen und Stufen früher als ein einzelner Strahl
## und kann nicht in Spalten schmaler als der Raddurchmesser fallen.

var radius := 0.4
var width := 0.3
var travel := 0.35
## Lenkfaktor: 1 = Vorderachse, 0 = starr, negativ = gegenläufig (Allrad), positiv = Krebsgang.
var steer_factor := 0.0
var hub_color := Color(0.95, 0.55, 0.1)
## Ketten-Laufwerk statt Rad: nur die Optik ändert sich, der Bodenkontakt bleibt die Kugel.
var tracks := false
## Reifen-Teil (für das Kenney-Rad); leer = einfache Zylinder.
var tire: StringName = &""

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

	_visual = Node3D.new()
	add_child(_visual)
	if tracks:
		_build_track_pod()
	elif KenneyModels.has_wheel(tire):
		_build_kenney_wheel()
	else:
		_visual.add_child(_disc(radius, width, Color(0.12, 0.12, 0.12)))
		_visual.add_child(_disc(radius * 0.5, width + 0.02, hub_color))


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


## Kenney-Rad, auf unseren Radius und unsere Breite skaliert; Nabe in Lackfarbe.
## Die Felge liegt beim Kenney-Rad auf +X; linke Räder werden um 180° gedreht (nicht gespiegelt –
## negative Skalierung dreht die Flächen nach innen), damit die Felge immer nach außen zeigt.
func _build_kenney_wheel() -> void:
	var info := KenneyModels.wheel_mesh(tire)
	var node := MeshInstance3D.new()
	node.mesh = info.mesh
	node.material_override = KenneyModels.paint_material(info.mesh, hub_color)
	var flip := Basis(Vector3.UP, PI) if position.x < 0.0 else Basis()
	var scale_r: float = radius / info.radius
	var scale_w: float = width / maxf(info.width, 0.01)
	# _visual dreht Zylinder (Achse Y) auf die Radachse X; das Kenney-Rad liegt schon auf X.
	node.basis = Basis(Vector3.FORWARD, PI / 2).inverse() * flip * Basis.from_scale(Vector3(scale_w, scale_r, scale_r))
	_visual.add_child(node)


## Dreieckiges Ketten-Laufwerk (wie Track-Pods an echten Crawlern), seitlich am Rad befestigt.
func _build_track_pod() -> void:
	var track := StandardMaterial3D.new()
	track.albedo_color = Color(0.12, 0.12, 0.12)
	var mesh := PrismMesh.new()
	mesh.size = Vector3(radius * 2.6, radius * 1.8, width)
	mesh.material = track
	var pod := MeshInstance3D.new()
	pod.mesh = mesh
	pod.rotation = Vector3(0, PI / 2, 0)
	pod.position.y = -radius * 0.1
	_visual.add_child(pod)
	var hub := _disc(radius * 0.35, width + 0.04, hub_color)
	hub.rotation = Vector3(0, 0, PI / 2)
	hub.position.y = radius * 0.15
	_visual.add_child(hub)


func _disc(r: float, h: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = h
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material = material
	var node := MeshInstance3D.new()
	node.mesh = mesh
	return node


## Mittelpunkt des Rads in Weltkoordinaten.
func center() -> Vector3:
	return _visual.global_position


func update_visual(forward_speed: float, delta: float) -> void:
	if tracks:
		return
	_spin -= forward_speed / radius * delta
	_visual.basis = Basis(Vector3.RIGHT, _spin) * Basis(Vector3.FORWARD, PI / 2)
