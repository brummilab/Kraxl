class_name TouchControls
extends Control
## Spike-Version der Steuerung „Kleine Hände“ (ADR 0003):
## links zwei Lenk-Tasten mit der Hupe darüber, rechts Vor/Zurück. Auslösen bei Touch-Down,
## beliebig viele Finger, ein Finger bleibt seiner Taste treu, auch wenn er verrutscht.
## Berührungen außerhalb der Tasten (z. B. Handballen am Rand) werden ignoriert.
## Jede neue Berührung einer Taste gibt sofort einen Klick-Ton (M5).

const BUTTON_SIZE_MM := 25.0
const EDGE_MARGIN_MM := 5.0
const GAP_MM := 4.0

enum Action { STEER_LEFT, STEER_RIGHT, FORWARD, BACKWARD, HORN }

var source := TouchInputSource.new()

var _fingers := {}  # Finger-Index -> Action
var _rects := {}  # Action -> Rect2
var _click: AudioStreamPlayer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout)
	_layout()
	Sfx.setup_bus()
	_click = AudioStreamPlayer.new()
	_click.stream = Sfx.click()
	_click.bus = Sfx.EFFECTS_BUS
	_click.max_polyphony = 4
	add_child(_click)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var action: Variant = _action_at(event.position)
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
	var h := s * 0.75  # Hupe etwas kleiner, mittig über den Lenk-Tasten
	_rects[Action.HORN] = Rect2(m + (s + g) * 0.5 + (s - h) * 0.5, bottom - h - g, h, h)
	queue_redraw()


func _action_at(pos: Vector2) -> Variant:
	for action in _rects:
		if _rects[action].has_point(pos):
			return action
	return null


func _apply() -> void:
	var held: Array = _fingers.values()
	source.steer = float(held.has(Action.STEER_RIGHT)) - float(held.has(Action.STEER_LEFT))
	source.throttle = float(held.has(Action.FORWARD)) - float(held.has(Action.BACKWARD))
	source.horn = held.has(Action.HORN)
	queue_redraw()


func _draw() -> void:
	var held: Array = _fingers.values()
	for action in _rects:
		var rect: Rect2 = _rects[action]
		var color := Color(1, 1, 1, 0.85) if held.has(action) else Color(1, 1, 1, 0.35)
		draw_circle(rect.get_center(), rect.size.x * 0.5, color)
		if action == Action.HORN:
			_draw_horn(rect)
		else:
			_draw_arrow(rect, action)


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


class TouchInputSource:
	extends InputSource
	# Werte werden direkt von TouchControls gesetzt.
	pass
