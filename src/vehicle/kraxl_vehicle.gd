class_name KraxlVehicle
extends RigidBody3D
## Eigener Rad-Controller (ADR 0002): Kugel-ShapeCasts, Feder-Dämpfer, Reifenkräfte
## ohne Division durch die Geschwindigkeit, Parkbremse im Stand und Aufstellhilfe.

const C := preload("res://src/vehicle/vehicle_constants.gd")

## Eingabe; ohne Zuweisung steht das Fahrzeug.
var input: InputSource = InputSource.new()
## Solange ein Kind drin sitzt, darf Jolt das Fahrzeug nicht schlafen legen.
var occupied := true:
	set(value):
		occupied = value
		can_sleep = not value

var wheels: Array[VehicleWheel] = []
var parked := false

var _steer_angle := 0.0
var _park_anchor := Transform3D()
var _has_park_anchor := false
var _tipped_time := 0.0
var _righting := false


func _ready() -> void:
	mass = C.MASS_KG
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, C.CENTER_OF_MASS_Y_M, 0)
	can_sleep = not occupied
	_build_body()
	_build_wheels()


func _build_body() -> void:
	var box := BoxShape3D.new()
	box.size = C.BODY_SIZE_M
	var collision := CollisionShape3D.new()
	collision.shape = box
	add_child(collision)

	var mesh := BoxMesh.new()
	mesh.size = C.BODY_SIZE_M
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.55, 0.1)
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	add_child(visual)


func _build_wheels() -> void:
	var x := C.WHEEL_TRACK_M * 0.5
	var z := C.WHEEL_BASE_M * 0.5
	# -Z ist vorne.
	for mount in [Vector3(-x, 0, -z), Vector3(x, 0, -z), Vector3(-x, 0, z), Vector3(x, 0, z)]:
		var wheel := VehicleWheel.new()
		wheel.position = mount + Vector3(0, C.WHEEL_MOUNT_Y_M, 0)
		wheel.is_front = mount.z < 0
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
			C.SPRING_STIFFNESS * wheel.compression + C.SPRING_DAMPING * compression_velocity,
			0.0,
			C.MAX_SUSPENSION_FORCE
		)
		wheel.set_meta("load", spring)
		total_load += spring
		apply_force(global_basis.y * spring, wheel.contact_point - global_position)

	var throttle := input.throttle
	var wants_to_drive := absf(throttle) > C.THROTTLE_DEADZONE
	parked = not wants_to_drive and linear_velocity.length() < C.PARK_SPEED_THRESHOLD
	_update_park_anchor()
	if grounded_count > 0 and total_load > 0.0:
		var share := mass / grounded_count
		for wheel in wheels:
			if wheel.grounded:
				_apply_tire_force(wheel, share, total_load, throttle, delta)

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
		if wheel.is_front:
			wheel.rotation.y = _steer_angle


## Reifenkraft eines Rads. `share` ist die anteilige Masse pro Bodenkontakt.
## Die Hangabtriebskraft wird nach Radlast verteilt, weil das bergseitige Rad weniger hält.
func _apply_tire_force(
	wheel: VehicleWheel, share: float, total_load: float, throttle: float, delta: float
) -> void:
	var n := wheel.contact_normal
	var offset := wheel.contact_point - global_position
	var velocity := linear_velocity + angular_velocity.cross(offset)
	var v_plane := velocity - n * velocity.dot(n)
	var load: float = wheel.get_meta("load", 0.0)
	var max_force := C.TIRE_FRICTION * load
	var gravity_plane := get_gravity() * mass * (load / total_load)
	gravity_plane -= n * gravity_plane.dot(n)

	var force: Vector3
	if parked:
		# Parkbremse: zur gemerkten Lage zurückziehen, Kontaktgeschwindigkeit abbauen und die
		# Hangabtriebskraft direkt gegenhalten. Der Lage-Anteil fängt auch Restkräfte ab, etwa
		# die Federkräfte, die bei geneigter Karosserie hangabwärts zeigen.
		var error := wheel.global_position - _park_anchor * wheel.position
		error -= n * error.dot(n)
		force = -error * C.PARK_HOLD_STIFFNESS - v_plane * share / delta * C.PARK_GAIN - gravity_plane
	else:
		var forward := -wheel.global_basis.z
		forward = (forward - n * forward.dot(n)).normalized()
		var side := forward.cross(n)
		var v_long := v_plane.dot(forward)
		var v_lat := v_plane.dot(side)

		# Seitenführung: Quergeschwindigkeit pro Tick zum Großteil abbauen, Hang seitlich halten.
		var f_lat := -v_lat * share / delta * C.LATERAL_GRIP - gravity_plane.dot(side)

		var per_wheel := 1.0 / wheels.size()
		var f_long := 0.0
		if absf(throttle) > C.THROTTLE_DEADZONE:
			var max_speed := C.MAX_SPEED_MPS * (1.0 if throttle > 0 else C.REVERSE_SPEED_FACTOR)
			if v_long * throttle < -0.5:
				f_long = -signf(v_long) * C.BRAKE_FORCE * per_wheel
			elif absf(v_long) < max_speed:
				f_long = throttle * C.ENGINE_FORCE * per_wheel
		else:
			# Ausrollen bis zur Parkbremse, auch bergab; clampf statt sign() vermeidet Sprünge um v = 0.
			f_long = -gravity_plane.dot(forward)
			f_long -= clampf(v_long, -1.0, 1.0) * C.BRAKE_FORCE * per_wheel * 0.5
		f_long -= clampf(v_long * 10.0, -1.0, 1.0) * C.ROLLING_RESISTANCE * load

		force = forward * f_long + side * f_lat

	if force.length() > max_force:
		force = force.normalized() * max_force
	apply_force(force, offset)


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
		return
	var axis := global_basis.y.cross(Vector3.UP)
	if axis.length() < 0.1:
		axis = global_basis.z  # genau auf dem Dach: über die Längsachse drehen
	apply_torque(axis.normalized() * C.UPRIGHT_TORQUE - angular_velocity * C.UPRIGHT_DAMPING)
	apply_central_force(Vector3.UP * mass * C.UPRIGHT_LIFT_ACCEL)


func is_righting() -> bool:
	return _righting
