class_name ActionInputSource
extends InputSource
## Tastatur und Gamepad über die Actions aus KraxlInput (ADR 0009).
## Analoge Werte (Stick, Trigger) kommen stufenlos durch, Knöpfe als 0 oder 1.


func _init() -> void:
	KraxlInput.setup()


func update(_delta: float) -> void:
	throttle = Input.get_action_strength(KraxlInput.FORWARD) - Input.get_action_strength(KraxlInput.BACKWARD)
	steer = Input.get_action_strength(KraxlInput.RIGHT) - Input.get_action_strength(KraxlInput.LEFT)
