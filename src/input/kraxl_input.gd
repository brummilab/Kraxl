class_name KraxlInput
## Eingabe-Belegung für Tastatur und Gamepad (ADR 0009), geprüft mit dem 8BitDo SN30 Pro.
##
## Der SN30 Pro meldet je nach Modus (X-Input, D-Input/Android, Switch) A/B und X/Y vertauscht
## (Nintendo-Beschriftung vs. Xbox-Position, vgl. SDL-Issue #9916). Deshalb liegt jede Fahraktion
## auf einem Knopf-PAAR, das bei so einem Tausch gleich bleibt:
##   rechte Knöpfe A + B (unten/rechts) und R/R2  -> vorwärts
##   linke Knöpfe X + Y (oben/links) und L/L2     -> rückwärts
##   Steuerkreuz und linker Stick                 -> lenken
##   Select                                       -> zurück in die Garage
## Keine Vibration: Auf Android braucht sie die VIBRATE-Berechtigung (ADR 0007: keine Berechtigungen).

const FORWARD := &"kraxl_vor"
const BACKWARD := &"kraxl_zurueck"
const LEFT := &"kraxl_links"
const RIGHT := &"kraxl_rechts"
const GARAGE := &"kraxl_garage"
const STICK_DEADZONE := 0.3


## Registriert die Actions einmalig. Idempotent, darf von jeder Szene aufgerufen werden.
static func setup() -> void:
	if InputMap.has_action(FORWARD):
		return
	_add(FORWARD, [KEY_UP, KEY_W], [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_RIGHT_SHOULDER], [[JOY_AXIS_TRIGGER_RIGHT, 1.0]])
	_add(BACKWARD, [KEY_DOWN, KEY_S], [JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_LEFT_SHOULDER], [[JOY_AXIS_TRIGGER_LEFT, 1.0]])
	_add(LEFT, [KEY_LEFT, KEY_A], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_add(RIGHT, [KEY_RIGHT, KEY_D], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_add(GARAGE, [KEY_G, KEY_ESCAPE], [JOY_BUTTON_BACK], [])

	# Menüs (Garage): Godot 4.7 belegt ui_* standardmäßig nur mit Tasten. Steuerkreuz und Stick
	# wandern zwischen den Karten, beide rechten Knöpfe bestätigen, egal welches Layout gemeldet wird.
	_add_joy(&"ui_accept", [JOY_BUTTON_A, JOY_BUTTON_B], [])
	_add_joy(&"ui_left", [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_add_joy(&"ui_right", [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_add_joy(&"ui_up", [JOY_BUTTON_DPAD_UP], [[JOY_AXIS_LEFT_Y, -1.0]])
	_add_joy(&"ui_down", [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])


static func _add(action: StringName, keys: Array, buttons: Array, axes: Array) -> void:
	InputMap.add_action(action, STICK_DEADZONE)
	for key in keys:
		var e := InputEventKey.new()
		e.physical_keycode = key
		InputMap.action_add_event(action, e)
	_add_joy(action, buttons, axes)


static func _add_joy(action: StringName, buttons: Array, axes: Array) -> void:
	for button in buttons:
		var e := InputEventJoypadButton.new()
		e.button_index = button
		e.device = -1  # alle Controller
		InputMap.action_add_event(action, e)
	for axis in axes:
		var e := InputEventJoypadMotion.new()
		e.axis = axis[0]
		e.axis_value = axis[1]
		e.device = -1
		InputMap.action_add_event(action, e)

