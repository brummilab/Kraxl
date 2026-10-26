class_name PartIcons
## Zeichnet textfreie Symbole für Kategorien und Teile (Platzhalter für spätere Grafiken).
## Unterschiede liegen immer in der Form, nie nur in der Farbe (M5, Farbsehschwäche).

const INK := Color(0.12, 0.12, 0.14)
const TIRE := Color(0.15, 0.15, 0.15)
const METAL := Color(0.6, 0.62, 0.66)


static func draw_category(ci: CanvasItem, category: StringName, r: Rect2, accent: Color) -> void:
	match category:
		&"fahrgestell": draw_part(ci, category, &"mittel", r, accent)
		&"vorlagen": _presets_stack(ci, r, accent)
		&"raeder": _wheel(ci, r.get_center(), r.size.x * 0.33, &"stollen", accent)
		&"achsen": draw_part(ci, category, &"portal", r, accent)
		&"reifen": _wheel(ci, r.get_center(), r.size.x * 0.33, &"matsch", accent)
		&"federung": draw_part(ci, category, &"normal", r, accent)
		&"motor": _bolt(ci, r.get_center(), r.size.x * 0.32, Color(1.0, 0.8, 0.1))
		&"lenkung": _steering_wheel(ci, r.get_center(), r.size.x * 0.32)
		&"aufbau": draw_part(ci, category, &"jeep", r, accent)
		&"farbe": _palette(ci, r)
		&"extras": _star(ci, r.get_center(), r.size.x * 0.34, Color(1.0, 0.8, 0.1))
		&"los": _flag(ci, r, Color(0.2, 0.75, 0.3))
		&"wuerfel": _dice(ci, r)
		&"garage": _wrench(ci, r)
		&"spieler": draw_part(ci, category, &"1", r, accent)


static func draw_part(ci: CanvasItem, category: StringName, id: StringName, r: Rect2, accent: Color) -> void:
	var c := r.get_center()
	var u := r.size.x / 100.0  # Zeichen-Einheit: Symbol ist 100 × 100 „Pixel“
	match category:
		&"fahrgestell":
			# Draufsicht: Rahmen mit Rädern an den Achsen.
			var p: Dictionary = PartCatalog.part(category, id)
			var scale := 22.0 * u
			var length: float = p.groesse.z * scale
			var width: float = p.spur * scale
			ci.draw_rect(Rect2(c - Vector2(width * 0.35, length * 0.5), Vector2(width * 0.7, length)), accent)
			for z in p.achsen:
				for x in [-0.5, 0.5]:
					var w := Vector2(9 * u, 16 * u)
					ci.draw_rect(Rect2(c + Vector2(x * width, z * scale) - w * 0.5, w), TIRE)
		&"raeder":
			var radius: float = PartCatalog.part(category, id).radius
			_wheel(ci, c, radius * 65.0 * u, &"stollen", accent)
		&"achsen":
			# Vorderansicht einer Achse: normal = gerade mit Differential unten,
			# portal = Differential hochgesetzt, Getriebekästen an den Enden.
			var portal := id == &"portal"
			var axle_y := c.y + (2 if portal else 12) * u
			var wheel_y := c.y + 12 * u
			for x in [-1.0, 1.0]:
				ci.draw_rect(Rect2(Vector2(c.x + x * 34 * u - 7 * u, wheel_y - 20 * u), Vector2(14, 40) * u), TIRE)
				if portal:
					ci.draw_rect(Rect2(Vector2(c.x + x * 25 * u - 5 * u, axle_y - 2 * u), Vector2(10, 16) * u), METAL.darkened(0.3))
			ci.draw_line(Vector2(c.x - 28 * u, axle_y), Vector2(c.x + 28 * u, axle_y), METAL.darkened(0.3), 6 * u)
			ci.draw_circle(Vector2(c.x, axle_y), 10 * u, accent)
			ci.draw_line(Vector2(c.x - 40 * u, c.y + 34 * u), Vector2(c.x + 40 * u, c.y + 34 * u), INK, 2 * u)
			ci.draw_line(Vector2(c.x, axle_y + 10 * u), Vector2(c.x, c.y + 34 * u), Color(0.3, 0.6, 0.95), 2 * u)
		&"reifen":
			if id == &"ketten":
				_track(ci, c, 40 * u, accent)
			else:
				_wheel(ci, c, 32 * u, id, accent)
		&"federung":
			var p: Dictionary = PartCatalog.part(category, id)
			var height: float = 30.0 + p.weg * 80.0
			var coils := 4 if id == &"weich" else (7 if id == &"hart" else 5)
			var thickness := 7.0 if id == &"hart" else 4.0
			_spring(ci, c, height * u, 22 * u, coils, thickness * u, accent)
		&"motor":
			var count: int = {&"gemuetlich": 1, &"normal": 2, &"stark": 3}[id]
			for i in count:
				var offset := (i - (count - 1) * 0.5) * 24.0 * u
				_bolt(ci, c + Vector2(offset, 0), 22 * u, Color(1.0, 0.8, 0.1))
		&"lenkung":
			var rear: float = PartCatalog.part(category, id).hinten
			ci.draw_rect(Rect2(c - Vector2(14, 30) * u, Vector2(28, 60) * u), accent)
			for z in [-1.0, 1.0]:
				var angle := 0.45 if z < 0 else 0.45 * rear / 0.6
				for x in [-1.0, 1.0]:
					_rotated_rect(ci, c + Vector2(x * 22, z * 22) * u, Vector2(9, 18) * u, angle, TIRE)
		&"aufbau":
			_body_silhouette(ci, id, c, u, accent)
		&"farbe":
			if PartCatalog.part(category, id).get("regenbogen", false):
				_rainbow(ci, c, 32 * u)
			else:
				ci.draw_circle(c, 32 * u, PartCatalog.part(category, id).farbe)
			ci.draw_arc(c, 32 * u, 0, TAU, 48, INK, 3 * u)
		&"extras":
			_extra(ci, id, c, u, accent)
		&"spieler":
			# Spielerzahl: eine oder zwei Figuren nebeneinander.
			var count := int(String(id))
			for i in count:
				var offset := (i - (count - 1) * 0.5) * 34.0 * u
				_figure(ci, c + Vector2(offset, 0), u * (1.0 if count == 1 else 0.8), [accent, Color(0.25, 0.7, 0.3)][i], 0)
		&"fahrer":
			# Wessen Crawler wird gebaut? Figur mit 1 bzw. 2 Punkten auf dem Helm (Form, nicht nur Farbe).
			_figure(ci, c, u, accent, int(String(id)))


## Kinderfigur mit Helm; `dots` Punkte auf dem Helm unterscheiden Spieler 1 und 2.
static func _figure(ci: CanvasItem, c: Vector2, u: float, color: Color, dots: int) -> void:
	ci.draw_rect(Rect2(c + Vector2(-16, 4) * u, Vector2(32, 34) * u), color)
	ci.draw_circle(c + Vector2(0, -14) * u, 15 * u, Color(0.98, 0.82, 0.68))
	ci.draw_arc(c + Vector2(0, -14) * u, 15 * u, PI, TAU, 16, color.darkened(0.2), 9 * u)
	for i in dots:
		ci.draw_circle(c + Vector2((i - (dots - 1) * 0.5) * 12, -25) * u, 4.5 * u, Color.WHITE)
	ci.draw_circle(c + Vector2(-5, -12) * u, 2.2 * u, INK)
	ci.draw_circle(c + Vector2(5, -12) * u, 2.2 * u, INK)
	ci.draw_arc(c + Vector2(0, -9) * u, 6 * u, 0.3, PI - 0.3, 8, INK, 2 * u)


static func _wheel(ci: CanvasItem, c: Vector2, radius: float, tire: StringName, hub: Color) -> void:
	match tire:
		&"stollen":
			for i in 10:
				var a := TAU * i / 10.0
				_rotated_rect(ci, c + Vector2.from_angle(a) * radius, Vector2(radius * 0.22, radius * 0.3), a, TIRE)
		&"matsch":
			for i in 6:
				var a := TAU * i / 6.0
				_rotated_rect(ci, c + Vector2.from_angle(a) * radius * 1.02, Vector2(radius * 0.45, radius * 0.25), a, TIRE)
	ci.draw_circle(c, radius, TIRE)
	ci.draw_circle(c, radius * 0.45, hub)
	ci.draw_circle(c, radius * 0.12, INK)


static func _track(ci: CanvasItem, c: Vector2, s: float, hub: Color) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -0.75) * s, c + Vector2(1.0, 0.55) * s, c + Vector2(-1.0, 0.55) * s])
	ci.draw_colored_polygon(pts, TIRE)
	for i in 9:
		var t := float(i) / 8.0
		var p := (c + Vector2(-1.0, 0.55) * s).lerp(c + Vector2(1.0, 0.55) * s, t)
		ci.draw_rect(Rect2(p - Vector2(0.06, 0.0) * s, Vector2(0.12, 0.14) * s), TIRE)
	ci.draw_circle(c + Vector2(0, 0.0) * s, 0.22 * s, hub)


## Kategorie-Symbol „Vorlagen“: drei kleine fertige Crawler übereinander.
static func _presets_stack(ci: CanvasItem, r: Rect2, accent: Color) -> void:
	var sub := r.size * 0.62
	for i in 3:
		var offset := Vector2(-0.14 + i * 0.14, -0.14 + i * 0.14) * r.size.x
		var rect := Rect2(r.get_center() - sub * 0.5 + offset, sub)
		_body_silhouette(ci, [&"jeep", &"kipper", &"pickup"][i], rect.get_center(), rect.size.x / 100.0,
			[accent, Color(0.2, 0.45, 0.9), Color(0.25, 0.7, 0.3)][i])


## Vorlagen-Karte: Aufbau-Silhouette in der Vorlagenfarbe, Radzahl und Ketten sichtbar.
static func draw_preset(ci: CanvasItem, preset: Dictionary, r: Rect2) -> void:
	var color: Color = PartCatalog.part(&"farbe", preset.get("farbe", PartCatalog.default_id(&"farbe"))).farbe
	var body: StringName = preset.get("aufbau", PartCatalog.default_id(&"aufbau"))
	var c := r.get_center() + Vector2(0, -r.size.y * 0.06)
	var u := r.size.x / 100.0
	_body_silhouette(ci, body, c, u, color)
	if preset.get("fahrgestell") == &"sechsrad":
		ci.draw_circle(Vector2(c.x, c.y + 14 * u), 12 * u, TIRE)
	if preset.get("reifen") == &"ketten":
		_track(ci, Vector2(c.x, c.y + 26 * u), 30 * u, color)
	var big: bool = preset.get("raeder") in [&"gross", &"monster"]
	if big:
		ci.draw_line(Vector2(c.x - 40 * u, c.y + 34 * u), Vector2(c.x + 40 * u, c.y + 34 * u), INK, 3 * u)


static func _spring(ci: CanvasItem, c: Vector2, height: float, width: float, coils: int, thickness: float, color: Color) -> void:
	var points := PackedVector2Array()
	var top := c.y - height * 0.5
	points.append(Vector2(c.x, top))
	for i in coils * 2:
		var y := top + height * (i + 0.5) / (coils * 2)
		points.append(Vector2(c.x + (width if i % 2 == 0 else -width) * 0.5, y))
	points.append(Vector2(c.x, top + height))
	ci.draw_polyline(points, color.darkened(0.2), thickness, true)
	ci.draw_line(Vector2(c.x - width * 0.7, top), Vector2(c.x + width * 0.7, top), INK, thickness)
	ci.draw_line(Vector2(c.x - width * 0.7, top + height), Vector2(c.x + width * 0.7, top + height), INK, thickness)


static func _bolt(ci: CanvasItem, c: Vector2, s: float, color: Color) -> void:
	var pts := PackedVector2Array([
		c + Vector2(0.2, -1.0) * s, c + Vector2(-0.45, 0.1) * s, c + Vector2(0.0, 0.1) * s,
		c + Vector2(-0.2, 1.0) * s, c + Vector2(0.45, -0.1) * s, c + Vector2(0.0, -0.1) * s,
	])
	ci.draw_colored_polygon(pts, color)
	pts.append(pts[0])
	ci.draw_polyline(pts, INK, 2.0, true)


static func _steering_wheel(ci: CanvasItem, c: Vector2, radius: float) -> void:
	ci.draw_arc(c, radius, 0, TAU, 48, INK, radius * 0.18, true)
	for a in [PI / 2, PI * 7 / 6, -PI / 6]:
		ci.draw_line(c, c + Vector2.from_angle(a) * radius, INK, radius * 0.14)
	ci.draw_circle(c, radius * 0.22, INK)


const RAINBOW := [
	Color(0.92, 0.12, 0.12), Color(1.0, 0.5, 0.05), Color(1.0, 0.85, 0.05),
	Color(0.12, 0.7, 0.25), Color(0.12, 0.35, 0.95), Color(0.6, 0.22, 0.92),
]


static func _palette(ci: CanvasItem, r: Rect2) -> void:
	var c := r.get_center()
	for i in RAINBOW.size():
		var a := TAU * i / RAINBOW.size() - PI / 2
		ci.draw_circle(c + Vector2.from_angle(a) * r.size.x * 0.22, r.size.x * 0.11, RAINBOW[i])


## Regenbogen-Lack: Tortenstücke in allen Farben (Form: viele Stücke statt einer Fläche).
static func _rainbow(ci: CanvasItem, c: Vector2, radius: float) -> void:
	for i in RAINBOW.size():
		var a0 := TAU * i / RAINBOW.size() - PI / 2
		var a1 := TAU * (i + 1) / RAINBOW.size() - PI / 2
		var pts := PackedVector2Array([c])
		for k in 7:
			pts.append(c + Vector2.from_angle(lerpf(a0, a1, k / 6.0)) * radius)
		ci.draw_colored_polygon(pts, RAINBOW[i])


static func _star(ci: CanvasItem, c: Vector2, radius: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := TAU * i / 10.0 - PI / 2
		pts.append(c + Vector2.from_angle(a) * (radius if i % 2 == 0 else radius * 0.45))
	ci.draw_colored_polygon(pts, color)
	pts.append(pts[0])
	ci.draw_polyline(pts, INK, 2.0, true)


static func _flag(ci: CanvasItem, r: Rect2, color: Color) -> void:
	var c := r.get_center()
	var s := r.size.x / 100.0
	ci.draw_line(c + Vector2(-22, 36) * s, c + Vector2(-22, -36) * s, INK, 6 * s)
	# Zielflagge: Schachbrett
	for y in 3:
		for x in 4:
			var cell := Rect2(c + Vector2(-19 + x * 11, -36 + y * 11) * s, Vector2(11, 11) * s)
			ci.draw_rect(cell, INK if (x + y) % 2 == 0 else Color.WHITE)
	ci.draw_circle(c + Vector2(18, 24) * s, 14 * s, color)
	ci.draw_colored_polygon(PackedVector2Array([
		c + Vector2(13, 16) * s, c + Vector2(26, 24) * s, c + Vector2(13, 32) * s,
	]), Color.WHITE)


static func _dice(ci: CanvasItem, r: Rect2) -> void:
	var c := r.get_center()
	var s := r.size.x * 0.32
	ci.draw_rect(Rect2(c - Vector2(s, s), Vector2(s, s) * 2), Color.WHITE)
	ci.draw_rect(Rect2(c - Vector2(s, s), Vector2(s, s) * 2), INK, false, 3.0)
	for p in [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0, 0), Vector2(-0.5, 0.5), Vector2(0.5, 0.5)]:
		ci.draw_circle(c + p * s, s * 0.16, INK)


static func _wrench(ci: CanvasItem, r: Rect2) -> void:
	var c := r.get_center()
	var s := r.size.x / 100.0
	var a := c + Vector2(-24, 24) * s
	var b := c + Vector2(18, -18) * s
	ci.draw_line(a, b, METAL.darkened(0.3), 12 * s)
	ci.draw_circle(b, 16 * s, METAL.darkened(0.3))
	ci.draw_circle(b + Vector2(7, -7) * s, 8 * s, Color(0.85, 0.85, 0.85))


static func _rotated_rect(ci: CanvasItem, center: Vector2, size: Vector2, angle: float, color: Color) -> void:
	var half := size * 0.5
	var pts := PackedVector2Array()
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		pts.append(center + (corner * half).rotated(angle))
	ci.draw_colored_polygon(pts, color)


static func _body_silhouette(ci: CanvasItem, id: StringName, c: Vector2, u: float, accent: Color) -> void:
	var base_y := c.y + 14 * u
	var wheel_r := 12 * u
	var rear := c.x + 26 * u
	var front := c.x - 26 * u
	match id:
		&"jeep":
			ci.draw_rect(Rect2(c.x - 40 * u, base_y - 22 * u, 80 * u, 16 * u), accent)
			ci.draw_rect(Rect2(c.x - 12 * u, base_y - 40 * u, 38 * u, 20 * u), accent)
			ci.draw_rect(Rect2(c.x - 8 * u, base_y - 36 * u, 14 * u, 12 * u), Color(0.6, 0.8, 0.95))
		&"pickup":
			ci.draw_rect(Rect2(c.x - 42 * u, base_y - 22 * u, 84 * u, 16 * u), accent)
			ci.draw_rect(Rect2(c.x - 26 * u, base_y - 40 * u, 26 * u, 20 * u), accent)
			ci.draw_rect(Rect2(c.x - 22 * u, base_y - 36 * u, 12 * u, 12 * u), Color(0.6, 0.8, 0.95))
			ci.draw_rect(Rect2(c.x + 4 * u, base_y - 30 * u, 38 * u, 4 * u), accent.darkened(0.2))
		&"traktor":
			ci.draw_rect(Rect2(c.x - 40 * u, base_y - 24 * u, 50 * u, 16 * u), accent)
			ci.draw_rect(Rect2(c.x + 4 * u, base_y - 52 * u, 30 * u, 6 * u), accent)
			for x in [6, 32]:
				ci.draw_line(Vector2(c.x + x * u, base_y - 48 * u), Vector2(c.x + x * u, base_y - 12 * u), INK, 3 * u)
			ci.draw_line(Vector2(c.x - 30 * u, base_y - 24 * u), Vector2(c.x - 30 * u, base_y - 42 * u), INK, 4 * u)
			rear = c.x + 22 * u
			ci.draw_circle(Vector2(rear, base_y - 2 * u), wheel_r * 1.7, TIRE)
			ci.draw_circle(Vector2(rear, base_y - 2 * u), wheel_r * 0.7, accent)
			ci.draw_circle(Vector2(front, base_y + 2 * u), wheel_r, TIRE)
			return
		&"buggy":
			ci.draw_rect(Rect2(c.x - 40 * u, base_y - 18 * u, 80 * u, 10 * u), accent)
			var cage := PackedVector2Array([
				Vector2(c.x - 22 * u, base_y - 18 * u), Vector2(c.x - 12 * u, base_y - 46 * u),
				Vector2(c.x + 20 * u, base_y - 46 * u), Vector2(c.x + 28 * u, base_y - 18 * u),
			])
			ci.draw_polyline(cage, METAL.darkened(0.2), 4 * u, true)
		&"kipper":
			ci.draw_rect(Rect2(c.x - 42 * u, base_y - 20 * u, 84 * u, 12 * u), INK)
			ci.draw_rect(Rect2(c.x - 42 * u, base_y - 44 * u, 22 * u, 26 * u), accent)
			ci.draw_rect(Rect2(c.x - 38 * u, base_y - 40 * u, 12 * u, 10 * u), Color(0.6, 0.8, 0.95))
			ci.draw_colored_polygon(PackedVector2Array([
				Vector2(c.x - 14 * u, base_y - 20 * u), Vector2(c.x + 42 * u, base_y - 20 * u),
				Vector2(c.x + 46 * u, base_y - 46 * u), Vector2(c.x - 18 * u, base_y - 40 * u),
			]), METAL)
		&"abschlepper":
			ci.draw_rect(Rect2(c.x - 42 * u, base_y - 20 * u, 84 * u, 12 * u), INK)
			ci.draw_rect(Rect2(c.x - 42 * u, base_y - 44 * u, 22 * u, 26 * u), accent)
			ci.draw_rect(Rect2(c.x - 38 * u, base_y - 40 * u, 12 * u, 10 * u), Color(0.6, 0.8, 0.95))
			ci.draw_line(Vector2(c.x + 4 * u, base_y - 22 * u), Vector2(c.x + 38 * u, base_y - 50 * u), Color(0.95, 0.75, 0.1), 6 * u)
			ci.draw_line(Vector2(c.x + 38 * u, base_y - 50 * u), Vector2(c.x + 38 * u, base_y - 30 * u), INK, 2 * u)
			ci.draw_arc(Vector2(c.x + 34 * u, base_y - 28 * u), 5 * u, -0.3, PI, 10, INK, 3 * u)
		&"bagger":
			# Ketten-Unterwagen, Oberwagen mit Kabine, geknickter Arm mit Löffel
			ci.draw_rect(Rect2(c.x - 34 * u, base_y - 6 * u, 60 * u, 14 * u), TIRE)
			ci.draw_rect(Rect2(c.x - 30 * u, base_y - 26 * u, 46 * u, 20 * u), accent)
			ci.draw_rect(Rect2(c.x - 26 * u, base_y - 44 * u, 18 * u, 18 * u), accent)
			ci.draw_rect(Rect2(c.x - 23 * u, base_y - 41 * u, 12 * u, 9 * u), Color(0.6, 0.8, 0.95))
			ci.draw_line(Vector2(c.x + 10 * u, base_y - 24 * u), Vector2(c.x + 34 * u, base_y - 50 * u), accent.darkened(0.15), 7 * u)
			ci.draw_line(Vector2(c.x + 34 * u, base_y - 50 * u), Vector2(c.x + 44 * u, base_y - 18 * u), accent.darkened(0.15), 6 * u)
			ci.draw_colored_polygon(PackedVector2Array([
				Vector2(c.x + 38 * u, base_y - 20 * u), Vector2(c.x + 50 * u, base_y - 16 * u), Vector2(c.x + 44 * u, base_y - 4 * u),
			]), METAL)
			return
		&"radlader":
			ci.draw_rect(Rect2(c.x - 30 * u, base_y - 22 * u, 52 * u, 16 * u), accent)
			ci.draw_rect(Rect2(c.x - 26 * u, base_y - 46 * u, 22 * u, 24 * u), accent)
			ci.draw_rect(Rect2(c.x - 22 * u, base_y - 42 * u, 14 * u, 12 * u), Color(0.6, 0.8, 0.95))
			ci.draw_line(Vector2(c.x + 4 * u, base_y - 26 * u), Vector2(c.x + 34 * u, base_y - 18 * u), INK, 4 * u)
			ci.draw_colored_polygon(PackedVector2Array([
				Vector2(c.x + 30 * u, base_y - 28 * u), Vector2(c.x + 48 * u, base_y - 26 * u),
				Vector2(c.x + 48 * u, base_y + 4 * u), Vector2(c.x + 34 * u, base_y + 4 * u),
			]), METAL)
		&"feuerwehr":
			ci.draw_rect(Rect2(c.x - 44 * u, base_y - 40 * u, 88 * u, 32 * u), accent)
			ci.draw_rect(Rect2(c.x - 40 * u, base_y - 34 * u, 14 * u, 12 * u), Color(0.6, 0.8, 0.95))
			ci.draw_line(Vector2(c.x - 20 * u, base_y - 46 * u), Vector2(c.x + 44 * u, base_y - 46 * u), METAL, 3 * u)
			for i in 7:
				var x := c.x + (-16 + i * 9) * u
				ci.draw_line(Vector2(x, base_y - 49 * u), Vector2(x, base_y - 43 * u), METAL, 2 * u)
			ci.draw_rect(Rect2(c.x - 38 * u, base_y - 48 * u, 10 * u, 6 * u), Color(0.2, 0.4, 1.0))
	for x in [front, rear]:
		ci.draw_circle(Vector2(x, base_y), wheel_r, TIRE)
		ci.draw_circle(Vector2(x, base_y), wheel_r * 0.45, accent.darkened(0.2))


static func _extra(ci: CanvasItem, id: StringName, c: Vector2, u: float, accent: Color) -> void:
	match id:
		&"licht":
			ci.draw_circle(c + Vector2(-6, 0) * u, 16 * u, Color(1.0, 0.92, 0.4))
			for a in [-0.5, -0.25, 0.0, 0.25, 0.5]:
				var dir := Vector2.from_angle(a)
				ci.draw_line(c + Vector2(14, 0) * u + dir * 6 * u, c + Vector2(14, 0) * u + dir * 30 * u, Color(0.95, 0.75, 0.1), 4 * u)
		&"rammschutz":
			ci.draw_rect(Rect2(c - Vector2(34, 20) * u, Vector2(68, 40) * u), INK, false, 6 * u)
			for x in [-12, 12]:
				ci.draw_line(c + Vector2(x, -20) * u, c + Vector2(x, 20) * u, INK, 5 * u)
			ci.draw_line(c + Vector2(-34, 0) * u, c + Vector2(34, 0) * u, INK, 5 * u)
		&"seilwinde":
			ci.draw_rect(Rect2(c - Vector2(30, 14) * u, Vector2(36, 28) * u), METAL)
			for x in [-24, -14, -4]:
				ci.draw_line(c + Vector2(x, -14) * u, c + Vector2(x, 14) * u, INK, 2 * u)
			ci.draw_line(c + Vector2(6, 0) * u, c + Vector2(30, 0) * u, INK, 3 * u)
			ci.draw_arc(c + Vector2(30, 8) * u, 8 * u, -PI / 2, PI, 12, INK, 3 * u)
		&"dachtraeger":
			ci.draw_rect(Rect2(c + Vector2(-30, 0) * u, Vector2(60, 26) * u), accent)
			ci.draw_line(c + Vector2(-34, -10) * u, c + Vector2(34, -10) * u, INK, 4 * u)
			for x in [-26, -9, 9, 26]:
				ci.draw_line(c + Vector2(x, -10) * u, c + Vector2(x, 0) * u, INK, 3 * u)
			ci.draw_rect(Rect2(c + Vector2(-20, -24) * u, Vector2(26, 14) * u), Color(0.55, 0.35, 0.2))
		&"fahne":
			ci.draw_line(c + Vector2(-20, 36) * u, c + Vector2(-20, -36) * u, INK, 5 * u)
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(-18, -34) * u, c + Vector2(28, -22) * u, c + Vector2(-18, -6) * u,
			]), accent.inverted())
		&"auspuff":
			for x in [-12, 12]:
				ci.draw_rect(Rect2(c + Vector2(x - 5, -10) * u, Vector2(10, 44) * u), METAL)
			for i in 3:
				ci.draw_circle(c + Vector2(-4 + i * 8, -18 - i * 10) * u, (5 + i * 2) * u, Color(0.7, 0.7, 0.7, 0.8))
