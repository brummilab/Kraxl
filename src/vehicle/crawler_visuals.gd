class_name CrawlerVisuals
## Baut das Aussehen eines Crawlers aus einfachen Grundformen (Platzhalter, bis Blender-Modelle
## nach M7 kommen). Nur Optik und Lichter; Kollision und Physik kommen aus VehicleSpec.

const DARK := Color(0.18, 0.18, 0.2)
const GLASS := Color(0.35, 0.55, 0.7)
const CHROME := Color(0.75, 0.75, 0.78)
const LAMP := Color(1.0, 0.95, 0.6)


static func build(root: Node3D, spec: VehicleSpec, design: CrawlerDesign) -> void:
	var paint := _material(spec.color)
	var dark := _material(DARK)
	var b := spec.body_size
	var top := b.y * 0.5
	var front := -b.z * 0.5

	# Fahrgestell: dunkler Rahmen mit farbigem Unterteil.
	_box(root, Vector3(b.x * 0.9, b.y * 0.5, b.z), Vector3(0, -b.y * 0.25, 0), dark)
	_box(root, Vector3(b.x, b.y * 0.5, b.z * 0.96), Vector3(0, b.y * 0.25, 0), paint)

	var cab := spec.cab_size
	var cab_pos := Vector3(0, top + cab.y * 0.5, spec.cab_z)
	match design.choices[&"aufbau"]:
		&"jeep":
			_box(root, cab, cab_pos, paint)
			_box(root, Vector3(cab.x * 0.9, cab.y * 0.5, 0.05), cab_pos + Vector3(0, cab.y * 0.1, -cab.z * 0.5), _material(GLASS))
			_cylinder(root, 0.25, 0.15, Vector3(0, top + 0.3, b.z * 0.5 + 0.08), Vector3(PI / 2, 0, 0), dark)
		&"pickup":
			_box(root, cab, cab_pos, paint)
			_box(root, Vector3(cab.x * 0.9, cab.y * 0.5, 0.05), cab_pos + Vector3(0, cab.y * 0.1, -cab.z * 0.5), _material(GLASS))
			var bed_z := (spec.cab_z + cab.z * 0.5 + b.z * 0.5) * 0.5
			var bed_len := b.z * 0.5 - (spec.cab_z + cab.z * 0.5)
			for side in [-1, 1]:
				_box(root, Vector3(0.06, 0.3, bed_len), Vector3(side * b.x * 0.47, top + 0.15, bed_z), paint)
			_box(root, Vector3(b.x, 0.3, 0.06), Vector3(0, top + 0.15, b.z * 0.5), paint)
		&"traktor":
			_box(root, Vector3(b.x * 0.6, 0.45, b.z * 0.4), Vector3(0, top + 0.22, front + b.z * 0.2), paint)
			for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				var p := Vector3(corner.x * cab.x * 0.45, cab_pos.y, spec.cab_z + corner.y * cab.z * 0.45)
				_box(root, Vector3(0.07, cab.y, 0.07), p, dark)
			_box(root, Vector3(cab.x, 0.08, cab.z), Vector3(0, top + cab.y, spec.cab_z), paint)
			_cylinder(root, 0.05, 0.6, Vector3(cab.x * 0.3, top + 0.7, front + b.z * 0.15), Vector3.ZERO, _material(CHROME))
		&"buggy":
			for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				var p := Vector3(corner.x * cab.x * 0.45, cab_pos.y, spec.cab_z + corner.y * cab.z * 0.45)
				_box(root, Vector3(0.06, cab.y, 0.06), p, _material(CHROME))
			for x in [-1, 1]:
				_box(root, Vector3(0.06, 0.06, cab.z), Vector3(x * cab.x * 0.45, top + cab.y, spec.cab_z), _material(CHROME))
			for z in [-1, 1]:
				_box(root, Vector3(cab.x, 0.06, 0.06), Vector3(0, top + cab.y, spec.cab_z + z * cab.z * 0.45), _material(CHROME))
			_box(root, Vector3(0.5, 0.35, 0.4), Vector3(0, top + 0.18, spec.cab_z + 0.15), dark)
		&"kipper":
			_box(root, cab, cab_pos, paint)
			_box(root, Vector3(cab.x * 0.9, cab.y * 0.5, 0.05), cab_pos + Vector3(0, cab.y * 0.1, -cab.z * 0.5), _material(GLASS))
			var box_len := b.z * 0.5 - (spec.cab_z + cab.z * 0.5) - 0.05
			var box_z := b.z * 0.5 - box_len * 0.5
			_box(root, Vector3(b.x, 0.08, box_len), Vector3(0, top + 0.1, box_z), _material(CHROME))
			for side in [-1, 1]:
				_box(root, Vector3(0.06, 0.45, box_len), Vector3(side * b.x * 0.47, top + 0.33, box_z), _material(CHROME))
			_box(root, Vector3(b.x, 0.45, 0.06), Vector3(0, top + 0.33, box_z - box_len * 0.5), _material(CHROME))
		&"feuerwehr":
			_box(root, cab, cab_pos, paint)
			_box(root, Vector3(cab.x * 0.9, cab.y * 0.4, 0.05), cab_pos + Vector3(0, cab.y * 0.15, -cab.z * 0.5), _material(GLASS))
			for x in [-0.3, 0.3]:
				_box(root, Vector3(0.05, 0.05, cab.z * 1.1), Vector3(x, top + cab.y + 0.06, spec.cab_z), _material(CHROME))
			for i in 6:
				var z := spec.cab_z - cab.z * 0.5 + (i + 0.5) * cab.z / 6.0
				_box(root, Vector3(0.6, 0.04, 0.04), Vector3(0, top + cab.y + 0.06, z), _material(CHROME))
			_box(root, Vector3(0.3, 0.12, 0.15), Vector3(0, top + cab.y + 0.06, spec.cab_z - cab.z * 0.5 + 0.1), _emissive(Color(0.2, 0.4, 1.0)))

		&"abschlepper":
			_box(root, cab, cab_pos, paint)
			_box(root, Vector3(cab.x * 0.9, cab.y * 0.5, 0.05), cab_pos + Vector3(0, cab.y * 0.1, -cab.z * 0.5), _material(GLASS))
			var deck_z := (spec.cab_z + cab.z * 0.5 + b.z * 0.5) * 0.5
			_box(root, Vector3(b.x * 0.9, 0.08, b.z * 0.5 - spec.cab_z - cab.z * 0.5), Vector3(0, top + 0.04, deck_z), dark)
			# Kranarm schräg nach hinten oben, Seil und Haken.
			var boom_base := Vector3(0, top + 0.3, deck_z)
			var boom := MeshInstance3D.new()
			var boom_mesh := BoxMesh.new()
			boom_mesh.size = Vector3(0.14, 0.14, 1.3)
			boom_mesh.material = _material(Color(0.95, 0.75, 0.1))
			boom.mesh = boom_mesh
			boom.position = boom_base + Vector3(0, 0.3, 0.45)
			boom.rotation.x = 0.55
			root.add_child(boom)
			_box(root, Vector3(0.25, 0.3, 0.25), boom_base, dark)
			var tip := boom_base + Vector3(0, 0.6, 1.0)
			_box(root, Vector3(0.02, 0.5, 0.02), tip + Vector3(0, -0.25, 0), dark)
			_box(root, Vector3(0.12, 0.12, 0.05), tip + Vector3(0, -0.55, 0), _material(CHROME))
			_box(root, Vector3(0.3, 0.1, 0.1), cab_pos + Vector3(0, cab.y * 0.55, 0), _emissive(Color(1.0, 0.6, 0.1)))

	var roof_y := top + cab.y
	for id in design.selected_extras():
		match id:
			&"licht":
				for x in [-0.45, 0.45]:
					var lamp_pos := Vector3(x * b.x, top - 0.05, front - 0.02)
					_box(root, Vector3(0.2, 0.15, 0.06), lamp_pos, _emissive(LAMP))
					var light := SpotLight3D.new()
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
