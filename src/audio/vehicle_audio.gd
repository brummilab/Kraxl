class_name VehicleAudio
extends Node3D
## Geräusche eines Crawlers: Motor (Tonhöhe folgt Tempo und Gas), Ketten-Rattern, Hupe,
## „Plumps“ beim Aufsetzen und ein fröhlicher Dreiklang nach dem Aufstellen.
## Wird von KraxlVehicle selbst angelegt; alle Töne laufen über den begrenzten Bus „Effekte“.

## Motor-Klang je Motor-Teil: Grundfrequenz (Hz) und Rauheit (mehr Obertöne).
const ENGINE_SOUND := {
	&"gemuetlich": [55.0, 0.2],
	&"normal": [70.0, 0.5],
	&"stark": [85.0, 0.9],
}
const IDLE_DB := -16.0
const FULL_THROTTLE_DB := -5.0
const SMOOTHING := 6.0  # 1/s, wie schnell Tonhöhe und Lautstärke nachziehen

var vehicle: KraxlVehicle
var engine: AudioStreamPlayer3D
var rattle: AudioStreamPlayer3D
var effects: AudioStreamPlayer3D

var _horn_was_pressed := false


func _init(owner_vehicle: KraxlVehicle) -> void:
	vehicle = owner_vehicle
	name = "Audio"


func _ready() -> void:
	Sfx.setup_bus()
	var sound: Array = ENGINE_SOUND.get(vehicle.design.choices[&"motor"], ENGINE_SOUND[&"normal"])
	engine = _player(Sfx.engine_loop(sound[0], sound[1]))
	engine.volume_db = IDLE_DB
	engine.play()
	if vehicle.spec.tracks:
		rattle = _player(Sfx.track_rattle_loop())
		rattle.volume_db = -80.0
		rattle.play()
	effects = _player(null)
	effects.max_polyphony = 3
	vehicle.landed.connect(_on_landed)
	vehicle.righted.connect(_on_righted)


func _physics_process(delta: float) -> void:
	var speed := absf(vehicle.linear_velocity.dot(-vehicle.global_basis.z))
	var speed_ratio := clampf(speed / maxf(vehicle.spec.max_speed, 0.1), 0.0, 1.0)
	var throttle := absf(vehicle.input.throttle)
	var blend := 1.0 - exp(-SMOOTHING * delta)

	var target_pitch := 0.8 + speed_ratio * 0.9 + throttle * 0.2
	engine.pitch_scale = lerpf(engine.pitch_scale, target_pitch, blend)
	var target_db := lerpf(IDLE_DB, FULL_THROTTLE_DB, maxf(throttle, speed_ratio * 0.6))
	engine.volume_db = lerpf(engine.volume_db, target_db, blend)

	if rattle:
		rattle.pitch_scale = 0.6 + speed_ratio * 1.4
		rattle.volume_db = lerpf(rattle.volume_db, lerpf(-40.0, -8.0, speed_ratio), blend)

	if vehicle.input.horn and not _horn_was_pressed:
		honk()
	_horn_was_pressed = vehicle.input.horn


func honk() -> void:
	_play_effect(Sfx.horn(), -2.0)


func _on_landed(strength: float) -> void:
	_play_effect(Sfx.thud(), lerpf(-14.0, 0.0, strength), randf_range(0.9, 1.1))


func _on_righted() -> void:
	_play_effect(Sfx.cheer(), -6.0)


func _play_effect(stream: AudioStream, volume_db: float, pitch := 1.0) -> void:
	effects.stream = stream
	effects.volume_db = volume_db
	effects.pitch_scale = pitch
	effects.play()


func _player(stream: AudioStream) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.bus = Sfx.EFFECTS_BUS
	player.unit_size = 12.0  # Kamera ist ~8 m entfernt; Geräusche sollen trotzdem kräftig sein
	add_child(player)
	return player
