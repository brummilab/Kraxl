class_name Playground
extends Node3D
## Bunte Spielwelt um die Startwiese (ADR 0012): Blumen (nur Optik, ohne Kollision) und bunte Kegel
## und Kisten aus dem Kenney Car Kit, die man umschubsen kann. Alles mit festem Zufallsstartwert,
## damit die Welt bei jedem Start gleich aussieht und die FPS-Messrunde vergleichbar bleibt.

const C := preload("res://src/vehicle/vehicle_constants.gd")
const SEED := 4711
const FLOWER_COUNT := 1800
const FLOWER_RADIUS := 70.0  # m um die Mitte
const START_CLEARANCE := 9.0  # m freier Platz am Start
const FLOWER_COLORS := [
	Color(1.0, 0.25, 0.3), Color(1.0, 0.85, 0.1), Color(1.0, 1.0, 1.0),
	Color(0.7, 0.35, 1.0), Color(1.0, 0.5, 0.8), Color(0.3, 0.65, 1.0),
]
const TOY_COLORS := [
	Color(1.0, 0.5, 0.05), Color(0.92, 0.12, 0.12), Color(1.0, 0.85, 0.05),
	Color(0.12, 0.7, 0.25), Color(0.12, 0.35, 0.95), Color(0.6, 0.22, 0.92),
]
const CONE_SCALE := 1.6
const BOX_SCALE := 1.2


func _init() -> void:
	name = "Spielwelt"


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	add_child(_flowers(rng))
	# Ein Kegel-Slalom vor dem Start und ein Kistenturm daneben.
	for i in 6:
		_toy("cone", Vector3(128.0 - 7.5 + i * 3.0, 0, 128.0 - 14.0), TOY_COLORS[i], rng)
	for i in 3:
		for k in 3 - i:
			_toy("box", Vector3(120.0 + k * 0.9 + i * 0.45, i * BOX_SCALE * 0.715, 116.0), TOY_COLORS[(i + k * 2) % TOY_COLORS.size()], rng)
	for i in 10:
		var a := TAU * i / 10.0
		_toy("cone", Vector3(128.0 + cos(a) * 26.0, 0, 128.0 + sin(a) * 26.0), TOY_COLORS[i % TOY_COLORS.size()], rng)


## Blumen als MultiMesh: flache Kugel auf dem Boden, nur auf flacher Wiese, nicht am Start.
func _flowers(rng: RandomNumberGenerator) -> MultiMeshInstance3D:
	var blossom := SphereMesh.new()
	blossom.radius = 0.14
	blossom.height = 0.14
	blossom.radial_segments = 6
	blossom.rings = 3
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.8
	blossom.material = material
	var points: Array[Transform3D] = []
	var colors: Array[Color] = []
	while points.size() < FLOWER_COUNT:
		var p := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * FLOWER_RADIUS
		if p.length() > FLOWER_RADIUS or p.length() < START_CLEARANCE:
			continue
		var x := 128.0 + p.x
		var z := 128.0 + p.y
		if x > SpikeTerrain.SLOPE_START_X - 2.0:
			continue
		var y := SpikeTerrain.height_at(x, z)
		var s := rng.randf_range(0.7, 1.3)
		points.append(Transform3D(Basis.from_scale(Vector3(s, s, s)), Vector3(x, y + 0.08, z)))
		colors.append(FLOWER_COLORS[rng.randi() % FLOWER_COLORS.size()])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = blossom
	mm.instance_count = points.size()
	for i in points.size():
		mm.set_instance_transform(i, points[i])
		mm.set_instance_color(i, colors[i])
	var node := MultiMeshInstance3D.new()
	node.name = "Blumen"
	node.multimesh = mm
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


## Umschubsbares Spielzeug; `pos.y` ist die Höhe über dem Boden.
func _toy(model: String, pos: Vector3, color: Color, rng: RandomNumberGenerator) -> RigidBody3D:
	var cone := model == "cone"
	var scale_f := CONE_SCALE if cone else BOX_SCALE
	var body := RigidBody3D.new()
	body.name = "Kegel" if cone else "Kiste"
	body.mass = C.TOY_CONE_MASS if cone else C.TOY_BOX_MASS
	body.physics_material_override = PhysicsMaterial.new()
	body.physics_material_override.friction = C.TOY_FRICTION
	body.position = pos + Vector3(0, SpikeTerrain.height_at(pos.x, pos.z) + 0.02, 0)
	body.rotation.y = rng.randf_range(-0.3, 0.3)
	var shape: Shape3D
	if cone:
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.2 * scale_f
		cyl.height = 0.595 * scale_f
		shape = cyl
	else:
		var box := BoxShape3D.new()
		box.size = Vector3.ONE * 0.715 * scale_f
		shape = box
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = (0.595 if cone else 0.715) * scale_f * 0.5
	body.add_child(collision)
	var scene := KenneyModels.instantiate(model)
	var mesh: MeshInstance3D = scene.get_node(model)
	scene.remove_child(mesh)
	mesh.owner = null
	scene.free()
	mesh.scale = Vector3.ONE * scale_f
	mesh.material_override = KenneyModels.paint_material(mesh.mesh, color)
	body.add_child(mesh)
	add_child(body)
	return body
