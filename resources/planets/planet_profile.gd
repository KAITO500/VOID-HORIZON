class_name PlanetProfile
extends Resource
## Tunable data for a non-procedural planetary destination.

@export var planet_id: StringName = &""
@export var display_name: String = "UNNAMED WORLD"
@export var available: bool = true

@export_group("Scale (metres)")
@export_range(100.0, 10000000.0, 10.0) var radius_m: float = 24000.0
@export_range(100.0, 2000000.0, 10.0) var atmosphere_height_m: float = 6000.0
@export_range(1.1, 100.0, 0.1) var approach_radius_ratio: float = 8.0
@export_range(1.01, 20.0, 0.1) var orbital_radius_ratio: float = 2.5
@export_range(0.0, 100000.0, 10.0) var boundary_hysteresis_m: float = 350.0
@export_range(0.05, 0.49, 0.01) var transition_start_progress: float = 0.25
@export_range(0.51, 0.95, 0.01) var active_start_progress: float = 0.78

@export_group("Surface")
@export var surface_color: Color = Color("77746d")
@export var surface_roughness: float = 0.92

@export_group("Atmosphere")
@export var atmosphere_color: Color = Color("c58a5c")
@export_range(0.0, 2.0, 0.01) var atmosphere_density: float = 0.42
@export_range(0.5, 8.0, 0.1) var atmosphere_rim_power: float = 2.4
@export_range(0.0, 1.0, 0.01) var sky_blend_strength: float = 0.2


func get_atmosphere_radius_m() -> float:
	return radius_m + atmosphere_height_m


func get_approach_radius_m() -> float:
	return radius_m * approach_radius_ratio


func get_orbital_radius_m() -> float:
	return radius_m * orbital_radius_ratio
