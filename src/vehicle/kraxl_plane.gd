class_name KraxlPlane
extends CharacterBody3D
## Flieger (ADR 0013): Spielzeug-Flug für Kinder, ohne Absturz und ohne Scheitern.
## ▲ = Gas, ab Abhebetempo steigen; ▼ = sinken, am Boden bremsen; ◀ ▶ = Kurve. Am Boden rollt er
## wie ein Auto. In der Luft hält er Tempo und Höhe von selbst. Jede Bodenberührung ist eine sanfte
## Landung (CharacterBody3D gleitet an Boden und Wänden ab), Hänge bis 45° werden zur Rollbahn.
## Bauplan: Aufbau „flieger“; Farbe und Regenbogen-Lack wie beim Crawler. Flugwerte nur in
## vehicle_constants.gd (PLANE_*).

const C := preload("res://src/vehicle/vehicle_constants.gd")

## Bauplan; nur Aufbau und Farbe zählen.
var design := CrawlerDesign.new()
var input: InputSource = InputSource.new()
## Geräusche (Motor, Hupe); im Fahrbot aus.
var sounds := true
## Garage: steht still auf der Drehscheibe.
var preview := false
## Vorwärtstempo in m/s (negativ = rückwärts rollen).
var speed := 0.0
var flying := false

var _climb := 0.0
var _bank := 0.0
var _pitch := 0.0
var _visual: Node3D
var _propeller: Node3D
var _engine: AudioStreamPlayer3D
var _effects: AudioStreamPlayer3D
var _horn_was_pressed := false


func _ready() -> void:
	up_direction = Vector3.UP
	floor_max_angle = deg_to_rad(C.PLANE_FLOOR_MAX_ANGLE_DEG)
	floor_snap_length = 0.3
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.9, 1.2, 3.2)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 0.6
	add_child(collision)
	_build_visual()
	set_physics_process(not preview)
	if sounds and not preview:
		_build_audio()


func _physics_process(delta: float) -> void:
	input.update(delta)
	var throttle := input.throttle
	var steer := input.steer
	var altitude := global_position.y - _ground_below()
	var vertical := 0.0
	var turn := 0.0

	if is_on_floor() and _climb <= 0.0:
		flying = false
		_climb = 0.0
		var target := 0.0
		if throttle > 0.0:
			target = C.PLANE_TAKEOFF_SPEED * 1.2
		elif throttle < 0.0:
			target = -C.PLANE_TAXI_REVERSE_SPEED
		var rate := C.PLANE_ACCEL if absf(target) > absf(speed) else C.PLANE_BRAKE
		speed = move_toward(speed, target, rate * delta)
		turn = -steer * C.PLANE_TAXI_TURN * clampf(speed / 3.0, -1.0, 1.0)
		vertical = -C.PLANE_GROUND_STICK
		if throttle > 0.0 and speed >= C.PLANE_TAKEOFF_SPEED:
			_climb = C.PLANE_CLIMB_RATE * 0.5  # abheben
			flying = true
	else:
		flying = true
		speed = move_toward(speed, C.PLANE_CRUISE_SPEED, C.PLANE_ACCEL * delta)
		var target_climb := throttle * (C.PLANE_CLIMB_RATE if throttle > 0.0 else C.PLANE_SINK_RATE)
		if altitude > C.PLANE_MAX_ALTITUDE:
			target_climb = minf(target_climb, -(altitude - C.PLANE_MAX_ALTITUDE))
		_climb = move_toward(_climb, target_climb, C.PLANE_CLIMB_ACCEL * delta)
		vertical = _climb
		turn = -steer * C.PLANE_AIR_TURN

	rotate_y(turn * delta)
	velocity = -global_basis.z * speed + Vector3.UP * vertical
	move_and_slide()
	if flying and is_on_floor() and _climb <= 0.0:
		flying = false  # aufgesetzt: ab jetzt rollen

	_update_visual(delta, steer, vertical)
	_update_audio(delta)


func has_lights() -> bool:
	return false


func has_tool() -> bool:
	return false


func tool_kind() -> StringName:
	return &""


func set_lights(_on: bool) -> void:
	pass


## Zurück an den Start (Weltrand-Sicherheitsnetz), still und am Boden.
func reset_to(where: Transform3D) -> void:
	global_transform = where
	velocity = Vector3.ZERO
	speed = 0.0
	_climb = 0.0
	flying = false
	reset_physics_interpolation()


## Höhe des Bodens unter dem Flieger (Strahl nach unten, ohne sich selbst).
func _ground_below() -> float:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, global_position + Vector3.DOWN * 200.0)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position.y if hit else global_position.y


func _update_visual(delta: float, steer: float, vertical: float) -> void:
	var blend := 1.0 - exp(-4.0 * delta)
	_bank = lerpf(_bank, steer * C.PLANE_VISUAL_BANK if flying else 0.0, blend)
	_pitch = lerpf(_pitch, atan2(vertical, maxf(absf(speed), 4.0)) if flying else 0.0, blend)
	_visual.basis = Basis(Vector3.RIGHT, _pitch) * Basis(Vector3.FORWARD, -_bank)
	_propeller.rotate_z(delta * (8.0 + absf(speed) * 3.0))


# --- Optik: Spielzeug-Flieger aus Grundformen ----------------------------------


func _build_visual() -> void:
	var spec := VehicleSpec.from_design(design)
	var paint := Paint.solid(spec.color, spec.rainbow)
	var trim := Paint.solid(spec.color.darkened(0.35), spec.rainbow)
	var white := Paint.solid(Color(0.95, 0.95, 0.95))
	var dark := Paint.solid(CrawlerVisuals.DARK)
	var glass := Paint.solid(CrawlerVisuals.GLASS)
	_visual = Node3D.new()
	_visual.name = "Flieger"
	_visual.position.y = 0.9  # Drehpunkt für Neigen und Rollen in der Rumpfmitte
	add_child(_visual)

	var body := CapsuleMesh.new()
	body.radius = 0.4
	body.height = 3.0
	_mesh(body, Vector3(0, 0, 0), Vector3(PI / 2, 0, 0), paint)
	var canopy := SphereMesh.new()
	canopy.radius = 0.3
	canopy.height = 0.5
	_mesh(canopy, Vector3(0, 0.33, -0.2), Vector3.ZERO, glass)
	_box(Vector3(4.6, 0.1, 0.9), Vector3(0, -0.05, -0.1), trim)  # Tragfläche
	for x in [-2.1, 2.1]:
		_box(Vector3(0.4, 0.12, 0.92), Vector3(x, -0.05, -0.1), white)  # weiße Flügelspitzen
	_box(Vector3(1.7, 0.08, 0.5), Vector3(0, 0.1, 1.3), trim)  # Höhenleitwerk
	_box(Vector3(0.08, 0.75, 0.55), Vector3(0, 0.45, 1.35), paint)  # Seitenleitwerk

	_propeller = Node3D.new()
	_propeller.name = "Propeller"
	_propeller.position = Vector3(0, 0, -1.62)
	_visual.add_child(_propeller)
	var hub := SphereMesh.new()
	hub.radius = 0.14
	hub.height = 0.28
	var hub_node := MeshInstance3D.new()
	hub_node.mesh = hub
	hub_node.material_override = white
	_propeller.add_child(hub_node)
	for angle in [0.0, PI]:
		var blade := MeshInstance3D.new()
		var blade_mesh := BoxMesh.new()
		blade_mesh.size = Vector3(0.14, 0.7, 0.04)
		blade.mesh = blade_mesh
		blade.material_override = dark
		blade.position = Vector3(0, 0.35, 0).rotated(Vector3.FORWARD, angle)
		blade.rotation.z = angle
		_propeller.add_child(blade)

	# Fahrwerk (sitzt fest am Rumpf, nicht am geneigten Teil, damit es am Boden bleibt).
	for x in [-0.75, 0.75]:
		_wheel(Vector3(x, 0.22, -0.45), 0.22, dark)
		_strut(Vector3(x, 0.55, -0.45), dark)
	_wheel(Vector3(0, 0.12, 1.3), 0.12, dark)


func _mesh(mesh: Mesh, pos: Vector3, rot: Vector3, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.rotation = rot
	node.material_override = material
	_visual.add_child(node)


func _box(size: Vector3, pos: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_mesh(mesh, pos, Vector3.ZERO, material)


func _wheel(pos: Vector3, radius: float, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.12
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.rotation.z = PI / 2
	node.material_override = material
	add_child(node)


func _strut(pos: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.06, 0.5, 0.06)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.material_override = material
	add_child(node)


# --- Ton -----------------------------------------------------------------------


func _build_audio() -> void:
	Sfx.setup_bus()
	_engine = _player(Sfx.engine_loop(C.PLANE_ENGINE_HZ, 0.35))
	_engine.volume_db = -14.0
	_engine.play()
	_effects = _player(null)


func _update_audio(delta: float) -> void:
	if _engine == null:
		return
	var ratio := clampf(absf(speed) / C.PLANE_CRUISE_SPEED, 0.0, 1.0)
	var blend := 1.0 - exp(-4.0 * delta)
	_engine.pitch_scale = lerpf(_engine.pitch_scale, 0.8 + ratio * 0.8 + maxf(input.throttle, 0.0) * 0.15, blend)
	_engine.volume_db = lerpf(_engine.volume_db, lerpf(-14.0, -5.0, ratio), blend)
	if input.horn and not _horn_was_pressed:
		_effects.stream = Sfx.horn()
		_effects.pitch_scale = 1.25
		_effects.play()
	_horn_was_pressed = input.horn


func _player(stream: AudioStream) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.bus = Sfx.EFFECTS_BUS
	player.unit_size = 12.0
	add_child(player)
	return player
