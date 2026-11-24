class_name FlightBoost
extends RefCounted
## Boost energy, cooldown and smoothed strength. No nodes; unit-testable and server-friendly.
##
## energy 1.0 = full tank. Holding boost drains it over `boost_duration` seconds. When it reaches
## zero boost is locked until `boost_unlock_fraction` has recharged. `strength` (0..1) is the
## smoothed value that scales speed/acceleration and drives the engine visuals.

var energy: float = 1.0
var strength: float = 0.0
var active: bool = false
var locked: bool = false
var _idle_time: float = 0.0
var _needs_release: bool = false   # after running dry the key must be released once


func update(wants_boost: bool, delta: float, config: FlightConfig) -> void:
	if not wants_boost:
		_needs_release = false
	active = wants_boost and not locked and not _needs_release and energy > 0.0
	if active:
		_idle_time = 0.0
		energy -= delta / maxf(config.boost_duration, 0.01)
		if energy <= 0.0:
			energy = 0.0
			locked = true
			_needs_release = true
			active = false
	else:
		_idle_time += delta
		if _idle_time >= config.boost_recharge_delay:
			energy += delta / maxf(config.boost_recharge_time, 0.01)
	energy = clampf(energy, 0.0, 1.0)
	if locked and energy >= config.boost_unlock_fraction:
		locked = false
	var ramp: float = config.boost_ramp_up if active else config.boost_ramp_down
	strength = move_toward(strength, 1.0 if active else 0.0, ramp * delta)


func reset() -> void:
	energy = 1.0
	strength = 0.0
	active = false
	locked = false
	_needs_release = false
	_idle_time = 0.0
