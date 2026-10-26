class_name Digging
extends Node
## Graben mit dem Bagger (ADR 0013). Erreicht der Arm unten den Boden, gräbt ein leerer Löffel eine
## Mulde ins Terrain3D und ist danach voll (Erde sichtbar); ein voller Löffel kippt beim nächsten
## Absenken einen Haufen aus. Gegrabene Stellen werden erdbraun. Danach wird die Kollision neu
## aufgebaut (einmal pro Löffel, ca. 17 ms am PC), damit Crawler in die Mulde fahren können.
## Grenzen (DIG_MAX_DEPTH, PILE_MAX_HEIGHT) halten alles befahrbar: kein Crawler bleibt stecken.

const C := preload("res://src/vehicle/vehicle_constants.gd")
const EARTH_TEXTURE := 0  # Terrain3D-Textur „Erde“ (SpikeTerrain)

var terrain: Terrain3D
## Fahrzeuge, die graben dürfen (nur mit Bagger-Werkzeug wirksam).
var vehicles: Array = []
## Gesamtzahl der Löffel (für Tests).
var scoops := 0
var dumps := 0

var _was_down := {}  # Fahrzeug -> Werkzeug war beim letzten Tick unten


func _init(target: Terrain3D) -> void:
	terrain = target
	name = "Graben"


func _physics_process(_delta: float) -> void:
	for v in vehicles:
		if not is_instance_valid(v) or v.tool_kind() != &"bagger":
			continue
		var down: bool = v.tool_amount() >= C.DIG_TRIGGER
		if down and not _was_down.get(v, false):
			_bottom_reached(v)
		_was_down[v] = down


## Arm ist unten angekommen: leer = graben, voll = auskippen.
func _bottom_reached(v) -> void:
	var tip: Vector3 = v.tool_tip()
	var ground := terrain.data.get_height(tip)
	if is_nan(ground) or tip.y > ground + C.DIG_REACH:
		return  # Löffel hängt in der Luft (z. B. über einer Kante)
	if v.bucket_full:
		reshape(tip, C.PILE_HEIGHT)
		dumps += 1
		v.set_bucket_full(false)
	else:
		reshape(tip, -C.DIG_DEPTH)
		scoops += 1
		v.set_bucket_full(true)


## Hebt (amount > 0) oder senkt (amount < 0) den Boden als weiche Kuppe bzw. Mulde um `center`.
func reshape(center: Vector3, amount: float) -> void:
	var r := C.DIG_RADIUS
	var steps := int(ceil(r))
	for dx in range(-steps, steps + 1):
		for dz in range(-steps, steps + 1):
			var p := Vector3(round(center.x) + dx, 0, round(center.z) + dz)
			var d := Vector2(p.x - center.x, p.z - center.z).length()
			if d > r:
				continue
			var h := terrain.data.get_height(p)
			if is_nan(h):
				continue
			var original := SpikeTerrain.height_at(p.x, p.z)
			var falloff := 1.0 - (d / r) * (d / r)
			var target := h + amount * falloff
			target = clampf(target, original - C.DIG_MAX_DEPTH, original + C.PILE_MAX_HEIGHT)
			terrain.data.set_height(p, target)
			terrain.data.set_control_auto(p, false)
			terrain.data.set_control_base_id(p, EARTH_TEXTURE)
	terrain.data.update_maps(Terrain3DRegion.TYPE_HEIGHT, true, false)
	terrain.data.update_maps(Terrain3DRegion.TYPE_CONTROL, true, false)
	terrain.data.calc_height_range(true)
	terrain.collision.update()
