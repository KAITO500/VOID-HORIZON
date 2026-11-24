class_name ShipIntent
extends RefCounted
## What a pilot WANTS the ship to do this frame (decision D-009, proposed).
##
## Human input, AI and network packets all fill the same object; the ship only reads it.
## Phase 03: filled by FlightInput (human) and consumed by FlightController. Axes: pitch + = nose up,
## yaw + = nose right, roll + = roll right, throttle + = forward.

var throttle: float = 0.0     # -1..1
var pitch: float = 0.0        # -1..1
var yaw: float = 0.0          # -1..1
var roll: float = 0.0         # -1..1
var boost: bool = false
var brake: bool = false
var assist: bool = true       # flight assist (lateral damping) on/off
var fire_primary: bool = false


func reset() -> void:
	throttle = 0.0
	pitch = 0.0
	yaw = 0.0
	roll = 0.0
	boost = false
	brake = false
	fire_primary = false


func to_dictionary() -> Dictionary:
	return {
		"throttle": throttle, "pitch": pitch, "yaw": yaw, "roll": roll,
		"boost": boost, "brake": brake, "assist": assist, "fire_primary": fire_primary,
	}


func apply_dictionary(data: Dictionary) -> void:
	throttle = data.get("throttle", 0.0)
	pitch = data.get("pitch", 0.0)
	yaw = data.get("yaw", 0.0)
	roll = data.get("roll", 0.0)
	boost = data.get("boost", false)
	brake = data.get("brake", false)
	assist = data.get("assist", true)
	fire_primary = data.get("fire_primary", false)
