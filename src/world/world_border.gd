class_name WorldBorder
extends StaticBody3D
## Rand der Spielwelt: ein bunter Zaun und dahinter eine unsichtbare Wand, damit niemand über den
## Rand des Geländes ins Leere fährt (Kinder-Regel „kein Scheitern“). Fährt ein Crawler trotzdem
## einmal hinaus oder fällt durch, holt `is_lost` ihn zurück an den Start (siehe terrain_spike.gd).

const INSET := 3.0  # Abstand des Zauns vom Geländerand (m)
const WALL_THICKNESS := 4.0
const WALL_HEIGHT := 80.0
const POST_SPACING := 3.0
const POST_HEIGHT := 1.4
## Fröhliche Zaunfarben, reihum. Die Pfosten unterscheiden sich zusätzlich durch die Kugel oben.
const POST_COLORS := [
	Color(0.95, 0.25, 0.25), Color(1.0, 0.6, 0.1), Color(1.0, 0.88, 0.15),
	Color(0.3, 0.8, 0.3), Color(0.25, 0.6, 1.0), Color(0.65, 0.35, 0.9),
]


func _init() -> void:
	name = "Weltrand"


func _ready() -> void:
	var size := float(SpikeTerrain.REGION_SIZE)
	var lo := INSET - WALL_THICKNESS * 0.5
	var hi := size - INSET + WALL_THICKNESS * 0.5
	var mid := size * 0.5
	_wall(Vector3(lo, WALL_HEIGHT * 0.3, mid), Vector3(WALL_THICKNESS, WALL_HEIGHT, size))
	_wall(Vector3(hi, WALL_HEIGHT * 0.3, mid), Vector3(WALL_THICKNESS, WALL_HEIGHT, size))
	_wall(Vector3(mid, WALL_HEIGHT * 0.3, lo), Vector3(size, WALL_HEIGHT, WALL_THICKNESS))
	_wall(Vector3(mid, WALL_HEIGHT * 0.3, hi), Vector3(size, WALL_HEIGHT, WALL_THICKNESS))
	add_child(_fence())


## Außerhalb des Zauns oder deutlich unter dem Boden = verloren; dann zurück an den Start.
static func is_lost(pos: Vector3) -> bool:
	var size := float(SpikeTerrain.REGION_SIZE)
	if pos.x < 0.0 or pos.z < 0.0 or pos.x > size or pos.z > size:
		return true
	return pos.y < SpikeTerrain.height_at(pos.x, pos.z) - 6.0


func _wall(center: Vector3, wall_size: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = wall_size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = center
	add_child(collision)


## Pfosten mit Kugel entlang aller vier Seiten, als MultiMesh (ein Draw-Call je Teil).
func _fence() -> Node3D:
	var size := float(SpikeTerrain.REGION_SIZE)
	var points: Array[Vector3] = []
	var steps := int((size - 2.0 * INSET) / POST_SPACING)
	for i in steps + 1:
		var t := INSET + i * POST_SPACING
		for p in [Vector2(t, INSET), Vector2(t, size - INSET), Vector2(INSET, t), Vector2(size - INSET, t)]:
			points.append(Vector3(p.x, SpikeTerrain.height_at(p.x, p.y), p.y))

	var post := CylinderMesh.new()
	post.top_radius = 0.12
	post.bottom_radius = 0.14
	post.height = POST_HEIGHT
	post.radial_segments = 8
	var ball := SphereMesh.new()
	ball.radius = 0.25
	ball.height = 0.5
	ball.radial_segments = 10
	ball.rings = 6

	var fence := Node3D.new()
	fence.name = "Zaun"
	fence.add_child(_multi(post, points, Vector3(0, POST_HEIGHT * 0.5, 0)))
	fence.add_child(_multi(ball, points, Vector3(0, POST_HEIGHT + 0.15, 0)))
	return fence


func _multi(mesh: Mesh, points: Array[Vector3], offset: Vector3) -> MultiMeshInstance3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.6
	mesh.surface_set_material(0, material)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = points.size()
	for i in points.size():
		mm.set_instance_transform(i, Transform3D(Basis(), points[i] + offset))
		mm.set_instance_color(i, POST_COLORS[int(i / 4.0) % POST_COLORS.size()])
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	return node
