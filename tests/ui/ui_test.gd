extends Node
## Tests für Gamepad-Belegung (ADR 0009), Bauplan (ADR 0008) und Garage.
## Aufruf: godot --headless res://tests/ui/ui_test.tscn
## Exit-Code 1 bei einem fehlgeschlagenen Check oder bei JEDEM Skriptfehler während des Laufs.

var _failures: Array[String] = []
var _checks := 0
var _logger := ErrorCounter.new()


class ErrorCounter:
	extends Logger
	var errors: Array[String] = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != ERROR_TYPE_WARNING:
			errors.append("%s:%d %s %s %s" % [file, line, function, code, rationale])


func _ready() -> void:
	OS.add_logger(_logger)
	await get_tree().process_frame
	_test_gamepad()
	_test_design()
	await _test_garage()
	await _test_sounds()
	await _test_models_and_tools()

	for e in _logger.errors:
		_failures.append("Skriptfehler: " + e)
	print("\n%d Checks, %d Fehler" % [_checks, _failures.size()])
	for f in _failures:
		print("  ❌ ", f)
	get_tree().quit(1 if not _failures.is_empty() else 0)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)


# --- Gamepad / Tastatur --------------------------------------------------------


func _test_gamepad() -> void:
	var source := ActionInputSource.new()
	# Knopf-Paare: bei A/B- oder X/Y-Tausch (8BitDo-Modi) bleibt die Bedeutung gleich.
	for button in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_RIGHT_SHOULDER]:
		_check(_with_button(source, button).throttle == 1.0, "Knopf %d fährt vorwärts" % button)
	for button in [JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_LEFT_SHOULDER]:
		_check(_with_button(source, button).throttle == -1.0, "Knopf %d fährt rückwärts" % button)
	_check(_with_button(source, JOY_BUTTON_DPAD_LEFT).steer == -1.0, "Steuerkreuz links lenkt links")
	_check(_with_button(source, JOY_BUTTON_DPAD_RIGHT).steer == 1.0, "Steuerkreuz rechts lenkt rechts")

	_check(_with_axis(source, JOY_AXIS_TRIGGER_RIGHT, 1.0).throttle > 0.99, "R2 (analog) gibt Gas")
	_check(_with_axis(source, JOY_AXIS_TRIGGER_LEFT, 1.0).throttle < -0.99, "L2 (analog) fährt rückwärts")
	_check(_with_axis(source, JOY_AXIS_LEFT_X, 0.8).steer > 0.6, "Stick rechts lenkt")
	_check(_with_axis(source, JOY_AXIS_LEFT_X, 0.2).steer == 0.0, "Stick-Totzone schluckt Zittern")

	# Zweiter Controller (z. B. Adapter + Bluetooth-Pad gleichzeitig) wirkt genauso.
	_press_button(JOY_BUTTON_A, true, 3)
	source.update(0.0)
	_check(source.throttle == 1.0, "Zweiter Controller (Gerät 3) fährt auch")
	_press_button(JOY_BUTTON_A, false, 3)

	_check(KraxlInput.describe_joypads() == "kein Gamepad", "Statuszeile ohne Controller")
	var mapping_file := "user://test_mappings.txt"
	var f := FileAccess.open(mapping_file, FileAccess.WRITE)
	f.store_string("# Kommentar\n\n" + "030000000000000000000000000000ff,Kraxl Testpad,a:b0,b:b1,x:b2,y:b3,platform:Linux\n")
	f.close()
	_check(KraxlInput.load_extra_mappings(mapping_file) == 1, "Zusatz-Mappings werden geladen (Kommentare ignoriert)")
	_check(KraxlInput.load_extra_mappings(KraxlInput.EXTRA_MAPPINGS) == 0, "Mitgelieferte Zusatzdatei ist gültig")

	_press_button(JOY_BUTTON_LEFT_STICK, true)
	source.update(0.0)
	_check(source.horn, "L3 hupt")
	_press_button(JOY_BUTTON_LEFT_STICK, false)
	source.update(0.0)
	_check(not source.horn, "Hupe aus nach Loslassen")

	_press_button(JOY_BUTTON_BACK, true)
	_check(Input.is_action_pressed(KraxlInput.GARAGE), "Select öffnet die Garage")
	_press_button(JOY_BUTTON_BACK, false)

	_check(_has_joy_button(&"ui_accept", JOY_BUTTON_A) and _has_joy_button(&"ui_accept", JOY_BUTTON_B),
		"Menü bestätigt mit beiden rechten Knöpfen")
	_check(_has_joy_button(&"ui_left", JOY_BUTTON_DPAD_LEFT) and _has_joy_button(&"ui_down", JOY_BUTTON_DPAD_DOWN),
		"Steuerkreuz wandert durch die Garage")

	var key := InputEventKey.new()
	key.physical_keycode = KEY_UP
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	source.update(0.0)
	_check(source.throttle == 1.0, "Pfeil hoch fährt vorwärts")
	var release := key.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()


func _with_button(source: ActionInputSource, button: JoyButton) -> ActionInputSource:
	_press_button(button, true)
	source.update(0.0)
	var copy := ActionInputSource.new()
	copy.throttle = source.throttle
	copy.steer = source.steer
	_press_button(button, false)
	return copy


func _with_axis(source: ActionInputSource, axis: JoyAxis, value: float) -> ActionInputSource:
	_move_axis(axis, value)
	source.update(0.0)
	var copy := ActionInputSource.new()
	copy.throttle = source.throttle
	copy.steer = source.steer
	_move_axis(axis, 0.0)
	return copy


func _press_button(button: JoyButton, pressed: bool, device := 0) -> void:
	var e := InputEventJoypadButton.new()
	e.device = device
	e.button_index = button
	e.pressed = pressed
	e.pressure = 1.0 if pressed else 0.0
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func _move_axis(axis: JoyAxis, value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = 0
	e.axis = axis
	e.axis_value = value
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func _has_joy_button(action: StringName, button: JoyButton) -> bool:
	return InputMap.action_get_events(action).any(
		func(e): return e is InputEventJoypadButton and e.button_index == button)


# --- Bauplan -------------------------------------------------------------------


func _test_design() -> void:
	var d := CrawlerDesign.new()
	d.select(&"raeder", &"monster")
	d.select(&"extras", &"licht")
	d.select(&"extras", &"fahne")
	d.select(&"extras", &"licht")  # zweimal = wieder ab
	var back := CrawlerDesign.from_dict(JSON.parse_string(JSON.stringify(d.to_dict())))
	_check(back.choices[&"raeder"] == &"monster", "Bauplan übersteht Speichern/Laden (Räder)")
	_check(back.selected_extras() == [&"fahne"], "Extras an/abwählen und speichern")

	var odd := CrawlerDesign.from_dict({"raeder": "gibtsnicht", "extras": ["licht", "quatsch"], "neu": "x"})
	_check(odd.choices[&"raeder"] == PartCatalog.default_id(&"raeder"), "Unbekanntes Teil fällt auf Standard zurück")
	_check(odd.selected_extras() == [&"licht"], "Unbekanntes Extra wird ignoriert")

	for preset in PartCatalog.PRESETS:
		var p := CrawlerDesign.from_preset(preset)
		_check(p.matches(preset), "Vorlage %s erkennt sich selbst" % preset.id)
		for category in PartCatalog.CATEGORIES:
			if category in PartCatalog.MULTI_SELECT:
				for id in p.choices[category]:
					_check(PartCatalog.has_part(category, id), "Vorlage %s: %s/%s existiert" % [preset.id, category, id])
			else:
				_check(PartCatalog.has_part(category, p.choices[category]),
					"Vorlage %s: %s/%s existiert" % [preset.id, category, p.choices[category]])

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 50:
		var r := CrawlerDesign.random(rng)
		var spec := VehicleSpec.from_design(r)
		_check(spec.mass > 0 and spec.wheel_mounts.size() >= 4, "Zufallsbauplan %d ist baubar" % i)


# --- Töne ----------------------------------------------------------------------


func _test_sounds() -> void:
	for s in [Sfx.blip(440.0), Sfx.click(), Sfx.horn(), Sfx.thud(), Sfx.cheer()]:
		_check(s.data.size() > 100, "Ton erzeugt (%d Bytes)" % s.data.size())
	for loop in [Sfx.engine_loop(55.0, 0.2), Sfx.engine_loop(85.0, 0.9), Sfx.track_rattle_loop()]:
		_check(loop.loop_mode == AudioStreamWAV.LOOP_FORWARD and loop.loop_end * 2 == loop.data.size(),
			"Schleife läuft nahtlos (Ende = Datenlänge)")
	Sfx.setup_bus()
	var bus := AudioServer.get_bus_index(Sfx.EFFECTS_BUS)
	_check(bus != -1 and AudioServer.get_bus_effect(bus, 0) is AudioEffectHardLimiter, "Effekte-Bus mit Begrenzer")

	var stage := Node3D.new()
	add_child(stage)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(60, 1, 60)
	shape.position.y = -0.5
	floor_body.add_child(shape)
	stage.add_child(floor_body)

	var design := CrawlerDesign.new()
	design.choices[&"reifen"] = &"ketten"
	var v := KraxlVehicle.new()
	v.design = design
	v.position = Vector3(0, 3.0, 0)
	var events := {"landed": 0, "righted": 0}
	v.landed.connect(func(_s): events.landed += 1)
	v.righted.connect(func(): events.righted += 1)
	stage.add_child(v)
	var audio: VehicleAudio = v.get_node("Audio")
	_check(audio != null and audio.engine.playing, "Motor läuft")
	_check(audio.rattle != null, "Ketten rattern bei Ketten-Reifen")
	await _physics_frames(240)
	_check(events.landed >= 1, "Aufsetzen nach Fall löst Plumps aus")
	var idle_pitch: float = audio.engine.pitch_scale

	var bot := BotInputSource.new([{"duration": 3.0, "throttle": 1.0}])
	v.input = bot
	await _physics_frames(240)
	_check(audio.engine.pitch_scale > idle_pitch + 0.2, "Motor wird mit Gas höher (%.2f -> %.2f)" % [idle_pitch, audio.engine.pitch_scale])

	v.input = InputSource.new()
	v.input.horn = true
	await _physics_frames(2)
	_check(audio.effects.playing and audio.effects.stream == Sfx.horn(), "Hupe ertönt")
	v.input.horn = false

	v.global_transform = Transform3D(Basis(Vector3.BACK, PI), v.global_position + Vector3(0, 2, 0))
	v.linear_velocity = Vector3.ZERO
	v.angular_velocity = Vector3.ZERO
	await _physics_frames(600)
	_check(events.righted >= 1, "Aufstellen spielt den Dreiklang (Signal righted)")

	var touch := TouchControls.new()
	var layer := CanvasLayer.new()
	add_child(layer)
	layer.add_child(touch)
	await get_tree().process_frame
	var horn_rect: Rect2 = touch._rects[TouchControls.Action.HORN]
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = horn_rect.get_center()
	touch._input(press)
	_check(touch.source.horn, "Touch-Hupe drückt die Hupe")
	_check(touch._click.playing, "Touch-Taste klickt")
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = horn_rect.get_center()
	touch._input(release)
	_check(not touch.source.horn, "Touch-Hupe loslassen")
	# Headless ist das Fenster winzig; geprüft wird mit echten Größen (PC-Fenster, kleines Handy quer).
	touch.show_light = true
	touch.show_tool = true
	for screen in [Vector2(1280, 720), Vector2(800, 360)]:
		touch.size = screen
		touch._layout()
		var rects: Array = touch._rects.values()
		for i in rects.size():
			_check(Rect2(Vector2.ZERO, screen).encloses(rects[i]), "Touch-Taste %d liegt im Bild (%s)" % [i, screen])
			for j in range(i + 1, rects.size()):
				_check(not rects[i].intersects(rects[j]), "Touch-Tasten %d/%d überlappen nicht (%s)" % [i, j, screen])
	layer.queue_free()
	stage.queue_free()


func _physics_frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


# --- Modelle, Licht, Werkzeug, Touch-Sichtbarkeit -------------------------------


func _test_models_and_tools() -> void:
	for body in KenneyModels.BODIES:
		var root := KenneyModels.instantiate(KenneyModels.BODIES[body])
		var mesh_node: MeshInstance3D = root.get_node("body")
		_check(KenneyModels.dominant_tile(mesh_node.mesh).x >= 0, "Kenney-Karosserie %s hat eine Lack-Kachel" % body)
		root.free()
	for tire in KenneyModels.WHEELS:
		var info := KenneyModels.wheel_mesh(tire)
		_check(info.mesh != null and info.radius > 0.1, "Kenney-Rad für %s" % tire)

	var stage := Node3D.new()
	add_child(stage)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(60, 1, 60)
	shape.position.y = -0.5
	floor_body.add_child(shape)
	stage.add_child(floor_body)

	for preset in PartCatalog.PRESETS:
		var v := KraxlVehicle.new()
		v.design = CrawlerDesign.from_preset(preset)
		v.position = Vector3(0, 2, 0)
		stage.add_child(v)
		var kenney := KenneyModels.has_body(v.design.choices[&"aufbau"])
		_check(v.has_node("KenneyBody") == kenney, "Vorlage %s: Kenney-Karosserie %s" % [preset.id, "ja" if kenney else "nein"])
		v.queue_free()
	await get_tree().physics_frame

	# Licht schalten: nur Fahrzeuge mit Extra „licht“, Tastendruck schaltet einmal um.
	var lit := CrawlerDesign.new()
	lit.choices[&"extras"] = [&"licht"]
	var car := KraxlVehicle.new()
	car.design = lit
	car.position = Vector3(0, 1.2, 0)
	stage.add_child(car)
	_check(car.has_lights() and car.lights_on, "Licht ist am Anfang an")
	car.input = InputSource.new()
	car.input.light = true
	await _physics_frames(3)
	_check(not car.lights_on, "Licht-Taste schaltet aus (einmal pro Druck)")
	var lamp: SpotLight3D = car._parts.lights[0]
	_check(not lamp.visible, "Scheinwerfer sind aus")
	car.input.light = false
	await _physics_frames(2)
	car.input.light = true
	await _physics_frames(2)
	_check(car.lights_on and lamp.visible, "Zweiter Druck schaltet wieder an")
	var plain := KraxlVehicle.new()
	stage.add_child(plain)
	_check(not plain.has_lights(), "Ohne Extra „licht“ gibt es nichts zu schalten")

	# Auspuffrauch: jedes Fahrzeug pafft, mit Extra „auspuff“ aus beiden Rohren; Gas = mehr Rauch.
	var plain_smoke := plain.find_children("Auspuffrauch*", "GPUParticles3D", true, false)
	_check(plain_smoke.size() == 1, "Ohne Extra: ein Endrohr raucht")
	var stacks := CrawlerDesign.new()
	stacks.choices[&"extras"] = [&"auspuff"]
	var smoker := KraxlVehicle.new()
	smoker.design = stacks
	smoker.position = Vector3(-6, 1.2, 0)
	stage.add_child(smoker)
	var puffs := smoker.find_children("Auspuffrauch*", "GPUParticles3D", true, false)
	_check(puffs.size() == 2, "Extra „auspuff“: zwei Rohre rauchen")
	var idle: float = puffs[0].amount_ratio
	smoker.input = InputSource.new()
	smoker.input.throttle = 1.0
	for i in 60:
		await get_tree().process_frame
	_check(puffs[0].amount_ratio > idle + 0.3, "Gas geben macht mehr Rauch")
	smoker.queue_free()

	# Werkzeug: Bagger-Arm und Radlader-Schaufel bewegen sich mit der Werkzeug-Taste.
	for body in [&"bagger", &"radlader"]:
		var d := CrawlerDesign.new()
		d.choices[&"aufbau"] = body
		var v := KraxlVehicle.new()
		v.design = d
		v.position = Vector3(6, 1.5, 0)
		stage.add_child(v)
		_check(v.has_tool(), "%s hat ein Werkzeug" % body)
		var node: Node3D = v._parts.tool.get("boom", v._parts.tool.get("shovel"))
		var before := node.transform
		v.input = InputSource.new()
		v.input.tool = 1.0
		for i in 90:
			await get_tree().process_frame
		_check(not node.transform.is_equal_approx(before), "%s: Werkzeug bewegt sich" % body)
		v.queue_free()

	# Touch-Tasten: Tastatur blendet aus, Berührung blendet ein.
	var touch := TouchControls.new()
	var layer := CanvasLayer.new()
	add_child(layer)
	layer.add_child(touch)
	await get_tree().process_frame
	touch.shown = true
	var key := InputEventKey.new()
	key.keycode = KEY_W
	key.pressed = true
	touch._input(key)
	_check(not touch.shown, "Tastatur blendet Touch-Tasten aus")
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	tap.position = Vector2(5, 5)
	touch._input(tap)
	_check(touch.shown, "Berührung blendet Touch-Tasten wieder ein")
	var lift := InputEventScreenTouch.new()
	lift.position = tap.position
	touch._input(lift)  # Finger weg – sonst bleibt die getroffene Taste gehalten
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	touch._input(pad)
	_check(not touch.shown, "Gamepad blendet Touch-Tasten aus")
	layer.queue_free()
	stage.queue_free()


# --- Garage --------------------------------------------------------------------


func _test_garage() -> void:
	var garage: Node = load("res://scenes/garage/garage.tscn").instantiate()
	add_child(garage)
	await get_tree().process_frame

	for category in garage._garage_categories():
		garage.show_category(category)
		await get_tree().process_frame
		_check(not garage._part_cards.is_empty(), "Kategorie %s zeigt Teile" % category)
		for card in garage._part_cards:
			var before: bool = card.selected
			garage.choose_part(card)
			if category in PartCatalog.MULTI_SELECT:
				_check(card.selected != before, "%s/%s schaltet beim Antippen um" % [category, card.part_id])
			else:
				_check(card.selected, "%s/%s ist nach dem Antippen ausgewählt" % [category, card.part_id])
		await get_tree().physics_frame

	for i in 5:
		garage.roll_dice()
		await get_tree().physics_frame
	_check(is_instance_valid(garage.vehicle), "Crawler steht nach dem Würfeln in der Garage")

	var saved := GameState.load_design()
	_check(saved.to_dict() == garage.design.to_dict(), "Garage speichert den aktuellen Crawler")

	for i in 60:
		await get_tree().physics_frame
	_check(garage.vehicle.global_position.y > 0.0, "Crawler fällt nicht durch den Garagenboden")
	garage.queue_free()
