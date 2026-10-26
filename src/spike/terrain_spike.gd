extends Node3D
## Spike-Szene (ADR 0001/0004): Terrain3D + gebauter Crawler + Touch/Gamepad + FPS-Messung.
## Schraubenschlüssel oben links (oder Select am Gamepad) führt zurück in die Garage.
## Statuszeile und „Fahrbot 5 min“ sind Entwickler-Werkzeuge: in Debug-Builds sichtbar,
## in der Exe/APK für Kinder ausgeblendet; F3 blendet sie jederzeit ein und aus.
## Läuft auf Windows und Android. Knopf oben rechts startet die 5-min-Fahrbot-Runde;
## das Ergebnis steht danach auf dem Bildschirm und im Log (Remote-Debugger / adb logcat).
## Mit `-- --benchmark` startet die Runde sofort, `-- --benchmark-seconds=N` verkürzt sie,
## `-- --screenshot=pfad.png` speichert ein Bild und beendet, `-- --spieler=2` erzwingt zwei Spieler.
## Zwei Spieler (ADR 0012): geteilter Bildschirm links/rechts, jeder mit eigenem Crawler, eigener
## Kamera, eigener Touch-Hälfte, eigener Tastaturhälfte und eigenem Gamepad.
## Weltrand: bunter Zaun mit unsichtbarer Wand; wer trotzdem hinausfällt, steht sofort wieder am Start.

const C := preload("res://src/vehicle/vehicle_constants.gd")
const GARAGE_SCENE := "res://scenes/garage/garage.tscn"
const BENCHMARK_SECONDS := 300.0
const TARGET_FPS := 30.0
const CAMERA_DISTANCE := 8.0
const CAMERA_HEIGHT := 3.5

const PLAYER_SPACING := 5.0  # Abstand der Startplätze im Zwei-Spieler-Modus (m)

## Spieler 1 (Fahrbot-Runde, Screenshot und Tests nutzen ihn).
var vehicle: KraxlVehicle
var touch: TouchControls
var players: Array[Player] = []

## Kamera der Hauptansicht; im Zwei-Spieler-Modus nur Mittelpunkt für Terrain3D und Hörposition.
var _camera: Camera3D
var _terrain: Terrain3D
var _hud: Label
var _bench_button: Button
var _driver_input: InputSource
var _layer: CanvasLayer
var _benchmark_seconds := BENCHMARK_SECONDS
var _bench_running := false
var _bench_time := 0.0
var _frame_times := PackedFloat32Array()
var _result_text := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var count := GameState.player_count()
	for arg in args:
		if arg.begins_with("--spieler="):
			count = clampi(int(arg.get_slice("=", 1)), 1, GameState.MAX_PLAYERS)

	_camera = Camera3D.new()
	_camera.far = 1000.0
	# Die Kamera folgt in _process; Physik-Interpolation würde sie doppelt glätten (Godot warnt).
	_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_camera)
	_terrain = SpikeTerrain.create(self, _camera)
	add_child(WorldBorder.new())
	add_child(Playground.new())

	KraxlInput.setup()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_layer = CanvasLayer.new()
	add_child(_layer)
	for i in count:
		players.append(_add_player(i, count))
	vehicle = players[0].vehicle
	touch = players[0].touch
	_driver_input = players[0].input
	if count > 1:
		_split_screen()
	else:
		_camera.global_position = vehicle.global_position + Vector3(0, CAMERA_HEIGHT, CAMERA_DISTANCE)
	_build_ui()

	for arg in args:
		if arg.begins_with("--benchmark-seconds="):
			_benchmark_seconds = float(arg.get_slice("=", 1))
		if arg.begins_with("--screenshot="):
			_save_screenshot_later(arg.get_slice("=", 1))
	if args.has("--benchmark") or _benchmark_seconds != BENCHMARK_SECONDS:
		_start_benchmark()
	set_dev_tools(OS.is_debug_build() or args.has("--dev") or _bench_running)


func _add_player(index: int, count: int) -> Player:
	var player := Player.new()
	player.vehicle = KraxlVehicle.new()
	player.vehicle.design = GameState.design(index).duplicate_design()
	var pos := SpikeTerrain.CENTER + Vector3((index - (count - 1) * 0.5) * PLAYER_SPACING, 0, 0)
	pos.y = SpikeTerrain.height_at(pos.x, pos.z) + 1.0
	player.start = Transform3D(Basis(), pos)
	player.vehicle.position = pos
	add_child(player.vehicle)

	player.touch = TouchControls.new()
	if count > 1:
		player.touch.fill_parent = false
		player.touch.anchor_left = 0.5 * index
		player.touch.anchor_right = 0.5 * (index + 1)
		player.touch.anchor_bottom = 1.0
	_layer.add_child(player.touch)
	player.touch.show_light = player.vehicle.has_lights()
	player.touch.show_tool = player.vehicle.has_tool()
	player.input = CombinedInputSource.new([player.touch.source, ActionInputSource.new(index if count > 1 else -1)])
	player.vehicle.input = player.input
	player.camera = _camera
	return player


## Zwei Hälften nebeneinander, jede mit eigener Kamera in derselben 3D-Welt. Die Hauptansicht
## zeichnet dann kein 3D mehr; ihre Kamera bleibt als Mittelpunkt für Terrain3D und als Ohr.
func _split_screen() -> void:
	var view_layer := CanvasLayer.new()
	view_layer.layer = -1  # unter den Tasten
	add_child(view_layer)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view_layer.add_child(row)
	var divider := ColorRect.new()
	divider.color = Color.WHITE
	divider.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view_layer.add_child(divider)
	view_layer.move_child(divider, 0)  # weiße Trennlinie scheint durch die Lücke

	for player in players:
		var container := SubViewportContainer.new()
		container.stretch = true
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(container)
		var view := SubViewport.new()
		view.world_3d = get_viewport().world_3d
		view.physics_object_picking = false
		container.add_child(view)
		var camera := Camera3D.new()
		camera.far = 1000.0
		camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		view.add_child(camera)
		camera.global_position = player.vehicle.global_position + Vector3(0, CAMERA_HEIGHT, CAMERA_DISTANCE)
		player.camera = camera
	get_viewport().disable_3d = true


func _exit_tree() -> void:
	get_viewport().disable_3d = false  # die Garage braucht die Hauptansicht wieder


func set_dev_tools(visible_now: bool) -> void:
	_hud.visible = visible_now
	_bench_button.visible = visible_now


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		set_dev_tools(not _hud.visible)


## Für Review-Bilder (M2): nach 4 s Fahrt Bild speichern und beenden.
func _save_screenshot_later(path: String) -> void:
	for player in players:
		player.vehicle.input = BotInputSource.new([{"duration": 10.0, "throttle": 0.6, "steer": 0.3}])
	await get_tree().create_timer(4.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("[Spike] Screenshot: ", path)
	get_tree().quit()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(KraxlInput.GARAGE):
		open_garage()
	for player in players:
		_follow_camera(player.camera, player.vehicle, delta)
	if players.size() > 1:
		_camera.global_position = (players[0].vehicle.global_position + players[1].vehicle.global_position) * 0.5 \
			+ Vector3.UP * CAMERA_HEIGHT
	if _bench_running:
		_frame_times.append(delta)
		_bench_time += delta
		if _bench_time >= _benchmark_seconds:
			_finish_benchmark()
	_update_hud()


## Automatische Kamera ohne Zoom-Gesten (ADR 0003): folgt ruhig von hinten oben.
func _follow_camera(camera: Camera3D, car: KraxlVehicle, delta: float) -> void:
	var back := car.global_basis.z
	back.y = 0.0
	back = back.normalized() if back.length() > 0.1 else Vector3.BACK
	var target := car.global_position + back * CAMERA_DISTANCE + Vector3.UP * CAMERA_HEIGHT
	var ground := SpikeTerrain.height_at(target.x, target.z) + 1.5
	target.y = maxf(target.y, ground)
	camera.global_position = camera.global_position.lerp(target, 1.0 - exp(-3.0 * delta))
	camera.look_at(car.global_position + Vector3.UP)


## Aus der Welt gefallen (Rand, Loch)? Dann sofort und ohne Aufhebens zurück an den Start.
func _physics_process(_delta: float) -> void:
	for player in players:
		if WorldBorder.is_lost(player.vehicle.global_position):
			player.vehicle.reset_to(player.start)
			player.camera.global_position = player.start.origin + Vector3(0, CAMERA_HEIGHT, CAMERA_DISTANCE)


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	KraxlInput.log_connection(device, connected)


func open_garage() -> void:
	get_tree().change_scene_to_file(GARAGE_SCENE)


func _start_benchmark() -> void:
	_frame_times.clear()
	_bench_time = 0.0
	_bench_running = true
	_result_text = ""
	# Weite Runde mit leichtem Lenkeinschlag über Wiese und Hügel.
	vehicle.input = BotInputSource.new([{"duration": _benchmark_seconds + 5.0, "throttle": 0.7, "steer": 0.2}])
	_bench_button.text = "Fahrbot läuft …"
	_bench_button.disabled = true
	print("[Spike] Fahrbot-Runde gestartet: %d s" % _benchmark_seconds)


func _finish_benchmark() -> void:
	_bench_running = false
	vehicle.input = _driver_input
	_bench_button.text = "Fahrbot 5 min"
	_bench_button.disabled = false

	var sorted := _frame_times.duplicate()
	sorted.sort()
	var total := 0.0
	for t in _frame_times:
		total += t
	var avg_fps := _frame_times.size() / total
	var low_1 := 1.0 / sorted[int(sorted.size() * 0.99)]  # 1 % langsamste Frames
	var min_fps := 1.0 / sorted[sorted.size() - 1]
	var ok := low_1 >= TARGET_FPS
	_result_text = "Fahrbot %d s: Ø %.1f fps, 1%%-Low %.1f fps, Min %.1f fps → %s" % [
		_benchmark_seconds, avg_fps, low_1, min_fps, "BESTANDEN" if ok else "NICHT BESTANDEN"
	]
	print("[Spike] ", _result_text)
	print("[Spike] ", _system_info().replace("\n", " | "))
	print("[Spike] ", KraxlInput.describe_joypads())
	var args := Array(OS.get_cmdline_user_args())
	if "--benchmark" in args or args.any(func(a): return a.begins_with("--benchmark-seconds=")):
		get_tree().quit(0 if ok else 1)


func _update_hud() -> void:
	var text := "%d fps\n%s\n%s" % [Engine.get_frames_per_second(), _system_info(), KraxlInput.describe_joypads()]
	if _bench_running:
		text += "\nFahrbot: %d / %d s" % [_bench_time, _benchmark_seconds]
	if _result_text:
		text += "\n" + _result_text
	_hud.text = text


func _system_info() -> String:
	var v := Engine.get_version_info()
	return "Kraxl %s | Godot %s | Terrain3D %s | %s | %s | %s" % [
		GameState.version(),
		v.string,
		_terrain.get_version(),
		RenderingServer.get_current_rendering_method(),
		RenderingServer.get_video_adapter_name(),
		OS.get_model_name(),
	]


func _build_ui() -> void:
	var layer := _layer

	_hud = Label.new()
	# Breite bis vor den Fahrbot-Knopf begrenzen und umbrechen, sonst läuft lange Info darunter.
	_hud.anchor_right = 1.0
	_hud.offset_left = 128
	_hud.offset_top = 16
	_hud.offset_right = -252
	_hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 6)
	layer.add_child(_hud)

	_bench_button = Button.new()
	_bench_button.text = "Fahrbot 5 min"
	_bench_button.custom_minimum_size = Vector2(220, 80)
	_bench_button.anchor_left = 1.0
	_bench_button.anchor_right = 1.0
	_bench_button.offset_left = -236
	_bench_button.offset_right = -16
	_bench_button.offset_top = 16
	_bench_button.offset_bottom = 96
	_bench_button.pressed.connect(_start_benchmark)
	_bench_button.focus_mode = Control.FOCUS_NONE  # sonst löst der Gas-Knopf am Gamepad ihn aus
	layer.add_child(_bench_button)

	var garage := IconCard.new(&"garage", &"", 96.0)
	garage.focus_mode = Control.FOCUS_NONE
	garage.position = Vector2(16, 16)
	garage.pressed.connect(open_garage)
	layer.add_child(garage)


class Player:
	extends RefCounted
	var vehicle: KraxlVehicle
	var camera: Camera3D
	var touch: TouchControls
	var input: InputSource
	var start: Transform3D
