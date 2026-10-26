class_name CrawlerVisuals
## Baut das Aussehen eines Crawlers aus einfachen Grundformen (Platzhalter, bis Blender-Modelle
## nach M7 kommen). Nur Optik und Lichter; Kollision und Physik kommen aus VehicleSpec.

const DARK := Color(0.18, 0.18, 0.2)
const GLASS := Color(0.35, 0.55, 0.7)
const CHROME := Color(0.75, 0.75, 0.78)
const LAMP := Color(1.0, 0.95, 0.6)
const DIRT := Color(0.45, 0.3, 0.17)


## Baut die Optik und liefert, was das Fahrzeug später bewegen oder schalten muss:
## {"lights": [SpotLight3D], "lamps": [StandardMaterial3D], "tool": {"kind": &"bagger"|&"radlader", ...},
##  "exhausts": [Transform3D]} – Auspufföffnungen, -Z zeigt in Austrittsrichtung (für den Rauch).
static func build(root: Node3D, spec: VehicleSpec, design: CrawlerDesign) -> Dictionary:
	var parts := {"lights": [], "lamps": [], "tool": {}, "exhausts": []}
	var paint := Paint.solid(spec.color, spec.rainbow)
	var dark := _material(DARK)
	var b := spec.body_size
	var top := b.y * 0.5
	var front := -b.z * 0.5
	var cab := spec.cab_size
	var cab_pos := Vector3(0, top + cab.y * 0.5, spec.cab_z)
	var roof_y := top + cab.y
	var body: StringName = design.choices[&"aufbau"]
	var back := b.z * 0.5

	if KenneyModels.has_body(body):
		var fit := _kenney_body(root, spec, KenneyModels.BODIES[body], parts)
		top = fit.deck
		roof_y = fit.roof
		front = fit.front
		back = fit.back
		match body:
			&"kipper":
				_dump_box(root, b, fit, _material(CHROME))
			&"abschlepper":
				_crane(root, fit, dark)
	else:
		# Gezeichnetes Fahrgestell: dunkler Rahmen mit farbigem Unterteil.
		_box(root, Vector3(b.x * 0.9, b.y * 0.5, b.z), Vector3(0, -b.y * 0.25, 0), dark)
		_box(root, Vector3(b.x, b.y * 0.5, b.z * 0.96), Vector3(0, b.y * 0.25, 0), paint)
		match body:
			&"buggy":
				_buggy_cage(root, cab, cab_pos, top, spec.cab_z, dark)
			&"bagger":
				parts.tool = _excavator(root, spec, top, paint, dark)
			_:
				_box(root, cab, cab_pos, paint)
				_box(root, Vector3(cab.x * 0.9, cab.y * 0.5, 0.05), cab_pos + Vector3(0, cab.y * 0.1, -cab.z * 0.5), _material(GLASS))

	for id in design.selected_extras():
		match id:
			&"licht":
				for x in [-0.45, 0.45]:
					var lamp_pos := Vector3(x * b.x, top - 0.05, front - 0.02)
					var lamp := _emissive(LAMP)
					parts.lamps.append(lamp)
					_box(root, Vector3(0.2, 0.15, 0.06), lamp_pos, lamp)
					var light := SpotLight3D.new()
					parts.lights.append(light)
					light.position = lamp_pos + Vector3(0, 0, -0.1)
					light.spot_range = 18.0
					light.spot_angle = 35.0
					light.light_energy = 2.0
					light.light_color = LAMP
					root.add_child(light)
			&"rammschutz":
				_box(root, Vector3(b.x * 1.05, 0.08, 0.08), Vector3(0, 0.0, front - 0.2), dark)
				_box(root, Vector3(b.x * 0.8, 0.08, 0.08), Vector3(0, 0.25, front - 0.2), dark)
				for x in [-0.35, 0.35]:
					_box(root, Vector3(0.08, 0.35, 0.08), Vector3(x * b.x, 0.12, front - 0.2), dark)
			&"seilwinde":
				_cylinder(root, 0.1, b.x * 0.5, Vector3(0, -0.05, front - 0.12), Vector3(0, 0, PI / 2), _material(CHROME))
				_box(root, Vector3(0.08, 0.08, 0.15), Vector3(0, -0.05, front - 0.25), dark)
			&"dachtraeger":
				for x in [-0.4, 0.4]:
					_box(root, Vector3(0.05, 0.05, cab.z * 0.95), Vector3(x * cab.x, roof_y + 0.1, spec.cab_z), dark)
				for z in [-0.35, 0.0, 0.35]:
					_box(root, Vector3(cab.x * 0.85, 0.05, 0.05), Vector3(0, roof_y + 0.1, spec.cab_z + z * cab.z), dark)
			&"fahne":
				var pole := Vector3(-b.x * 0.4, top + 0.75, b.z * 0.45)
				_cylinder(root, 0.025, 1.5, pole, Vector3.ZERO, _material(CHROME))
				_box(root, Vector3(0.02, 0.3, 0.45), pole + Vector3(0, 0.55, 0.23), _material(spec.color.inverted()))
			&"auspuff":
				for x in [-0.35, 0.35]:
					var z := spec.cab_z + cab.z * 0.5 + 0.08
					_cylinder(root, 0.06, 0.8, Vector3(x * cab.x, top + 0.4, z), Vector3.ZERO, _material(CHROME))
					parts.exhausts.append(Transform3D(Basis.looking_at(Vector3.UP, Vector3.BACK), Vector3(x * cab.x, top + 0.82, z)))
	if parts.exhausts.is_empty():
		# Ohne Auspuff-Extra: kurzes Endrohr hinten rechts, Rauch nach hinten und leicht nach oben.
		var pipe := Vector3(b.x * 0.3, -b.y * 0.15, back + 0.05)
		_cylinder(root, 0.04, 0.2, pipe, Vector3(PI / 2, 0, 0), dark)
		parts.exhausts.append(Transform3D(Basis.looking_at(Vector3(0, 0.4, 1)), pipe + Vector3(0, 0, 0.1)))
	return parts


## Setzt eine Kenney-Karosserie so auf unser Fahrgestell, dass ihre Radkästen über unseren Rädern
## in Ruhelage sitzen (Kenney blickt nach +Z, wir nach -Z). Die Kenney-Räder entfallen, unsere
## eigenen Räder drehen sich. Liefert Deck-, Dach- und Fronthöhe für Aufbauten und Extras.
static func _kenney_body(root: Node3D, spec: VehicleSpec, model: String, parts: Dictionary) -> Dictionary:
	var scene := KenneyModels.instantiate(model)
	var wheels := []
	for child in scene.get_children():
		if String(child.name).begins_with("wheel"):
			wheels.append(child)
	var kenney_front := -INF
	var kenney_back := INF
	var kenney_x := 0.0
	var kenney_y := 0.0
	for w: MeshInstance3D in wheels:
		var center := w.position + w.get_aabb().get_center()
		kenney_front = maxf(kenney_front, center.z)
		kenney_back = minf(kenney_back, center.z)
		kenney_x = maxf(kenney_x, absf(center.x))
		kenney_y += w.position.y / wheels.size()

	var our_front := INF
	var our_back := -INF
	var our_x := 0.0
	for m in spec.wheel_mounts:
		our_front = minf(our_front, m.z)
		our_back = maxf(our_back, m.z)
		our_x = maxf(our_x, absf(m.x))
	var sag := spec.mass / spec.wheel_mounts.size() * 9.81 / spec.spring
	var wheel_y: float = spec.wheel_mounts[0].y - (spec.travel - sag)

	var sz := (our_back - our_front) / maxf(kenney_front - kenney_back, 0.1)
	var sx := our_x / maxf(kenney_x, 0.1)
	var sy := (sz + sx) * 0.5
	var holder := Node3D.new()
	holder.name = "KenneyBody"
	holder.basis = Basis(Vector3.UP, PI) * Basis.from_scale(Vector3(sx, sy, sz))
	holder.position = Vector3(0, wheel_y - kenney_y * sy, (our_front + our_back) * 0.5 + (kenney_front + kenney_back) * 0.5 * sz)
	root.add_child(holder)
	for w in wheels:
		w.free()
	var body: MeshInstance3D = scene.get_node("body")
	scene.remove_child(body)
	body.owner = null
	holder.add_child(body)
	scene.free()
	_paint_recursive(body, spec.color, spec.rainbow)

	var aabb := body.get_aabb()
	var bottom := holder.position.y + (body.position.y + aabb.position.y) * sy
	var height := aabb.size.y * sy
	var fit := {
		"deck": bottom + height * 0.45,
		"roof": bottom + height,
		"front": holder.position.z - (body.position.z + aabb.end.z) * sz,
		"back": holder.position.z - (body.position.z + aabb.position.z) * sz,
		"width": aabb.size.x * sx,
	}
	if body.has_node("shovel"):
		var shovel: Node3D = body.get_node("shovel")
		parts.tool = {"kind": &"radlader", "shovel": shovel, "rest": shovel.transform}
	return fit


static func _paint_recursive(node: Node, color: Color, rainbow: bool) -> void:
	if node is MeshInstance3D:
		node.material_override = KenneyModels.paint_material(node.mesh, color, rainbow)
	for child in node.get_children():
		_paint_recursive(child, color, rainbow)


static func _dump_box(root: Node3D, b: Vector3, fit: Dictionary, metal: Material) -> void:
	var length: float = (fit.back - fit.front) * 0.5
	var z: float = fit.back - length * 0.5 - 0.05
	var y: float = fit.deck + 0.05
	_box(root, Vector3(fit.width * 0.95, 0.08, length), Vector3(0, y, z), metal)
	for side in [-1, 1]:
		_box(root, Vector3(0.06, 0.45, length), Vector3(side * fit.width * 0.45, y + 0.25, z), metal)
	_box(root, Vector3(fit.width * 0.95, 0.45, 0.06), Vector3(0, y + 0.25, z - length * 0.5), metal)


static func _crane(root: Node3D, fit: Dictionary, dark: Material) -> void:
	var base := Vector3(0, fit.deck + 0.2, fit.back - 0.6)
	_box(root, Vector3(0.25, 0.3, 0.25), base, dark)
	var boom := MeshInstance3D.new()
	var boom_mesh := BoxMesh.new()
	boom_mesh.size = Vector3(0.14, 0.14, 1.3)
	boom_mesh.material = _material(Color(0.95, 0.75, 0.1))
	boom.mesh = boom_mesh
	boom.position = base + Vector3(0, 0.3, 0.45)
	boom.rotation.x = 0.55
	root.add_child(boom)
	var tip := base + Vector3(0, 0.6, 1.0)
	_box(root, Vector3(0.02, 0.5, 0.02), tip + Vector3(0, -0.25, 0), dark)
	_box(root, Vector3(0.12, 0.12, 0.05), tip + Vector3(0, -0.55, 0), _material(CHROME))


static func _buggy_cage(root: Node3D, cab: Vector3, cab_pos: Vector3, top: float, cab_z: float, dark: Material) -> void:
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var p := Vector3(corner.x * cab.x * 0.45, cab_pos.y, cab_z + corner.y * cab.z * 0.45)
		_box(root, Vector3(0.06, cab.y, 0.06), p, _material(CHROME))
	for x in [-1, 1]:
		_box(root, Vector3(0.06, 0.06, cab.z), Vector3(x * cab.x * 0.45, top + cab.y, cab_z), _material(CHROME))
	for z in [-1, 1]:
		_box(root, Vector3(cab.x, 0.06, 0.06), Vector3(0, top + cab.y, cab_z + z * cab.z * 0.45), _material(CHROME))
	_box(root, Vector3(0.5, 0.35, 0.4), Vector3(0, top + 0.18, cab_z + 0.15), dark)


## Bagger: Oberwagen mit Kabine und Gegengewicht, dreiteiliger Arm (Ausleger, Stiel, Löffel).
## Die drei Gelenke sind eigene Nodes; KraxlVehicle bewegt sie mit der Werkzeug-Taste.
static func _excavator(root: Node3D, _spec: VehicleSpec, top: float, paint: Material, dark: Material) -> Dictionary:
	var metal := _material(CHROME)
	var house := Node3D.new()
	house.name = "Oberwagen"
	house.position = Vector3(0, top, 0.15)
	root.add_child(house)
	_cylinder(house, 0.55, 0.12, Vector3(0, 0.06, 0), Vector3.ZERO, dark)
	_box(house, Vector3(1.25, 0.45, 1.3), Vector3(0, 0.35, 0.15), paint)
	_box(house, Vector3(1.2, 0.35, 0.3), Vector3(0, 0.4, 0.85), dark)  # Gegengewicht
	_box(house, Vector3(0.6, 0.65, 0.65), Vector3(-0.3, 0.88, -0.15), paint)  # Kabine
	_box(house, Vector3(0.5, 0.42, 0.05), Vector3(-0.3, 0.95, -0.48), _material(GLASS))
	_box(house, Vector3(0.05, 0.42, 0.5), Vector3(-0.61, 0.95, -0.15), _material(GLASS))

	var boom := _pivot(house, "Ausleger", Vector3(0.3, 0.55, -0.45))
	_box(boom, Vector3(0.18, 0.2, 1.5), Vector3(0, 0, -0.75), paint)
	var stick := _pivot(boom, "Stiel", Vector3(0, 0, -1.5))
	_box(stick, Vector3(0.14, 1.0, 0.16), Vector3(0, -0.5, 0), paint)
	var bucket := _pivot(stick, "Loeffel", Vector3(0, -1.0, 0))
	_box(bucket, Vector3(0.5, 0.35, 0.08), Vector3(0, -0.15, -0.2), metal)
	_box(bucket, Vector3(0.5, 0.08, 0.35), Vector3(0, -0.32, -0.05), metal)
	for x in [-0.22, -0.07, 0.07, 0.22]:
		_box(bucket, Vector3(0.06, 0.1, 0.08), Vector3(x, -0.36, -0.25), dark)  # Zähne
	var tip := _pivot(bucket, "Spitze", Vector3(0, -0.36, -0.25))  # hier greift der Löffel in die Erde
	# Erde im Löffel: sichtbar, sobald der Löffel voll ist (ADR 0013).
	var dirt := MeshInstance3D.new()
	dirt.name = "Erde"
	var dirt_mesh := SphereMesh.new()
	dirt_mesh.radius = 0.24
	dirt_mesh.height = 0.3
	dirt_mesh.material = _material(DIRT)
	dirt.mesh = dirt_mesh
	dirt.position = Vector3(0, -0.2, -0.08)
	dirt.scale = Vector3(1.0, 0.8, 0.8)
	dirt.visible = false
	bucket.add_child(dirt)
	return {"kind": &"bagger", "boom": boom, "stick": stick, "bucket": bucket, "tip": tip, "dirt": dirt}


static func _pivot(parent: Node3D, node_name: String, pos: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = node_name
	pivot.position = pos
	parent.add_child(pivot)
	return pivot


static func _box(root: Node3D, size: Vector3, pos: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	root.add_child(node)


static func _cylinder(root: Node3D, radius: float, height: float, pos: Vector3, rot: Vector3, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.material = material
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.rotation = rot
	root.add_child(node)


static func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.6
	return m


static func _emissive(color: Color) -> StandardMaterial3D:
	var m := _material(color)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 2.0
	return m
