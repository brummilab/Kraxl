extends Node3D
## Fahrbot: deterministische Physik-Szenarien mit Messwerten (ADR 0002).
##
## Aufruf (headless, so schnell wie möglich mit festem 120-Hz-Takt):
##   godot --headless --fixed-fps 120 res://tests/fahrbot/fahrbot.tscn -- [--only=name,name] [--json=pfad]
## Ohne --headless sieht man die Szenarien laufen. Exit-Code 1, wenn eine Metrik verfehlt wird,
## 2 bei Zeitüberschreitung (--timeout=Sekunden Echtzeit, Standard 900).
## Nicht `--quit-after` verwenden: Godot beendet dann mit Exit-Code 0, auch mitten im Lauf.

const C := preload("res://src/vehicle/vehicle_constants.gd")
const SCENARIOS := [
	"stand_eben",
	"hang_35_bergauf",
	"hang_35_quer",
	"lenken",
	"stufe_30cm",
	"spalt_15cm",
	"aufstellen",
	"terrain3d_hang_quer",
	"baukasten",
]
const SPAWN_CLEARANCE := 0.85  # Karosserie-Ursprung über dem Boden beim Absetzen

var results: Array[Dictionary] = []
var _stage: Node3D
var _camera: Camera3D
var _deadline_ms := 0


func _ready() -> void:
	var args := _parse_args()
	var only: PackedStringArray = args.get("only", "").split(",", false)
	_deadline_ms = Time.get_ticks_msec() + int(float(args.get("timeout", "900")) * 1000.0)
	await get_tree().process_frame

	for scenario in SCENARIOS:
		if only.is_empty() or only.has(scenario):
			_stage = Node3D.new()
			_stage.name = scenario
			add_child(_stage)
			print("▶ ", scenario)
			await call("_scenario_" + scenario)
			_stage.queue_free()
			await get_tree().physics_frame

	var failed := results.filter(func(r): return not r.ok).size()
	print("\n", _markdown_table())
	print("Ergebnis: %d Metriken, %d verfehlt" % [results.size(), failed])
	if args.has("json"):
		var file := FileAccess.open(args.json, FileAccess.WRITE)
		file.store_string(JSON.stringify(results, "  "))
	get_tree().quit(1 if failed > 0 else 0)


func _process(_delta: float) -> void:
	if _deadline_ms > 0 and Time.get_ticks_msec() > _deadline_ms:
		push_error("Fahrbot: Zeitüberschreitung, Lauf abgebrochen")
		print("\n", _markdown_table())
		get_tree().quit(2)
		_deadline_ms = 0


# --- Szenarien ---------------------------------------------------------------


func _scenario_stand_eben() -> void:
	_flat_ground()
	var vehicle := _spawn(Transform3D(Basis(), Vector3(0, SPAWN_CLEARANCE, 0)))
	await _run(3.0)
	var m := await _measure_parked(vehicle, 5.0)
	_report("stand_eben", "Winkelgeschw. im Stand", m.max_angular, C.MAX_PARKED_ANGULAR_VELOCITY, "rad/s")
	_report("stand_eben", "Drift in 5 s", m.drift, C.MAX_PARKED_DRIFT_M, "m")


func _scenario_hang_35_bergauf() -> void:
	await _parked_on_ramp("hang_35_bergauf", Basis())


func _scenario_hang_35_quer() -> void:
	await _parked_on_ramp("hang_35_quer", Basis(Vector3.UP, PI / 2))


func _scenario_lenken() -> void:
	_flat_ground()
	var vehicle := _spawn(Transform3D(Basis(), Vector3(0, SPAWN_CLEARANCE, 0)))
	await _run(1.0)
	vehicle.input = BotInputSource.new([{"duration": 6.0, "throttle": 0.6, "steer": 1.0}])
	var m := {"turned": 0.0, "min_up": 1.0, "last": vehicle.global_basis.z}
	await _run(6.0, func():
		var z: Vector3 = vehicle.global_basis.z
		m.turned += absf(m.last.signed_angle_to(z, Vector3.UP))
		m.last = z
		m.min_up = minf(m.min_up, vehicle.global_basis.y.dot(Vector3.UP))
	)
	_report("lenken", "Drehung in 6 s (Vollausschlag)", rad_to_deg(m.turned), 180.0, "°", true)
	_report("lenken", "Kippen (cos Neigung)", m.min_up, 0.9, "", true)


func _scenario_stufe_30cm() -> void:
	_flat_ground()
	# Stufe beginnt bei z = -5 und reicht nach -Z (vorne).
	_box(Vector3(20, C.TARGET_STEP_HEIGHT_M, 20), Vector3(0, C.TARGET_STEP_HEIGHT_M / 2, -15))
	var vehicle := _spawn(Transform3D(Basis(), Vector3(0, SPAWN_CLEARANCE, 0)))
	await _run(1.0)
	vehicle.input = BotInputSource.new([{"duration": 10.0, "throttle": 1.0}])
	var m := {"time": INF, "t": 0.0}
	await _run(10.0, func():
		m.t += 1.0 / C.PHYSICS_TICKS_PER_SECOND
		if m.time == INF and vehicle.global_position.z < -8.0 and vehicle.global_position.y > C.TARGET_STEP_HEIGHT_M:
			m.time = m.t
	)
	_report("stufe_30cm", "Zeit bis oben (Vollgas)", m.time, 8.0, "s")


func _scenario_spalt_15cm() -> void:
	# Zwei Platten, Oberkante y = 0, Spalt von z = -5,00 bis -5,15.
	_box(Vector3(10, 1, 15), Vector3(0, -0.5, 2.5))
	_box(Vector3(10, 1, 20), Vector3(0, -0.5, -5.0 - C.TEST_GAP_WIDTH_M - 10.0))
	var vehicle := _spawn(Transform3D(Basis(), Vector3(0, SPAWN_CLEARANCE, 0)))
	await _run(1.0)
	vehicle.input = BotInputSource.new([{"duration": 8.0, "throttle": 0.4}])
	var m := {"sink": 0.0}
	await _run(8.0, func():
		if vehicle.global_position.z < -18.0:
			vehicle.input = InputSource.new()  # vor dem Plattenende anhalten
		for wheel in vehicle.wheels:
			if wheel.grounded and wheel.center().z > -22.0:
				m.sink = maxf(m.sink, wheel.radius - wheel.center().y)
	)
	_report("spalt_15cm", "Rad-Einsinken", m.sink, C.MAX_GAP_SINK_M, "m")
	_report("spalt_15cm", "Strecke nach dem Spalt", -5.15 - vehicle.global_position.z, 3.0, "m", true)


func _scenario_aufstellen() -> void:
	_flat_ground()
	var vehicle := _spawn(Transform3D(Basis(Vector3.BACK, PI), Vector3(0, 1.5, 0)))
	var m := {"time": INF, "t": 0.0}
	await _run(8.0, func():
		m.t += 1.0 / C.PHYSICS_TICKS_PER_SECOND
		var upright: bool = vehicle.global_basis.y.dot(Vector3.UP) > 0.9
		var calm: bool = vehicle.angular_velocity.length() < 0.5 and not vehicle.is_righting()
		if m.time == INF and m.t > 0.5 and upright and calm:
			m.time = m.t
	)
	_report("aufstellen", "Zeit bis aufrecht", m.time, C.MAX_SELF_RIGHT_TIME_S, "s")


func _scenario_terrain3d_hang_quer() -> void:
	if not ClassDB.class_exists("Terrain3D"):
		_report("terrain3d_hang_quer", "Terrain3D geladen", 1.0, 0.0, "")
		return
	var camera := Camera3D.new()
	_stage.add_child(camera)
	SpikeTerrain.create(_stage, camera)
	await _run(0.2)  # Kollision aufbauen lassen
	var x := 185.0
	var z := 128.0
	var angle := deg_to_rad(C.TARGET_HILL_ANGLE_DEG)
	var normal := Vector3(-sin(angle), cos(angle), 0)
	var ground := Vector3(x, SpikeTerrain.height_at(x, z), z)
	var basis := Basis(Vector3.BACK, angle)  # quer zum Hang, Blick nach -Z
	var vehicle := _spawn(Transform3D(basis, ground + normal * SPAWN_CLEARANCE))
	await _run(4.0)
	var m := await _measure_parked(vehicle, 10.0)
	_report("terrain3d_hang_quer", "Drift in 10 s", m.drift, C.MAX_PARKED_DRIFT_M, "m")
	_report("terrain3d_hang_quer", "Winkelgeschw. im Stand", m.max_angular, C.MAX_PARKED_ANGULAR_VELOCITY, "rad/s")


## Pflicht für JEDE Teilekombination (ADR 0008): am 35°-Hang quer und bergauf parken ohne Drift
## und Zittern, nach dem Umkippen in < 3 s wieder aufrecht. Die 30-cm-Stufe ist dagegen eine
## Eigenschaft (kleine Räder schaffen sie nicht) und wird nur gezählt.
func _scenario_baukasten() -> void:
	var designs := _baukasten_designs()
	var worst := {}  # Metrik -> [Wert, Design]
	var failures: Array[String] = []
	var climbers := 0
	for entry in designs:
		var label: String = entry[0]
		var design: CrawlerDesign = entry[1]
		var m := await _check_design(design)
		climbers += int(m.climbs)
		for key in ["drift_quer", "drift_bergauf", "angular", "righting"]:
			if not worst.has(key) or m[key] > worst[key][0]:
				worst[key] = [m[key], label]
		if m.drift_quer > C.MAX_PARKED_DRIFT_M or m.drift_bergauf > C.MAX_PARKED_DRIFT_M \
				or m.angular > C.MAX_PARKED_ANGULAR_VELOCITY or m.righting > C.MAX_SELF_RIGHT_TIME_S:
			failures.append("%s (quer %.3f m, bergauf %.3f m, %.4f rad/s, aufstellen %.1f s)" % [
				label, m.drift_quer, m.drift_bergauf, m.angular, m.righting])
	print("  %d Baupläne geprüft, %d schaffen die 30-cm-Stufe" % [designs.size(), climbers])
	for f in failures:
		print("  ❌ ", f)
	_report("baukasten", "Drift quer, schlechtester (%s)" % worst.drift_quer[1], worst.drift_quer[0], C.MAX_PARKED_DRIFT_M, "m")
	_report("baukasten", "Drift bergauf, schlechtester (%s)" % worst.drift_bergauf[1], worst.drift_bergauf[0], C.MAX_PARKED_DRIFT_M, "m")
	_report("baukasten", "Zittern, schlechtester (%s)" % worst.angular[1], worst.angular[0], C.MAX_PARKED_ANGULAR_VELOCITY, "rad/s")
	_report("baukasten", "Aufstellen, schlechtester (%s)" % worst.righting[1], worst.righting[0], C.MAX_SELF_RIGHT_TIME_S, "s")
	_report("baukasten", "Baupläne mit Fehler", failures.size(), 0, "")


## Volle Matrix der fahrwerksrelevanten Teile im ungünstigsten Aufbau (schwer, hoher Schwerpunkt,
## Portalachsen, glatte Reifen, alle Extras), dazu jedes übrige Teil einzeln am Standard-Crawler
## und alle Vorlagen.
func _baukasten_designs() -> Array:
	var out := []
	for chassis in PartCatalog.parts(&"fahrgestell"):
		for wheels in PartCatalog.parts(&"raeder"):
			for suspension in PartCatalog.parts(&"federung"):
				var d := CrawlerDesign.new()
				d.choices[&"fahrgestell"] = chassis.id
				d.choices[&"raeder"] = wheels.id
				d.choices[&"federung"] = suspension.id
				d.choices[&"reifen"] = &"glatt"
				d.choices[&"achsen"] = &"portal"
				d.choices[&"aufbau"] = &"feuerwehr"
				d.choices[&"extras"] = PartCatalog.parts(&"extras").map(func(p): return p.id)
				out.append(["%s/%s/%s" % [chassis.id, wheels.id, suspension.id], d])
	for category in [&"achsen", &"reifen", &"motor", &"lenkung", &"aufbau"]:
		for p in PartCatalog.parts(category):
			var d := CrawlerDesign.new()
			d.choices[category] = p.id
			out.append(["%s=%s" % [category, p.id], d])
	for preset in PartCatalog.PRESETS:
		out.append(["vorlage=%s" % preset.id, CrawlerDesign.from_preset(preset)])
	return out


func _check_design(design: CrawlerDesign) -> Dictionary:
	var spec := VehicleSpec.from_design(design)
	var clearance := -C.WHEEL_MOUNT_Y_M + spec.travel + spec.wheel_radius + 0.05
	var ramp_basis := Basis(Vector3.RIGHT, deg_to_rad(C.TARGET_HILL_ANGLE_DEG))
	var m := {"angular": 0.0}

	for turn in [Basis(Vector3.UP, PI / 2), Basis()]:
		_new_stage()
		_box(Vector3(60, 1, 60), Vector3.ZERO, ramp_basis)
		var v := _spawn(Transform3D(ramp_basis * turn, ramp_basis.y * (0.5 + clearance)), design)
		await _run(3.0)
		var parked := await _measure_parked(v, 5.0)
		m["drift_quer" if turn != Basis() else "drift_bergauf"] = parked.drift
		m.angular = maxf(m.angular, parked.max_angular)

	_new_stage()
	_flat_ground()
	var top := spec.body_size.y * 0.5 + spec.cab_size.y
	var flipped := _spawn(Transform3D(Basis(Vector3.BACK, PI), Vector3(0, top + 0.5, 0)), design)
	var r := {"time": INF, "t": 0.0}
	await _run(6.0, func():
		r.t += 1.0 / C.PHYSICS_TICKS_PER_SECOND
		var upright: bool = flipped.global_basis.y.dot(Vector3.UP) > 0.9
		var calm: bool = flipped.angular_velocity.length() < 0.5 and not flipped.is_righting()
		if r.time == INF and r.t > 0.5 and upright and calm:
			r.time = r.t
	)
	m.righting = r.time

	_new_stage()
	_flat_ground()
	_box(Vector3(20, C.TARGET_STEP_HEIGHT_M, 20), Vector3(0, C.TARGET_STEP_HEIGHT_M / 2, -15))
	var climber := _spawn(Transform3D(Basis(), Vector3(0, clearance, 0)), design)
	climber.input = BotInputSource.new([{"duration": 8.0, "throttle": 1.0}])
	await _run(8.0)
	m.climbs = climber.global_position.z < -8.0 and climber.global_position.y > C.TARGET_STEP_HEIGHT_M
	return m


func _new_stage() -> void:
	if _stage:
		_stage.queue_free()
	_stage = Node3D.new()
	add_child(_stage)


# --- Bausteine ---------------------------------------------------------------


func _parked_on_ramp(name: String, vehicle_turn: Basis) -> void:
	var ramp_basis := Basis(Vector3.RIGHT, deg_to_rad(C.TARGET_HILL_ANGLE_DEG))  # -Z zeigt bergauf
	_box(Vector3(60, 1, 60), Vector3.ZERO, ramp_basis)
	var up := ramp_basis.y
	var vehicle := _spawn(Transform3D(ramp_basis * vehicle_turn, up * (0.5 + SPAWN_CLEARANCE)))
	await _run(4.0)
	var m := await _measure_parked(vehicle, 10.0)
	_report(name, "Drift in 10 s", m.drift, C.MAX_PARKED_DRIFT_M, "m")
	_report(name, "Winkelgeschw. im Stand", m.max_angular, C.MAX_PARKED_ANGULAR_VELOCITY, "rad/s")


func _measure_parked(vehicle: KraxlVehicle, seconds: float) -> Dictionary:
	var m := {"start": vehicle.global_position, "max_angular": 0.0}
	await _run(seconds, func():
		m.max_angular = maxf(m.max_angular, vehicle.angular_velocity.length())
	)
	m.drift = vehicle.global_position.distance_to(m.start)
	return m


func _run(seconds: float, each_tick: Callable = Callable()) -> void:
	for i in int(seconds * C.PHYSICS_TICKS_PER_SECOND):
		await get_tree().physics_frame
		if each_tick.is_valid():
			each_tick.call()


func _spawn(xform: Transform3D, design: CrawlerDesign = null) -> KraxlVehicle:
	var vehicle := KraxlVehicle.new()
	vehicle.sounds = false
	vehicle.smoke = false
	if design:
		vehicle.design = design
	vehicle.transform = xform
	_stage.add_child(vehicle)
	_camera = Camera3D.new()
	_camera.position = xform.origin + Vector3(6, 4, 8)
	_stage.add_child(_camera)
	_camera.look_at(xform.origin)
	return vehicle


func _flat_ground() -> void:
	_box(Vector3(100, 1, 100), Vector3(0, -0.5, 0))


func _box(size: Vector3, position: Vector3, basis := Basis()) -> void:
	var body := StaticBody3D.new()
	body.transform = Transform3D(basis, position)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	body.add_child(visual)
	_stage.add_child(body)


## Grenzen sind Obergrenzen, mit `at_least` Untergrenzen.
func _report(
	scenario: String, metric: String, value: float, limit: float, unit: String, at_least := false
) -> void:
	var ok := value >= limit if at_least else value <= limit
	results.append({
		"szenario": scenario, "metrik": metric, "wert": value, "grenze": limit,
		"einheit": unit, "mindestens": at_least, "ok": ok,
	})


func _markdown_table() -> String:
	var lines := ["| Szenario | Metrik | Wert | Grenze | ok |", "|---|---|---|---|---|"]
	for r in results:
		var value := "—" if is_inf(r.wert) else "%.4f %s" % [r.wert, r.einheit]
		var op := "≥" if r.mindestens else "≤"
		lines.append("| %s | %s | %s | %s %s %s | %s |" % [r.szenario, r.metrik, value, op, r.grenze, r.einheit, "✅" if r.ok else "❌"])
	return "\n".join(lines)


func _parse_args() -> Dictionary:
	var out := {}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var kv := arg.substr(2).split("=", true, 1)
			out[kv[0]] = kv[1]
	return out
