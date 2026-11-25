class_name FlightBoost
extends RefCounted
## Sustained overdrive state. Holding Shift keeps it active; release ramps it down smoothly.
## No timer or energy pool: traversal time is controlled by the player's input.

var strength: float = 0.0
var active: bool = false


func update(wants_boost: bool, delta: float, config: FlightConfig) -> void:
	active = wants_boost
	var ramp: float = config.boost_ramp_up if active else config.boost_ramp_down
	strength = move_toward(strength, 1.0 if active else 0.0, ramp * delta)


func reset() -> void:
	strength = 0.0
	active = false
