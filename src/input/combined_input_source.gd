class_name CombinedInputSource
extends InputSource
## Fasst mehrere Quellen zusammen (z. B. Touch + Tastatur). Werte werden addiert und begrenzt.

var sources: Array[InputSource] = []


func _init(input_sources: Array[InputSource] = []) -> void:
	sources = input_sources


func update(delta: float) -> void:
	throttle = 0.0
	steer = 0.0
	horn = false
	for source in sources:
		source.update(delta)
		throttle += source.throttle
		steer += source.steer
		horn = horn or source.horn
	throttle = clampf(throttle, -1.0, 1.0)
	steer = clampf(steer, -1.0, 1.0)
