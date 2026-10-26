class_name KraxlVehicle
extends RigidBody3D
## Eigener Rad-Controller (ADR 0002): Kugel-ShapeCasts, Feder-Dämpfer, Reifenkräfte
## ohne Division durch die Geschwindigkeit, Parkbremse im Stand und Aufstellhilfe.
## Aufbau und Fahrwerte kommen aus dem Bauplan (ADR 0008); `design` vor add_child setzen.

const C := preload("res://src/vehicle/vehicle_constants.gd")

## Nach einem Sprung (mindestens LANDING_MIN_AIR_S ohne Bodenkontakt) wieder aufgesetzt.
## `strength` 0..1 aus der Fallgeschwindigkeit, für die Lautstärke des „Plumps“.
signal landed(strength: float)
## Die Aufstellhilfe hat das Fahrzeug wieder auf die Räder gebracht.
signal righted

## Bauplan; ohne Zuweisung der Standard-Crawler.
var design := CrawlerDesign.new()
var spec: VehicleSpec

## Eingabe; ohne Zuweisung steht das Fahrzeug.
var input: InputSource = InputSource.new()
## Solange ein Kind drin sitzt, darf Jolt das Fahrzeug nicht schlafen legen.
var occupied := true:
	set(value):
		occupied = value
		can_sleep = not value

## Geräusche (Motor, Ketten, Plumps, Aufstehen); im Fahrbot aus, weil dort niemand zuhört.
var sounds := true
## Auspuffrauch; im Fahrbot aus, weil dort niemand hinschaut.
var smoke := true

var wheels: Array[VehicleWheel] = []
var parked := false

var _steer_angle := 0.0
var _park_anchor := Transform3D()
var _has_park_anchor := false
var _tipped_time := 0.0
var _righting := false
var _inv_inertia_world := Basis()
## Lichter (nur mit Extra „licht“) – per Licht-Taste umschaltbar.
var lights_on := true
## Was CrawlerVisuals zum Schalten und Bewegen liefert (Lichter, Lampen, Werkzeug-Gelenke).
var _parts := {}
var _light_was_pressed := false
var _tool_amount := 0.0
var _air_time := 0.0
var _fall_speed := 0.0


func _ready() -> void:
	spec = VehicleSpec.from_design(design)
	mass = spec.mass
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = spec.center_of_mass
	can_sleep = not occupied
	_build_body()
	_build_wheels()
	if sounds:
		add_child(VehicleAudio.new(self))


func _build_body() -> void:
	# Kollision: Fahrgestell + Kabine. Die Kabine ist das Dach, auf dem ein gekipptes Fahrzeug
	# liegt, bevor die Aufstellhilfe greift.
	var top := spec.body_size.y * 0.5
	_add_box_collision(spec.body_size, Vector3.ZERO)
	_add_box_collision(spec.cab_size, Vector3(0, top + spec.cab_size.y * 0.5, spec.cab_z))
	_parts = CrawlerVisuals.build(self, spec, design)
	set_lights(lights_on)
	if smoke:
		for i in _parts.exhausts.size():
			var puff := ExhaustSmoke.new(self, _parts.exhausts[i])
			puff.name = "Auspuffrauch%d" % (i + 1)
			add_child(puff)


func _add_box_collision(size: Vector3, pos: Vector3) -> void:
	var box := BoxShape3D.new()
	box.size = size
	var collision := CollisionShape3D.new()
	collision.shape = box
	collision.position = pos
	add_child(collision)


func _build_wheels() -> void:
	for i in spec.wheel_mounts.size():
		var wheel := VehicleWheel.new()
		wheel.position = spec.wheel_mounts[i]
		wheel.steer_factor = spec.steer_factors[i]
		wheel.radius = spec.wheel_radius
		wheel.width = spec.wheel_width
		wheel.travel = spec.travel
		wheel.hub_color = spec.color
		wheel.tracks = spec.tracks
		wheel.tire = design.choices[&"reifen"]
		add_child(wheel)
		wheel.add_exception(self)
		wheels.append(wheel)


func _physics_process(delta: float) -> void:
	input.update(delta)
	_update_steering(delta)

	var grounded_count := 0
	var total_load := 0.0
	for wheel in wheels:
		var compression_velocity := wheel.probe(delta)
		if not wheel.grounded:
			continue
		grounded_count += 1
		var spring := clampf(
			spec.spring * wheel.compression + spec.damping * compression_velocity,
			0.0,
			spec.max_suspension_force
		)
		wheel.set_meta("load", spring)
		total_load += spring
		apply_force(global_basis.y * spring, wheel.contact_point - global_position)

	_track_landing(grounded_count, delta)
	if input.light and not _light_was_pressed and has_lights():
		set_lights(not lights_on)
	_light_was_pressed = input.light

	var throttle := input.throttle
	var wants_to_drive := absf(throttle) > C.THROTTLE_DEADZONE
	parked = not wants_to_drive and linear_velocity.length() < C.PARK_SPEED_THRESHOLD
	_update_park_anchor()
	if grounded_count > 0 and total_load > 0.0:
		_inv_inertia_world = _world_inertia().inverse()
		for wheel in wheels:
			if wheel.grounded:
				_apply_tire_force(wheel, grounded_count, total_load, throttle, delta)

	_update_righting(delta)
	for wheel in wheels:
		wheel.update_visual(-linear_velocity.dot(global_basis.z), delta)


## Beim Einrasten der Parkbremse wird die Lage gemerkt. Wird das Fahrzeug weiter als
## PARK_SLIP_DISTANCE weggeschoben (z. B. von einem anderen Fahrzeug), rutscht der Anker mit,
## damit es nicht wie an einem Gummiband zurückspringt.
func _update_park_anchor() -> void:
	if not parked:
		_has_park_anchor = false
	elif not _has_park_anchor or global_position.distance_to(_park_anchor.origin) > C.PARK_SLIP_DISTANCE:
		_park_anchor = global_transform
		_has_park_anchor = true


func _update_steering(delta: float) -> void:
	var target := -input.steer * deg_to_rad(C.MAX_STEER_ANGLE_DEG)
	_steer_angle = move_toward(_steer_angle, target, deg_to_rad(C.STEER_SPEED_DEG_PER_S) * delta)
	for wheel in wheels:
		wheel.rotation.y = _steer_angle * wheel.steer_factor


## Effektive Masse am Kontaktpunkt in Richtung `dir`, geteilt durch die Zahl der Räder, die
## gleichzeitig ziehen. Berücksichtigt die Drehträgheit: Bei kurzem Radstand oder hohem
## Schwerpunkt dreht eine Kraft am Rad das Fahrzeug stark, die Masse wirkt dort also kleiner.
## Mit „Masse ÷ Räder“ schwingt die Parkbremse bei solchen Bauplänen (ADR 0008).
func _effective_mass(offset: Vector3, dir: Vector3, contacts: int) -> float:
	if dir.length_squared() < 1e-8:
		return mass / contacts
	var arm := (offset - global_basis * center_of_mass).cross(dir.normalized())
	var k := 1.0 / mass + arm.dot(_inv_inertia_world * arm)
	return 1.0 / (k * contacts)


## Reifenkraft eines Rads. Die Hangabtriebskraft wird nach Radlast verteilt, weil das
## bergseitige Rad weniger hält.
func _apply_tire_force(
	wheel: VehicleWheel, contacts: int, total_load: float, throttle: float, delta: float
) -> void:
	var n := wheel.contact_normal
	var offset := wheel.contact_point - global_position
	var velocity := linear_velocity + angular_velocity.cross(offset)
	var v_plane := velocity - n * velocity.dot(n)
	var load: float = wheel.get_meta("load", 0.0)
	var max_force := spec.tire_friction * load
	var gravity_plane := get_gravity() * mass * (load / total_load)
	gravity_plane -= n * gravity_plane.dot(n)

	var force: Vector3
	if parked:
		# Parkbremse: zur gemerkten Lage zurückziehen, Kontaktgeschwindigkeit abbauen und die
		# Hangabtriebskraft direkt gegenhalten. Der Lage-Anteil fängt auch Restkräfte ab, etwa
		# die Federkräfte, die bei geneigter Karosserie hangabwärts zeigen.
		var error := wheel.global_position - _park_anchor * wheel.position
		error -= n * error.dot(n)
		var share := _effective_mass(offset, v_plane, contacts)
		force = -error * spec.park_hold_stiffness - v_plane * share / delta * C.PARK_GAIN - gravity_plane
	else:
		var forward := -wheel.global_basis.z
		forward = (forward - n * forward.dot(n)).normalized()
		var side := forward.cross(n)
		var v_long := v_plane.dot(forward)
		var v_lat := v_plane.dot(side)

		# Seitenführung: Quergeschwindigkeit pro Tick zum Großteil abbauen, Hang seitlich halten.
		var f_lat := -v_lat * _effective_mass(offset, side, contacts) / delta * C.LATERAL_GRIP - gravity_plane.dot(side)

		var per_wheel := 1.0 / wheels.size()
		var f_long := 0.0
		if absf(throttle) > C.THROTTLE_DEADZONE:
			var max_speed := spec.max_speed * (1.0 if throttle > 0 else C.REVERSE_SPEED_FACTOR)
			if v_long * throttle < -0.5:
				f_long = -signf(v_long) * spec.brake_force * per_wheel
			elif absf(v_long) < max_speed:
				f_long = throttle * spec.engine_force * per_wheel
		else:
			# Ausrollen bis zur Parkbremse, auch bergab; clampf statt sign() vermeidet Sprünge um v = 0.
			f_long = -gravity_plane.dot(forward)
			f_long -= clampf(v_long, -1.0, 1.0) * spec.brake_force * per_wheel * 0.5
		f_long -= clampf(v_long * 10.0, -1.0, 1.0) * spec.rolling_resistance * load

		force = forward * f_long + side * f_lat

	if force.length() > max_force:
		force = force.normalized() * max_force
	apply_force(force, offset)


func has_lights() -> bool:
	return not _parts.get("lights", []).is_empty()


func has_tool() -> bool:
	return not _parts.get("tool", {}).is_empty()


func set_lights(on: bool) -> void:
	lights_on = on
	for light: SpotLight3D in _parts.get("lights", []):
		light.visible = on
	for lamp: StandardMaterial3D in _parts.get("lamps", []):
		lamp.emission_enabled = on
		lamp.albedo_color = CrawlerVisuals.LAMP if on else CrawlerVisuals.LAMP.darkened(0.6)


## Bagger-Arm bzw. Radlader-Schaufel folgen der Werkzeug-Taste weich (nur Optik).
func _process(delta: float) -> void:
	if not has_tool():
		return
	_tool_amount = move_toward(_tool_amount, clampf(input.tool, 0.0, 1.0), delta * C.TOOL_SPEED)
	var a := _tool_amount
	var tool: Dictionary = _parts.tool
	match tool.kind:
		&"bagger":
			tool.boom.rotation.x = lerpf(0.55, -0.25, a)
			tool.stick.rotation.x = lerpf(-1.1, -0.35, a)
			tool.bucket.rotation.x = lerpf(-0.9, 0.5, a)
		&"radlader":
			var rest: Transform3D = tool.rest
			tool.shovel.transform = rest.rotated_local(Vector3.RIGHT, lerpf(0.0, -0.75, a))


func _track_landing(grounded_count: int, delta: float) -> void:
	if grounded_count == 0:
		_air_time += delta
		_fall_speed = maxf(_fall_speed, -linear_velocity.y)
		return
	if _air_time >= C.LANDING_MIN_AIR_S:
		landed.emit(clampf(_fall_speed / C.LANDING_FULL_SPEED, 0.15, 1.0))
	_air_time = 0.0
	_fall_speed = 0.0


func _update_righting(delta: float) -> void:
	var up_dot := global_basis.y.dot(Vector3.UP)
	if not _righting:
		_tipped_time = _tipped_time + delta if up_dot < C.UPRIGHT_DOT_LIMIT else 0.0
		_righting = _tipped_time > C.UPRIGHT_DELAY_S
	if not _righting:
		return
	if up_dot > 0.95:
		_righting = false
		_tipped_time = 0.0
		righted.emit()
		return
	var axis := global_basis.y.cross(Vector3.UP)
	if axis.length() < 0.1:
		axis = global_basis.z  # genau auf dem Dach: über die Längsachse drehen
	var angle := acos(clampf(up_dot, -1.0, 1.0))
	var accel := axis.normalized() * C.UPRIGHT_STIFFNESS * angle - angular_velocity * C.UPRIGHT_ANGULAR_DAMPING
	apply_torque(_world_inertia() * accel)
	apply_central_force(Vector3.UP * mass * C.UPRIGHT_LIFT_ACCEL)


## Trägheitstensor in Weltkoordinaten, aus der von Jolt berechneten Hauptträgheit.
func _world_inertia() -> Basis:
	var state := PhysicsServer3D.body_get_direct_state(get_rid())
	var inv: Vector3 = state.inverse_inertia
	var principal := Basis.from_scale(Vector3(
		1.0 / inv.x if inv.x > 0.0 else 0.0,
		1.0 / inv.y if inv.y > 0.0 else 0.0,
		1.0 / inv.z if inv.z > 0.0 else 0.0,
	))
	var rotation := global_basis.orthonormalized() * state.principal_inertia_axes
	return rotation * principal * rotation.transposed()


func is_righting() -> bool:
	return _righting
