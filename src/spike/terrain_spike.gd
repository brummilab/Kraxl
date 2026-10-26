extends Node3D
## Spike-Szene (ADR 0001/0004): Terrain3D + gebauter Crawler + Touch/Gamepad + FPS-Messung.
## Schraubenschlüssel oben links (oder Select am Gamepad) führt zurück in die Garage.
## Läuft auf Windows und Android. Knopf oben rechts startet die 5-min-Fahrbot-Runde;
## das Ergebnis steht danach auf dem Bildschirm und im Log (Remote-Debugger / adb logcat).
## Mit `-- --benchmark` startet die Runde sofort, `-- --benchmark-seconds=N` verkürzt sie,
## `-- --screenshot=pfad.png` speichert ein Bild und beendet.

const C := preload("res://src/vehicle/vehicle_constants.gd")
const GARAGE_SCENE := "res://scenes/garage/garage.tscn"
const BENCHMARK_SECONDS := 300.0
const TARGET_FPS := 30.0
const CAMERA_DISTANCE := 8.0
const CAMERA_HEIGHT := 3.5

var vehicle: KraxlVehicle
var touch: TouchControls

var _camera: Camera3D
var _terrain: Terrain3D
var _hud: Label
var _bench_button: Button
var _driver_input: InputSource
var _benchmark_seconds := BENCHMARK_SECONDS
var _bench_running := false
var _bench_time := 0.0
var _frame_times := PackedFloat32Array()
var _result_text := ""


func _ready() -> void:
	_camera = Camera3D.new()
	_camera.far = 1000.0
	# Die Kamera folgt in _process; Physik-Interpolation würde sie doppelt glätten (Godot warnt).
	_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_camera)
	_terrain = SpikeTerrain.create(self, _camera)

	KraxlInput.setup()
	vehicle = KraxlVehicle.new()
	vehicle.design = GameState.design().duplicate_design()
	var start := SpikeTerrain.CENTER
	start.y = SpikeTerrain.height_at(start.x, start.z) + 1.0
	vehicle.position = start
	add_child(vehicle)

	_build_ui()
	_driver_input = CombinedInputSource.new([touch.source, ActionInputSource.new()])
	vehicle.input = _driver_input
	_camera.global_position = start + Vector3(0, CAMERA_HEIGHT, CAMERA_DISTANCE)

	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--benchmark-seconds="):
			_benchmark_seconds = float(arg.get_slice("=", 1))
		if arg.begins_with("--screenshot="):
			_save_screenshot_later(arg.get_slice("=", 1))
	if args.has("--benchmark") or _benchmark_seconds != BENCHMARK_SECONDS:
		_start_benchmark()


## Für Review-Bilder (M2): nach 4 s Fahrt Bild speichern und beenden.
func _save_screenshot_later(path: String) -> void:
	vehicle.input = BotInputSource.new([{"duration": 10.0, "throttle": 0.6, "steer": 0.3}])
	await get_tree().create_timer(4.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("[Spike] Screenshot: ", path)
	get_tree().quit()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(KraxlInput.GARAGE):
		open_garage()
	_follow_camera(delta)
	if _bench_running:
		_frame_times.append(delta)
		_bench_time += delta
		if _bench_time >= _benchmark_seconds:
			_finish_benchmark()
	_update_hud()


## Automatische Kamera ohne Zoom-Gesten (ADR 0003): folgt ruhig von hinten oben.
func _follow_camera(delta: float) -> void:
	var back := vehicle.global_basis.z
	back.y = 0.0
	back = back.normalized() if back.length() > 0.1 else Vector3.BACK
	var target := vehicle.global_position + back * CAMERA_DISTANCE + Vector3.UP * CAMERA_HEIGHT
	var ground := SpikeTerrain.height_at(target.x, target.z) + 1.5
	target.y = maxf(target.y, ground)
	_camera.global_position = _camera.global_position.lerp(target, 1.0 - exp(-3.0 * delta))
	_camera.look_at(vehicle.global_position + Vector3.UP)


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
	var args := Array(OS.get_cmdline_user_args())
	if "--benchmark" in args or args.any(func(a): return a.begins_with("--benchmark-seconds=")):
		get_tree().quit(0 if ok else 1)


func _update_hud() -> void:
	var text := "%d fps\n%s" % [Engine.get_frames_per_second(), _system_info()]
	if _bench_running:
		text += "\nFahrbot: %d / %d s" % [_bench_time, _benchmark_seconds]
	if _result_text:
		text += "\n" + _result_text
	_hud.text = text


func _system_info() -> String:
	var v := Engine.get_version_info()
	return "Godot %s | Terrain3D %s | %s | %s | %s" % [
		v.string,
		_terrain.get_version(),
		RenderingServer.get_current_rendering_method(),
		RenderingServer.get_video_adapter_name(),
		OS.get_model_name(),
	]


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	touch = TouchControls.new()
	layer.add_child(touch)

	_hud = Label.new()
	_hud.position = Vector2(128, 16)
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
