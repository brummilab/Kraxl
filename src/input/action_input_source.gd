class_name ActionInputSource
extends InputSource
## Tastatur und Gamepad über die Actions aus KraxlInput (ADR 0009).
## Analoge Werte (Stick, Trigger) kommen stufenlos durch, Knöpfe als 0 oder 1.
## `player` = -1: alle Tasten und alle Gamepads (Ein-Spieler). 0 oder 1: Zwei-Spieler-Modus mit
## eigener Tastenhälfte und eigenem Gamepad (das erste bzw. zweite angeschlossene, ADR 0012).

var player := -1


func _init(for_player := -1) -> void:
	player = for_player
	KraxlInput.setup()


func update(_delta: float) -> void:
	throttle = _strength(KraxlInput.FORWARD) - _strength(KraxlInput.BACKWARD)
	steer = _strength(KraxlInput.RIGHT) - _strength(KraxlInput.LEFT)
	horn = _strength(KraxlInput.HORN) > 0.5
	light = _strength(KraxlInput.LIGHTS) > 0.5
	tool = _strength(KraxlInput.TOOL)


func _strength(action: StringName) -> float:
	if player < 0:
		return Input.get_action_strength(action)
	return maxf(
		Input.get_action_strength(KraxlInput.player_action(action, player)),
		KraxlInput.pad_strength(action, KraxlInput.player_pad(player))
	)
