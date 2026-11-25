class_name PlanetaryApproachSnapshot
extends RefCounted
## Read-only-by-convention planetary approach data shared with HUD/navigation.

var planet_id: StringName = &""
var planet_name: String = ""
var distance_to_center_m: float = 0.0
var altitude_m: float = 0.0
var distance_to_atmosphere_m: float = 0.0
var direction_to_planet: Vector3 = Vector3.ZERO
var atmosphere_progress: float = 0.0
var approach_progress: float = 0.0
var state: int = 0
var state_name: String = "SPACE"
