class_name IconCard
extends Button
## Großer Knopf mit gezeichnetem Symbol statt Text (ADR 0003/0008).
## Löst bei Touch-Down aus. Ausgewählt = dicker Rahmen + Haken, nicht nur eine Farbe (M5).

var category: StringName
var part_id: StringName
var accent := Color(0.95, 0.55, 0.1)
## Nur für Vorlagen-Karten: der Eintrag aus PartCatalog.PRESETS.
var preset := {}
var selected := false:
	set(value):
		selected = value
		queue_redraw()


func _init(card_category: StringName, card_part: StringName = &"", size_px := 110.0) -> void:
	category = card_category
	part_id = card_part
	custom_minimum_size = Vector2(size_px, size_px)
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	pivot_offset = custom_minimum_size * 0.5
	resized.connect(func(): pivot_offset = size * 0.5)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size).grow(-size.x * 0.08)
	if not preset.is_empty():
		PartIcons.draw_preset(self, preset, r)
	elif part_id == &"":
		PartIcons.draw_category(self, category, r, accent)
	else:
		PartIcons.draw_part(self, category, part_id, r, accent)
	if selected:
		draw_rect(Rect2(Vector2.ZERO, size).grow(-3), Color(1.0, 0.85, 0.1), false, 6.0)
		var c := size - Vector2(18, 18)
		draw_circle(c, 13, Color(0.2, 0.7, 0.3))
		draw_polyline(PackedVector2Array([c + Vector2(-6, 0), c + Vector2(-1, 5), c + Vector2(7, -5)]), Color.WHITE, 3.0)


## Kurzes Hüpfen als sofortiges Feedback auf jede Berührung (M5).
func bounce() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.06)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)
