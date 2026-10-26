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


func _press_button(button: JoyButton, pressed: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.device = 0
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
