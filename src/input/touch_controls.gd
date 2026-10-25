class_name TouchControls
extends Control
## Spike-Version der Steuerung „Kleine Hände“ (ADR 0003):
## links zwei Lenk-Tasten, rechts Vor/Zurück. Auslösen bei Touch-Down,
## beliebig viele Finger, ein Finger bleibt seiner Taste treu, auch wenn er verrutscht.
## Berührungen außerhalb der Tasten (z. B. Handballen am Rand) werden ignoriert.

const BUTTON_SIZE_MM := 25.0
const EDGE_MARGIN_MM := 5.0
const GAP_MM := 4.0

enum Action { STEER_LEFT, STEER_RIGHT, FORWARD, BACKWARD }

var source := TouchInputSource.new()

var _fingers := {}  # Finger-Index -> Action
var _rects := {}  # Action -> Rect2


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout)
	_layout()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var action: Variant = _action_at(event.position)
			if action != null:
				_fingers[event.index] = action
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
	queue_redraw()


func _draw() -> void:
	var held: Array = _fingers.values()
	for action in _rects:
		var rect: Rect2 = _rects[action]
		var color := Color(1, 1, 1, 0.85) if held.has(action) else Color(1, 1, 1, 0.35)
		draw_circle(rect.get_center(), rect.size.x * 0.5, color)
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


class TouchInputSource:
	extends InputSource
	# Werte werden direkt von TouchControls gesetzt.
	pass
