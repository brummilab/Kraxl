class_name Sfx
## Erzeugt kurze Töne per Code, bis echte Sounds kommen (M5: Ton-Feedback binnen 100 ms).

const MIX_RATE := 22050


## Weicher „Plopp“: Sinus mit kurzem Abklingen.
static func blip(frequency: float, seconds := 0.09) -> AudioStreamWAV:
	var samples := int(MIX_RATE * seconds)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / MIX_RATE
		var envelope := exp(-t * 40.0) * minf(1.0, t * 400.0)
		var value := sin(TAU * frequency * t * (1.0 + t * 2.0)) * envelope * 0.5
		data.encode_s16(i * 2, int(value * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.data = data
	return stream
