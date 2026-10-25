class_name KeyboardInputSource
extends InputSource
## Tastatur für Entwickler-Probefahrten am PC (Pfeiltasten oder WASD).


func update(_delta: float) -> void:
	throttle = _axis(KEY_DOWN, KEY_S, KEY_UP, KEY_W)
	steer = _axis(KEY_LEFT, KEY_A, KEY_RIGHT, KEY_D)


func _axis(neg_a: Key, neg_b: Key, pos_a: Key, pos_b: Key) -> float:
	var value := 0.0
	if Input.is_physical_key_pressed(pos_a) or Input.is_physical_key_pressed(pos_b):
		value += 1.0
	if Input.is_physical_key_pressed(neg_a) or Input.is_physical_key_pressed(neg_b):
		value -= 1.0
	return value
