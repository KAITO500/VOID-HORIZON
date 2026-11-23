class_name CelestialBody
extends Node3D
## A distant celestial object placed by APPARENT size and direction.
##
## Placement is controlled by three numbers:
##   - direction: yaw_deg / pitch_deg (see SkyMath)
##   - distance:  units from the backdrop origin (the camera)
##   - angular_diameter_deg: how large it looks from there
## World radius is derived: radius = distance * tan(angular_diameter / 2).
## Changing `distance` alone does NOT change how large it looks; change the angular size.
##
## Phase 01 implements GAS_GIANT (banded shader, optional rings) and STAR (emissive).
## Other kinds are simple lit placeholder spheres until their phases arrive.

const GAS_GIANT_SHADER: Shader = preload("res://assets/materials/space/gas_giant.gdshader")
const RING_SHADER: Shader = preload("res://assets/materials/space/planet_ring.gdshader")

enum Kind { GAS_GIANT, ROCKY_PLANET, MOON, STAR, ASTEROID_FIELD, ORBITAL_STRUCTURE }

@export var kind: Kind = Kind.GAS_GIANT

@export_group("Apparent placement")
@export_range(0.1, 90.0, 0.1) var angular_diameter_deg: float = 28.0
@export_range(1000.0, 400000.0, 1.0) var distance: float = 80000.0
@export_range(-180.0, 180.0, 0.1) var yaw_deg: float = -30.0
@export_range(-89.0, 89.0, 0.1) var pitch_deg: float = 6.0
@export_range(-80.0, 80.0, 0.5) var axial_tilt_deg: float = 35.0

@export_group("Gas giant look")
@export var band_color_a: Color = Color(0.06, 0.12, 0.34)
@export var band_color_b: Color = Color(0.30, 0.16, 0.52)
@export var band_color_c: Color = Color(0.30, 0.65, 0.85)
@export_range(1.0, 30.0, 0.5) var band_frequency: float = 9.0
@export_range(0.0, 1.0, 0.01) var turbulence: float = 0.35
@export var atmosphere_color: Color = Color(0.25, 0.60, 1.0)
@export_range(0.0, 3.0, 0.05) var atmosphere_strength: float = 0.55

@export_group("Rings")
@export var rings_enabled: bool = true
## Ring radii as multiples of the planet radius.
@export_range(1.05, 4.0, 0.05) var ring_inner_ratio: float = 1.35
@export_range(1.1, 5.0, 0.05) var ring_outer_ratio: float = 2.3
@export var ring_color: Color = Color(0.55, 0.65, 0.85)
@export_range(0.0, 1.0, 0.01) var ring_opacity: float = 0.55

@export_group("Placeholder / star")
@export var body_color: Color = Color(0.5, 0.5, 0.55)
@export_range(0.0, 16.0, 0.1) var star_emission_energy: float = 4.0

var _pivot: Node3D


## radius = distance * tan(angular_diameter / 2)
static func radius_from_angular(distance_units: float, angular_diameter_degrees: float) -> float:
	return distance_units * tan(deg_to_rad(angular_diameter_degrees) * 0.5)


## Inverse of radius_from_angular, in degrees.
static func angular_diameter_from_radius(radius_units: float, distance_units: float) -> float:
	return rad_to_deg(2.0 * atan(radius_units / distance_units))


func _ready() -> void:
	_build()
	apply_placement()


func get_radius() -> float:
	return radius_from_angular(distance, angular_diameter_deg)


## Apparent diameter in degrees as seen from a world-space point.
func apparent_diameter_deg_from(point: Vector3) -> float:
	var d: float = global_position.distance_to(point)
	return angular_diameter_from_radius(get_radius(), maxf(d, 0.001))


## Positions and scales the body from the apparent-placement settings.
func apply_placement() -> void:
	position = SkyMath.direction_from_angles(yaw_deg, pitch_deg) * distance
	if _pivot != null:
		_pivot.scale = Vector3.ONE * get_radius()
		_pivot.rotation_degrees = Vector3(0.0, 0.0, axial_tilt_deg)


func _build() -> void:
	if _pivot != null:
		remove_child(_pivot)
		_pivot.free()
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)

	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 96
	sphere.rings = 48

	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = sphere
	body.material_override = _make_body_material()
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pivot.add_child(body)

	if kind == Kind.GAS_GIANT and rings_enabled:
		_pivot.add_child(_make_rings())


func _make_body_material() -> Material:
	match kind:
		Kind.GAS_GIANT:
			var material := ShaderMaterial.new()
			material.shader = GAS_GIANT_SHADER
			material.set_shader_parameter("color_a", band_color_a)
			material.set_shader_parameter("color_b", band_color_b)
			material.set_shader_parameter("color_c", band_color_c)
			material.set_shader_parameter("band_frequency", band_frequency)
			material.set_shader_parameter("turbulence", turbulence)
			material.set_shader_parameter("atmosphere_color", atmosphere_color)
			material.set_shader_parameter("atmosphere_strength", atmosphere_strength)
			return material
		Kind.STAR:
			var star := StandardMaterial3D.new()
			star.albedo_color = Color.BLACK
			star.emission_enabled = true
			star.emission = body_color
			star.emission_energy_multiplier = star_emission_energy
			return star
		_:
			var placeholder := StandardMaterial3D.new()
			placeholder.albedo_color = body_color
			placeholder.roughness = 0.9
			return placeholder


func _make_rings() -> MeshInstance3D:
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * ring_outer_ratio * 2.0

	var material := ShaderMaterial.new()
	material.shader = RING_SHADER
	material.set_shader_parameter("ring_color", ring_color)
	material.set_shader_parameter("inner", ring_inner_ratio / ring_outer_ratio)
	material.set_shader_parameter("opacity", ring_opacity)

	var rings := MeshInstance3D.new()
	rings.name = "Rings"
	rings.mesh = plane
	rings.material_override = material
	rings.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return rings
