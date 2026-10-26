class_name Sfx
## Erzeugt alle Töne per Code, bis echte Sounds kommen (M5: Ton-Feedback binnen 100 ms).
## Nur freundliche Klänge: kein „Falsch“-Ton, kein Alarm (Kinder-Regel 4).
## Schleifen (Motor, Ketten) werden einmal erzeugt und zur Laufzeit nur in Tonhöhe und
## Lautstärke verändert – das kostet auf schwachen Handys praktisch nichts.

const MIX_RATE := 22050
const EFFECTS_BUS := &"Effekte"
## Obergrenze für alle Effekte (M5: Lautstärke-Obergrenze im Mixer), in dB.
const EFFECTS_CEILING_DB := -6.0

static var _cache := {}


## Legt einmalig den Bus „Effekte“ mit Begrenzer an. Idempotent.
static func setup_bus() -> void:
	if AudioServer.get_bus_index(EFFECTS_BUS) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, EFFECTS_BUS)
	AudioServer.set_bus_send(index, &"Master")
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = EFFECTS_CEILING_DB
	AudioServer.add_bus_effect(index, limiter)


## Weicher „Plopp“: Sinus mit kurzem Abklingen.
static func blip(frequency: float, seconds := 0.09) -> AudioStreamWAV:
	return _cached("blip_%d_%d" % [frequency, seconds * 1000], func():
		return _render(seconds, func(t: float) -> float:
			var envelope := exp(-t * 40.0) * minf(1.0, t * 400.0)
			return sin(TAU * frequency * t * (1.0 + t * 2.0)) * envelope * 0.5))


## Kurzer, leiser Klick für Touch-Tasten.
static func click() -> AudioStreamWAV:
	return _cached("click", func():
		return _render(0.04, func(t: float) -> float:
			return sin(TAU * 1400.0 * t) * exp(-t * 120.0) * 0.35))


## Zweiklang-Hupe („tüt-tüt“-Grundton), rechteckig für den typischen Hupen-Charakter.
static func horn() -> AudioStreamWAV:
	return _cached("horn", func():
		return _render(0.4, func(t: float) -> float:
			var envelope := minf(1.0, t * 60.0) * minf(1.0, (0.4 - t) * 30.0)
			var a := signf(sin(TAU * 392.0 * t))
			var b := signf(sin(TAU * 494.0 * t))
			return (a + b) * 0.16 * envelope))


## Dumpfes „Plumps“ beim Aufsetzen: tiefer Ton mit fallender Tonhöhe plus etwas Rauschen.
static func thud() -> AudioStreamWAV:
	return _cached("thud", func():
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		return _render(0.3, func(t: float) -> float:
			var tone := sin(TAU * (90.0 - t * 120.0) * t) * exp(-t * 14.0)
			var noise := rng.randf_range(-1.0, 1.0) * exp(-t * 40.0) * 0.4
			return (tone + noise) * 0.6))


## Fröhlicher Dreiklang, wenn sich der Crawler wieder aufgestellt hat.
static func cheer() -> AudioStreamWAV:
	return _cached("cheer", func():
		return _render(0.45, func(t: float) -> float:
			var notes := [523.25, 659.25, 783.99]
			var i := mini(int(t / 0.12), 2)
			var local := t - i * 0.12
			return sin(TAU * notes[i] * t) * exp(-local * 9.0) * 0.4))


## Motor-Schleife: Grundton mit Obertönen und Zünd-Pulsieren. Länge ist ein ganzzahliges Vielfaches
## der Periode, damit die Schleife ohne Knacksen wiederholt. `roughness` 0..1 = mehr Obertöne.
static func engine_loop(base_frequency: float, roughness: float) -> AudioStreamWAV:
	return _cached("engine_%d_%d" % [base_frequency, roughness * 100], func():
		var period := roundi(MIX_RATE / base_frequency)
		var cycles := maxi(1, roundi(0.5 * MIX_RATE / period))
		var f := float(MIX_RATE) / period
		var stream := _render(float(period * cycles) / MIX_RATE, func(t: float) -> float:
			var phase := TAU * f * t
			var tone := sin(phase) + 0.5 * sin(2.0 * phase) * (0.5 + roughness)
			tone += 0.3 * sin(3.0 * phase) * roughness + 0.15 * signf(sin(phase)) * roughness
			var pulse := 0.75 + 0.25 * sin(phase * 0.5)  # Zündtakt
			return tone * pulse * 0.22, period * cycles)
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = period * cycles
		return stream)


## Ketten-Rattern: acht kurze Klacker pro Schleife, jeder klingt vor dem nächsten ab.
static func track_rattle_loop() -> AudioStreamWAV:
	return _cached("rattle", func():
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		var length := int(0.4 * MIX_RATE)
		var stream := _render(0.4, func(t: float) -> float:
			var local := fmod(t, 0.05)
			return rng.randf_range(-1.0, 1.0) * exp(-local * 160.0) * 0.35, length)
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = length
		return stream)


static func _cached(key: String, build: Callable) -> AudioStreamWAV:
	if not _cache.has(key):
		_cache[key] = build.call()
	return _cache[key]


## Rechnet `wave(t)` (Werte -1..1) in einen 16-Bit-Mono-Stream.
static func _render(seconds: float, wave: Callable, samples := -1) -> AudioStreamWAV:
	if samples < 0:
		samples = int(MIX_RATE * seconds)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var value := clampf(wave.call(float(i) / MIX_RATE), -1.0, 1.0)
		data.encode_s16(i * 2, int(value * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.data = data
	return stream
