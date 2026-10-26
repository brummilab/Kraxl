extends Node
## Erzeugt die README-Bilder in docs/screenshots/ (reproduzierbar, gleiche Welt bei jedem Lauf).
## Aufruf mit Grafik (nicht headless), feste Bildrate für gleiche Spielzeit pro Bild:
##   godot --rendering-method gl_compatibility --fixed-fps 30 --resolution 1280x720 \
##     res://tests/screenshots/screenshots.tscn
## Unter Linux ohne Bildschirm mit `xvfb-run -a -s "-screen 0 1280x720x24"` davor.
## Baupläne werden nur im Speicher gesetzt (GameState), die gespeicherten Crawler bleiben unberührt.

const OUT := "res://docs/screenshots/"
const GARAGE := "res://scenes/garage/garage.tscn"
const WORLD := "res://scenes/spike/terrain_spike.tscn"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _garage("garage-vorlagen", _preset(&"gelaendewagen"), &"vorlagen")
	await _garage("garage-farben", _design({&"aufbau": &"jeep", &"raeder": &"gross", &"farbe": &"regenbogen",
		&"extras": [&"licht", &"dachtraeger"]}), &"farbe")
	await _world_single()
	await _world_two_players()
	await _world_digging()
	await _world_plane()
	print("[Screenshots] fertig")
	get_tree().quit()


func _garage(file: String, design: CrawlerDesign, category: StringName) -> void:
	_set_players([design])
	var garage: Node = load(GARAGE).instantiate()
	add_child(garage)
	await _frames(2)
	garage.show_category(category)
	await _frames(45)
	await _save(file)
	garage.queue_free()
	await _frames(2)


## Ein Spieler: Kegel-Slalom, Blumen, Auspuffrauch.
func _world_single() -> void:
	_set_players([_preset(&"hochbeiner")])
	var world := await _world()
	world.vehicle.input = BotInputSource.new([{"duration": 10.0, "throttle": 0.5, "steer": 0.15}])
	await _frames(75)
	await _save("gelaende")
	await _close(world)


## Zwei Spieler mit geteiltem Bildschirm.
func _world_two_players() -> void:
	_set_players([_preset(&"radlader"), _design({&"aufbau": &"pickup", &"farbe": &"pink", &"raeder": &"gross"})])
	var world := await _world()
	for p in world.players:
		p.vehicle.input = BotInputSource.new([{"duration": 10.0, "throttle": 0.6, "steer": -0.2}])
	await _frames(60)
	await _save("zwei-spieler")
	await _close(world)


## Bagger mit vollem Löffel neben einer frisch gegrabenen Mulde und einem Haufen.
func _world_digging() -> void:
	_set_players([_preset(&"bagger")])
	var world := await _world()
	var bagger: KraxlVehicle = world.vehicle
	var p := bagger.global_position
	for i in 2:
		world._digging.reshape(p + Vector3(-1.0, 0, -3.6), -0.45)
	world._digging.reshape(p + Vector3(3.2, 0, -3.0), 0.4)
	world._digging.reshape(p + Vector3(3.6, 0, -2.2), 0.4)
	var bot := BotInputSource.new()
	bot.tool = 0.7
	bagger.input = bot
	bagger.set_bucket_full(true)
	await _frames(40)
	_camera_at(world, p + Vector3(7.5, 4.0, 3.5), p + Vector3(0.5, 0, -2.5))
	await _frames(2)
	await _save("bagger-graebt")
	await _close(world)


## Regenbogen-Flieger in der Luft über der Wiese.
func _world_plane() -> void:
	_set_players([_design({&"aufbau": &"flieger", &"farbe": &"regenbogen"})])
	var world := await _world()
	var plane: KraxlPlane = world.vehicle
	plane.reset_to(Transform3D(Basis(Vector3.UP, 0.5), plane.global_position + Vector3(0, 9, 0)))
	plane.speed = 13.0
	plane.input = BotInputSource.new([{"duration": 10.0, "throttle": 0.3, "steer": 0.4}])
	await _frames(45)
	await _save("flieger")
	await _close(world)


func _world() -> Node:
	var world: Node = load(WORLD).instantiate()
	add_child(world)
	await _frames(2)
	world.set_dev_tools(false)
	for p in world.players:
		p.touch.shown = false
	return world


func _close(world: Node) -> void:
	world.queue_free()
	await _frames(2)


func _camera_at(world: Node, from: Vector3, target: Vector3) -> void:
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.global_position = from
	camera.look_at(target)
	camera.make_current()


func _set_players(designs: Array) -> void:
	GameState.forget()
	GameState._players = designs.size()
	for i in designs.size():
		GameState._designs[i] = designs[i]


func _preset(id: StringName) -> CrawlerDesign:
	for preset in PartCatalog.PRESETS:
		if preset.id == id:
			return CrawlerDesign.from_preset(preset)
	return CrawlerDesign.new()


func _design(choices: Dictionary) -> CrawlerDesign:
	var d := CrawlerDesign.new()
	for key in choices:
		d.choices[key] = choices[key]
	return d


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _save(file: String) -> void:
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(OUT + file + ".png")
	get_viewport().get_texture().get_image().save_png(path)
	print("[Screenshots] ", path)
