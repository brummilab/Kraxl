class_name BotInputSource
extends InputSource
## Deterministische Eingabe für den Fahrbot: Liste aus Schritten {duration, throttle, steer}.
## Nach dem letzten Schritt bleiben Gas und Lenkung auf 0.

var _steps: Array[Dictionary] = []
var _index := 0
var _time_in_step := 0.0


func _init(steps: Array[Dictionary] = []) -> void:
	_steps = steps


func update(delta: float) -> void:
	if _index >= _steps.size():
		throttle = 0.0
		steer = 0.0
		return
	var step := _steps[_index]
	throttle = step.get("throttle", 0.0)
	steer = step.get("steer", 0.0)
	_time_in_step += delta
	if _time_in_step >= step.get("duration", 0.0):
		_time_in_step = 0.0
		_index += 1


func is_finished() -> bool:
	return _index >= _steps.size()
