class_name InputSource
extends RefCounted
## Gemeinsame Eingabe-Schnittstelle für Touch-UI, Tastatur und Fahrbot (M1).
## Fahrzeuge lesen nur diese Werte, nie direkt OS-Events.

## Gas: -1 (zurück) bis 1 (vor).
var throttle := 0.0
## Lenkung: -1 (links) bis 1 (rechts).
var steer := 0.0


## Wird einmal pro Physik-Tick vom Fahrzeug aufgerufen, bevor es die Werte liest.
func update(_delta: float) -> void:
	pass
