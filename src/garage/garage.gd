extends Node3D
## Garage = Crawler-Baukasten (ADR 0008). Links die Kategorien, unten die Teile, oben rechts
## Würfel (Zufalls-Crawler) und Zielflagge (losfahren). Alles per Antippen oder Gamepad,
## kein Ziehen, kein Text. Jede Änderung sieht man sofort am Crawler auf der Drehscheibe.
## `-- --screenshot=pfad.png` speichert ein Bild und beendet (Review, M2),
## `-- --kategorie=name` öffnet eine bestimmte Kategorie, `-- --spieler=2 --fahrer=2` zeigt den
## Zwei-Spieler-Modus mit dem Crawler von Spieler 2.
## Zwei Spieler (ADR 0012): Die Figuren-Karte schaltet zwischen einem und zwei Spielern um; bei zwei
## Spielern wählen zwei Helm-Karten (ein bzw. zwei Punkte), wessen Crawler gerade gebaut wird.

const WORLD_SCENE := "res://scenes/spike/terrain_spike.tscn"
## Vorlagen (fertige Crawler) stehen als erste „Kategorie“ links, sind aber kein Teil des Bauplans.
const PRESET_CATEGORY := &"vorlagen"
const MARGIN := 16.0
const SEPARATION := 10.0
const MAX_PER_ROW := 9

var design: CrawlerDesign
## KraxlVehicle oder (Aufbau „flieger“) KraxlPlane auf der Drehscheibe.
var vehicle: Node3D
## Wessen Crawler gerade gebaut wird (0 = Spieler 1).
var player := 0
var category: StringName = &"fahrgestell"

var _camera: Camera3D
var _orbit := 0.6
var _category_cards := {}  # Kategorie -> IconCard
var _part_rows: VBoxContainer
var _part_cards: Array[IconCard] = []
var _sfx: AudioStreamPlayer
var _sounds := {}
var _rng := RandomNumberGenerator.new()
var _players_card: IconCard
var _player_cards: Array[IconCard] = []


func _ready() -> void:
	KraxlInput.setup()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	design = GameState.design(player).duplicate_design()
	_build_world()
	_build_ui()
	_spawn_vehicle()
	_update_player_cards()
	show_category(category)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--kategorie="):
			show_category(StringName(arg.get_slice("=", 1)))
		if arg.begins_with("--screenshot="):
			_save_screenshot_later(arg.get_slice("=", 1))
		if arg.begins_with("--spieler="):
			set_player_count(int(arg.get_slice("=", 1)))
		if arg.begins_with("--fahrer="):
			select_player(int(arg.get_slice("=", 1)) - 1)


func _process(delta: float) -> void:
	_orbit += delta * 0.25
	var target := Vector3(0, 0.9, 0)
	_camera.position = target + Vector3(sin(_orbit) * 7.5, 2.6, cos(_orbit) * 7.5)
	_camera.look_at(target)


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	KraxlInput.log_connection(device, connected)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
		go()


# --- Aktionen (auch von Tests aufgerufen) --------------------------------------


func show_category(new_category: StringName) -> void:
	category = new_category
	for c in _category_cards:
		_category_cards[c].selected = c == category
	for card in _part_cards:
		card.queue_free()
	_part_cards.clear()

	var parts: Array = PartCatalog.PRESETS if category == PRESET_CATEGORY else PartCatalog.parts(category)
	# Viele Teile (Farben) in zwei Reihen statt winziger Karten; Wischen bleibt unnötig.
	var rows := 1 if parts.size() <= MAX_PER_ROW else 2
	var per_row := ceili(parts.size() / float(rows))
	var size_px := _part_card_size(per_row, rows)
	for row in _part_rows.get_children():
		row.queue_free()
	var row_box: HBoxContainer
	for i in parts.size():
		if i % per_row == 0:
			row_box = HBoxContainer.new()
			row_box.alignment = BoxContainer.ALIGNMENT_CENTER
			row_box.add_theme_constant_override("separation", int(SEPARATION))
			_part_rows.add_child(row_box)
		var p: Dictionary = parts[i]
		var card := IconCard.new(category, p.id, size_px)
		card.accent = design.get_part(&"farbe").farbe
		if category == PRESET_CATEGORY:
			card.preset = p
		card.pressed.connect(choose_part.bind(card))
		row_box.add_child(card)
		_part_cards.append(card)
	_update_selection()
	var focus_card := _part_cards.filter(func(c): return c.selected)
	(focus_card[0] if not focus_card.is_empty() else _part_cards[0]).grab_focus.call_deferred()
	_play(&"kategorie")


func choose_part(card: IconCard) -> void:
	if card.category == PRESET_CATEGORY:
		design = CrawlerDesign.from_preset(card.preset)
	else:
		design.select(card.category, card.part_id)
	_update_selection()
	card.bounce()
	_play(card.category)
	if card.category in [&"farbe", PRESET_CATEGORY]:
		_refresh_accent()
	_spawn_vehicle()
	GameState.set_design(design, player)


func _update_selection() -> void:
	for c in _part_cards:
		c.selected = design.matches(c.preset) if c.category == PRESET_CATEGORY \
			else design.is_selected(c.category, c.part_id)


func roll_dice() -> void:
	design = CrawlerDesign.random(_rng)
	_refresh_accent()
	show_category(category)
	_spawn_vehicle()
	GameState.set_design(design, player)
	_play(&"wuerfel")


func go() -> void:
	GameState.set_design(design, player)
	get_tree().change_scene_to_file(WORLD_SCENE)


## Ein oder zwei Spieler. Bei einem Spieler wird immer Spieler 1 gebaut.
func set_player_count(count: int) -> void:
	GameState.set_player_count(count)
	if GameState.player_count() == 1 and player != 0:
		select_player(0)
	_update_player_cards()
	_play(&"spieler")


func toggle_players() -> void:
	set_player_count(2 if GameState.player_count() == 1 else 1)
	_players_card.bounce()


## Wechselt, wessen Crawler auf der Drehscheibe steht und gebaut wird.
func select_player(index: int) -> void:
	GameState.set_design(design, player)
	player = index
	design = GameState.design(player).duplicate_design()
	_refresh_accent()
	show_category(category)
	_spawn_vehicle()
	_update_player_cards()
	_play(&"spieler")


func _update_player_cards() -> void:
	var count := GameState.player_count()
	_players_card.part_id = StringName(str(count))
	_players_card.queue_redraw()
	for i in _player_cards.size():
		var card := _player_cards[i]
		card.visible = count > 1
		card.selected = i == player
		card.accent = GameState.design(i).get_part(&"farbe").farbe if i != player else design.get_part(&"farbe").farbe
		card.queue_redraw()


# --- Aufbau ------------------------------------------------------------------


func _spawn_vehicle() -> void:
	if vehicle:
		vehicle.queue_free()
	if design.is_plane():
		var plane := KraxlPlane.new()
		plane.preview = true
		plane.design = design.duplicate_design()
		plane.position = Vector3(0, 0.05, 0)
		vehicle = plane
	else:
		var crawler := KraxlVehicle.new()
		crawler.design = design.duplicate_design()
		crawler.position = Vector3(0, 1.6, 0)
		vehicle = crawler
	vehicle.rotation.y = -0.6
	add_child(vehicle)
	_update_category_visibility()


## Beim Flieger zählen nur Aufbau und Farbe; die Crawler-Kategorien verschwinden, bis wieder ein
## Crawler-Aufbau gewählt ist.
func _update_category_visibility() -> void:
	var plane := design.is_plane()
	for c in _category_cards:
		_category_cards[c].visible = not plane or c == PRESET_CATEGORY or c in PartCatalog.PLANE_CATEGORIES
	if _category_cards.has(category) and not _category_cards[category].visible:
		show_category.call_deferred(&"aufbau")


func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-55), deg_to_rad(30), 0)
	sun.shadow_enabled = true
	add_child(sun)

	var floor_body := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(40, 1, 40)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = -0.5
	floor_body.add_child(collision)
	add_child(floor_body)
	floor_body.add_child(_mesh(_cylinder_mesh(5.0, 0.1), Vector3(0, 0.0, 0), Color(0.55, 0.57, 0.6)))
	floor_body.add_child(_mesh(_plane_mesh(400.0), Vector3(0, -0.06, 0), Color(0.82, 0.78, 0.7)))

	_camera = Camera3D.new()
	_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # dreht in _process
	add_child(_camera)

	_sfx = AudioStreamPlayer.new()
	add_child(_sfx)
	var pitches := [440.0, 523.0, 587.0, 659.0, 698.0, 784.0, 880.0, 988.0, 1047.0, 1175.0, 1319.0]
	var categories := _garage_categories()
	for i in categories.size():
		_sounds[categories[i]] = Sfx.blip(pitches[i % pitches.size()])
	_sounds[&"kategorie"] = Sfx.blip(392.0, 0.06)
	_sounds[&"wuerfel"] = Sfx.blip(330.0, 0.2)
	_sounds[&"spieler"] = Sfx.blip(494.0, 0.12)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		root.add_theme_constant_override("margin_" + side, int(MARGIN))
	layer.add_child(root)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", int(SEPARATION * 2))
	root.add_child(columns)

	var category_column := VBoxContainer.new()
	category_column.add_theme_constant_override("separation", int(SEPARATION * 0.6))
	columns.add_child(category_column)
	var cat_size := _category_card_size()
	for c in _garage_categories():
		var card := IconCard.new(c, &"", cat_size)
		card.accent = design.get_part(&"farbe").farbe
		card.pressed.connect(func():
			card.bounce()
			show_category(c))
		category_column.add_child(card)
		_category_cards[c] = card

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)

	var top_row := HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_END
	top_row.add_theme_constant_override("separation", int(SEPARATION * 2))
	right.add_child(top_row)
	_players_card = IconCard.new(&"spieler", &"1", cat_size * 1.4)
	_players_card.pressed.connect(toggle_players)
	top_row.add_child(_players_card)
	for i in GameState.MAX_PLAYERS:
		var card := IconCard.new(&"fahrer", StringName(str(i + 1)), cat_size * 1.4)
		card.pressed.connect(_on_player_card.bind(i))
		top_row.add_child(card)
		_player_cards.append(card)
	var spacer_top := Control.new()
	spacer_top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer_top)
	var dice := IconCard.new(&"wuerfel", &"", cat_size * 1.4)
	dice.pressed.connect(func():
		dice.bounce()
		roll_dice())
	top_row.add_child(dice)
	var go_card := IconCard.new(&"los", &"", cat_size * 1.8)
	go_card.pressed.connect(go)
	top_row.add_child(go_card)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)

	_part_rows = VBoxContainer.new()
	_part_rows.add_theme_constant_override("separation", int(SEPARATION))
	right.add_child(_part_rows)


func _on_player_card(index: int) -> void:
	_player_cards[index].bounce()
	select_player(index)


func _garage_categories() -> Array[StringName]:
	var out: Array[StringName] = [PRESET_CATEGORY]
	out.append_array(PartCatalog.CATEGORIES)
	return out


func _category_card_size() -> float:
	var h := get_viewport().get_visible_rect().size.y
	var n := _garage_categories().size()
	return clampf((h - 2 * MARGIN - (n - 1) * SEPARATION * 0.6) / n, 48.0, 110.0)


## Teile-Karten so groß wie möglich, aber alle sichtbar (kein Wischen nötig).
func _part_card_size(per_row: int, rows := 1) -> float:
	var view := get_viewport().get_visible_rect().size
	var width := view.x - 2 * MARGIN - _category_card_size() - SEPARATION * 2
	var height := view.y * (0.22 if rows == 1 else 0.17)
	return clampf(minf(height, width / per_row - SEPARATION), 56.0, 170.0)


func _refresh_accent() -> void:
	var color: Color = design.get_part(&"farbe").farbe
	for card in _category_cards.values() + _part_cards:
		card.accent = color
		card.queue_redraw()
	if not _player_cards.is_empty():
		_update_player_cards()


func _play(key: StringName) -> void:
	if _sounds.has(key):
		_sfx.stream = _sounds[key]
		_sfx.play()


func _save_screenshot_later(path: String) -> void:
	await get_tree().create_timer(2.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("[Garage] Screenshot: ", path)
	get_tree().quit()


static func _mesh(mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	return node


static func _cylinder_mesh(radius: float, height: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	return m


static func _plane_mesh(size: float) -> PlaneMesh:
	var m := PlaneMesh.new()
	m.size = Vector2(size, size)
	return m
