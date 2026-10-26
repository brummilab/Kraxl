class_name TouchControls
extends Control
## Spike-Version der Steuerung „Kleine Hände“ (ADR 0003):
## links zwei Lenk-Tasten mit der Hupe darüber, rechts Vor/Zurück. Auslösen bei Touch-Down,
## beliebig viele Finger, ein Finger bleibt seiner Taste treu, auch wenn er verrutscht.
## Berührungen außerhalb der Tasten (z. B. Handballen am Rand) werden ignoriert.
## Jede neue Berührung einer Taste gibt sofort einen Klick-Ton (M5).
## Sichtbar nur bei Touch: beim Start, wenn das Gerät einen Touchscreen hat, und nach jeder
## Berührung; Tastatur oder Gamepad blenden die Tasten aus (am PC stören sie sonst).
## Licht- und Werkzeug-Taste erscheinen nur, wenn das Fahrzeug Licht bzw. ein Werkzeug hat.
## Im Zwei-Spieler-Modus bekommt jede Bildschirmhälfte eigene Tasten (`fill_parent = false`,
## Anker setzt der Aufrufer); Berührungen in der anderen Hälfte gehören dem anderen Kind.

const BUTTON_SIZE_MM := 25.0
const EDGE_MARGIN_MM := 5.0
const GAP_MM := 4.0

enum Action { STEER_LEFT, STEER_RIGHT, FORWARD, BACKWARD, HORN, LIGHT, TOOL }

var source := TouchInputSource.new()
## true: füllt den ganzen Bildschirm (Ein-Spieler). false: Anker und Größe setzt der Aufrufer.
var fill_parent := true

var _fingers := {}  # Finger-Index -> Action
var _rects := {}  # Action -> Rect2
## Zusatztasten je nach Fahrzeug.
var show_light := false:
	set(value):
		show_light = value
		_layout()
var show_tool := false:
	set(value):
		show_tool = value
		_layout()
## false = ausgeblendet (keine Zeichnung); eine Berührung blendet wieder ein.
var shown := true:
	set(value):
		shown = value
		queue_redraw()
var _click: AudioStreamPlayer


func _ready() -> void:
	if fill_parent:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout)
	shown = DisplayServer.is_touchscreen_available()
	_layout()
	Sfx.setup_bus()
	_click = AudioStreamPlayer.new()
	_click.stream = Sfx.click()
	_click.bus = Sfx.EFFECTS_BUS
	_click.max_polyphony = 4
	add_child(_click)


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton \
			or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		if shown and _fingers.is_empty():
			shown = false
		return
	if event is InputEventScreenTouch:
		if event.pressed and not shown:
			shown = true
		if event.pressed:
			var action: Variant = _action_at(make_input_local(event).position)
			if action != null:
				_fingers[event.index] = action
				_click.play()
		else:
			_fingers.erase(event.index)
		_apply()


func _layout() -> void:
	var dpi := float(DisplayServer.screen_get_dpi())
	var px_per_mm := maxf(dpi, 96.0) / 25.4
	var s := maxf(BUTTON_SIZE_MM * px_per_mm, size.y * 0.22)
	var m := EDGE_MARGIN_MM * px_per_mm
	var g := GAP_MM * px_per_mm
	var bottom := size.y - m - s
	_rects[Action.STEER_LEFT] = Rect2(m, bottom, s, s)
	_rects[Action.STEER_RIGHT] = Rect2(m + s + g, bottom, s, s)
	_rects[Action.FORWARD] = Rect2(size.x - m - s, bottom - s - g, s, s)
	_rects[Action.BACKWARD] = Rect2(size.x - m - s, bottom, s, s)
	var h := s * 0.75  # Zusatztasten etwas kleiner
	_rects[Action.HORN] = Rect2(m + (s + g) * 0.5 + (s - h) * 0.5, bottom - h - g, h, h)
	_rects.erase(Action.LIGHT)
	_rects.erase(Action.TOOL)
	if show_light:  # über Vor/Zurück
		_rects[Action.LIGHT] = Rect2(size.x - m - s + (s - h) * 0.5, bottom - s - g - h - g, h, h)
	if show_tool:  # links neben Vor/Zurück, auf Daumenhöhe
		_rects[Action.TOOL] = Rect2(size.x - m - s - g - h, bottom + (s - h) * 0.5, h, h)
	queue_redraw()


func _action_at(pos: Vector2) -> Variant:
	if not Rect2(Vector2.ZERO, size).has_point(pos):
		return null  # andere Bildschirmhälfte (Zwei-Spieler) oder außerhalb
	for action in _rects:
		if _rects[action].has_point(pos):
			return action
	return null


func _apply() -> void:
	var held: Array = _fingers.values()
	source.steer = float(held.has(Action.STEER_RIGHT)) - float(held.has(Action.STEER_LEFT))
	source.throttle = float(held.has(Action.FORWARD)) - float(held.has(Action.BACKWARD))
	source.horn = held.has(Action.HORN)
	source.light = held.has(Action.LIGHT)
	source.tool = 1.0 if held.has(Action.TOOL) else 0.0
	queue_redraw()


func _draw() -> void:
	if not shown:
		return
	var held: Array = _fingers.values()
	for action in _rects:
		var rect: Rect2 = _rects[action]
		var color := Color(1, 1, 1, 0.85) if held.has(action) else Color(1, 1, 1, 0.35)
		draw_circle(rect.get_center(), rect.size.x * 0.5, color)
		match action:
			Action.HORN: _draw_horn(rect)
			Action.LIGHT: _draw_light(rect)
			Action.TOOL: _draw_tool(rect)
			_: _draw_arrow(rect, action)


func _draw_arrow(rect: Rect2, action: Action) -> void:
	var c := rect.get_center()
	var r := rect.size.x * 0.25
	var dir: Vector2 = {
		Action.STEER_LEFT: Vector2.LEFT,
		Action.STEER_RIGHT: Vector2.RIGHT,
		Action.FORWARD: Vector2.UP,
		Action.BACKWARD: Vector2.DOWN,
	}[action]
	var side := dir.orthogonal()
	draw_colored_polygon(
		PackedVector2Array([c + dir * r, c - dir * r * 0.6 + side * r, c - dir * r * 0.6 - side * r]),
		Color(0.1, 0.1, 0.1, 0.9)
	)


## Hupe: Trichter mit Schallwellen (Form statt Text, Farbe nur als Zusatz).
func _draw_horn(rect: Rect2) -> void:
	var c := rect.get_center()
	var r := rect.size.x * 0.22
	var ink := Color(0.1, 0.1, 0.1, 0.9)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-1.2, -0.3) * r, c + Vector2(-0.4, -0.3) * r, c + Vector2(0.4, -0.9) * r,
		c + Vector2(0.4, 0.9) * r, c + Vector2(-0.4, 0.3) * r, c + Vector2(-1.2, 0.3) * r,
	]), Color(0.98, 0.8, 0.15))
	for i in 2:
		draw_arc(c + Vector2(0.4, 0) * r, r * (0.6 + i * 0.5), -0.7, 0.7, 12, ink, r * 0.18)


## Licht: Glühbirne mit Strahlen.
func _draw_light(rect: Rect2) -> void:
	var c := rect.get_center()
	var r := rect.size.x * 0.2
	draw_circle(c + Vector2(0, -0.2) * r, r * 0.8, Color(1.0, 0.9, 0.3))
	draw_rect(Rect2(c + Vector2(-0.4, 0.5) * r, Vector2(0.8, 0.6) * r), Color(0.3, 0.3, 0.35))
	for a in [-2.4, -1.57, -0.74]:
		var d := Vector2.from_angle(a)
		draw_line(c + Vector2(0, -0.2) * r + d * r * 1.1, c + Vector2(0, -0.2) * r + d * r * 1.6, Color(0.1, 0.1, 0.1, 0.9), r * 0.18)


## Werkzeug: Baggerschaufel mit Zähnen.
func _draw_tool(rect: Rect2) -> void:
	var c := rect.get_center()
	var r := rect.size.x * 0.22
	draw_line(c + Vector2(-1.1, -0.9) * r, c + Vector2(0.1, -0.2) * r, Color(0.95, 0.75, 0.1), r * 0.35)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-0.2, -0.5) * r, c + Vector2(0.9, -0.3) * r, c + Vector2(0.9, 0.7) * r, c + Vector2(-0.4, 0.5) * r,
	]), Color(0.6, 0.62, 0.66))
	for i in 3:
		draw_rect(Rect2(c + Vector2(-0.3 + i * 0.4, 0.5) * r, Vector2(0.22, 0.35) * r), Color(0.1, 0.1, 0.1, 0.9))


class TouchInputSource:
	extends InputSource
	# Werte werden direkt von TouchControls gesetzt.
	pass
