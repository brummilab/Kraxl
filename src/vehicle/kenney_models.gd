class_name KenneyModels
## Kenney Car Kit (CC0, assets/models/kenney) als Optik für Karosserien und Räder.
## Die Physik bleibt beim Bauplan (VehicleSpec); die Modelle werden nur auf unsere Achsen
## ausgerichtet und skaliert. Lackfarbe: Die Modelle nutzen eine gemeinsame Farbpalette
## (8 × 4 Kacheln mit Verlauf). Ein Shader färbt die vorherrschende bunte Kachel jedes Modells
## in der gewählten Farbe ein und behält die Schattierung. Die dunkelgrauen Zierteile (Stoßstangen,
## Schweller) bekommen eine dunklere Variante des Lacks, die Felgen der Räder den Lack selbst –
## so wirken die Fahrzeuge kräftig bunt statt grau (ADR 0012). Regenbogen-Lack siehe Paint.

const DIR := "res://assets/models/kenney/"
const COLORMAP := "res://assets/models/kenney/Textures/colormap.png"

## Aufbau -> Kenney-Karosserie. Nicht genannte Aufbauten (buggy, bagger) werden gezeichnet.
const BODIES := {
	&"jeep": "suv",
	&"pickup": "truck",
	&"traktor": "tractor",
	&"kipper": "truck-flat",
	&"feuerwehr": "firetruck",
	&"abschlepper": "truck-flat",
	&"radlader": "tractor-shovel",
}
## Reifen -> Kenney-Rad (Ketten werden gezeichnet).
const WHEELS := {
	&"stollen": "wheel-truck",
	&"glatt": "wheel-default",
	&"matsch": "wheel-tractor-back",
}
const GRID := Vector2(8, 4)
## Dunkelgraue Kachel der Zierteile an Karosserien und helle Felgen-Kachel der Räder.
const TRIM_TILE := Vector2i(3, 2)
const RIM_TILE := Vector2i(6, 2)
const TRIM_DARKEN := 0.45
## Bunte Palettenkacheln (Spalte, Zeile), die als Lack infrage kommen. Glas, Grau, Weiß, Schwarz
## und Hauttöne bleiben unverändert.
const PAINTABLE := [
	Vector2i(1, 0), Vector2i(2, 0),
	Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1),
	Vector2i(7, 2),
	Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3),
]
const PAINT_SHADER := "shader_type spatial;\n" + """
uniform sampler2D colormap : source_color, filter_linear_mipmap;
uniform vec3 paint : source_color = vec3(1.0, 0.5, 0.1);
uniform vec3 trim : source_color = vec3(0.5, 0.25, 0.05);
uniform vec2 tile = vec2(-1.0);
uniform vec2 trim_tile = vec2(-1.0);
uniform float tile_luminance = 0.5;
uniform float trim_luminance = 0.5;
uniform bool rainbow = false;
""" + Paint.RAINBOW_GLSL + Paint.WORLD_POS_VERTEX + """
void fragment() {
	vec3 c = texture(colormap, UV).rgb;
	vec2 t = floor(UV * vec2(8.0, 4.0));
	vec3 p = rainbow ? rainbow_at(world_pos) : paint;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	if (t == tile) {
		c = p * clamp(l / max(tile_luminance, 0.05), 0.5, 1.5);
	} else if (t == trim_tile) {
		c = (rainbow ? p * 0.55 : trim) * clamp(l / max(trim_luminance, 0.05), 0.5, 1.5);
	}
	ALBEDO = c;
	ROUGHNESS = 0.7;
}
"""

static var _scenes := {}
static var _tiles := {}
static var _shader: Shader
static var _colormap: Texture2D
static var _colormap_image: Image


static func has_body(body: StringName) -> bool:
	return BODIES.has(body)


static func has_wheel(tire: StringName) -> bool:
	return WHEELS.has(tire)


## Neue Instanz eines Modells (Wurzel-Node mit Karosserie und Rädern als Kinder).
static func instantiate(model: String) -> Node3D:
	if not _scenes.has(model):
		_scenes[model] = load(DIR + model + ".glb")
	return _scenes[model].instantiate()


## Material, das die vorherrschende bunte Kachel von `mesh` in `color` umfärbt (bei Rädern die
## Felge). Karosserien bekommen zusätzlich farbige Zierteile.
static func paint_material(mesh: Mesh, color: Color, rainbow := false, wheel := false) -> ShaderMaterial:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = PAINT_SHADER
		_colormap = load(COLORMAP)
		_colormap_image = _colormap.get_image()
		if _colormap_image.is_compressed():
			_colormap_image.decompress()
	var tile := RIM_TILE if wheel else dominant_tile(mesh)
	var trim_tile := Vector2i(-1, -1) if wheel else TRIM_TILE
	var material := ShaderMaterial.new()
	material.shader = _shader
	material.set_shader_parameter("colormap", _colormap)
	material.set_shader_parameter("paint", color)
	material.set_shader_parameter("trim", color.darkened(TRIM_DARKEN))
	material.set_shader_parameter("rainbow", rainbow)
	material.set_shader_parameter("tile", Vector2(tile) if tile.x >= 0 else Vector2(-1, -1))
	material.set_shader_parameter("tile_luminance", _tile_luminance(tile))
	material.set_shader_parameter("trim_tile", Vector2(trim_tile))
	material.set_shader_parameter("trim_luminance", _tile_luminance(trim_tile))
	return material


## Bunte Kachel mit der größten Fläche im Mesh (über die UV-Mittelpunkte der Dreiecke).
static func dominant_tile(mesh: Mesh) -> Vector2i:
	var key := mesh.get_rid().get_id()
	if _tiles.has(key):
		return _tiles[key]
	var area := {}
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if uvs.is_empty():
			continue
		var count := indices.size() if not indices.is_empty() else vertices.size()
		for i in range(0, count - 2, 3):
			var a := indices[i] if not indices.is_empty() else i
			var b := indices[i + 1] if not indices.is_empty() else i + 1
			var c := indices[i + 2] if not indices.is_empty() else i + 2
			var uv := (uvs[a] + uvs[b] + uvs[c]) / 3.0
			var tile := Vector2i(floori(uv.x * GRID.x), floori(uv.y * GRID.y))
			if tile in PAINTABLE:
				var size := (vertices[b] - vertices[a]).cross(vertices[c] - vertices[a]).length()
				area[tile] = area.get(tile, 0.0) + size
	var best := Vector2i(-1, -1)
	for tile in area:
		if best.x < 0 or area[tile] > area[best]:
			best = tile
	_tiles[key] = best
	return best


static func _tile_luminance(tile: Vector2i) -> float:
	if tile.x < 0 or _colormap_image == null:
		return 0.5
	var w := _colormap_image.get_width() / GRID.x
	var h := _colormap_image.get_height() / GRID.y
	var total := 0.0
	var samples := 0
	for y in range(4, int(h) - 4, 8):
		for x in range(4, int(w) - 4, 8):
			var c := _colormap_image.get_pixel(int(tile.x * w) + x, int(tile.y * h) + y)
			total += c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			samples += 1
	return total / maxi(samples, 1)


## Kenney-Rad als Mesh plus Radius/Breite des Originals (zum Skalieren auf unsere Maße).
static func wheel_mesh(tire: StringName) -> Dictionary:
	var root := instantiate(WHEELS[tire])
	var mesh_node: MeshInstance3D = _first_mesh(root)
	var aabb := mesh_node.get_aabb()
	var info := {"mesh": mesh_node.mesh, "radius": aabb.size.y * 0.5, "width": aabb.size.x}
	root.free()
	return info


static func _first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := _first_mesh(child)
		if found:
			return found
	return null
