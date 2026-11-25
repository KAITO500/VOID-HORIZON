class_name NavigationTelemetrySnapshot
extends RefCounted
## Immutable-by-convention sample captured from the live Spaceship flight state.

var position: SpatialPosition
var velocity: Vector3 = Vector3.ZERO
var speed_mps: float = 0.0
var movement_direction: Vector3 = Vector3.ZERO
var forward: Vector3 = Vector3.FORWARD
var right: Vector3 = Vector3.RIGHT
var up: Vector3 = Vector3.UP
var orientation: Quaternion = Quaternion.IDENTITY
var heading_degrees: float = 0.0
var heading_valid: bool = true
var pitch_degrees: float = 0.0
var roll_degrees: float = 0.0
var forward_speed_mps: float = 0.0
