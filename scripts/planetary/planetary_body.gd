class_name PlanetaryBody
extends Node3D
## A physical-scale, non-procedural planetary destination with a low-cost atmosphere shell.

const ATMOSPHERE_SHADER: Shader = preload("res://scripts/planetary/planetary_atmosphere.gdshader")

@export var profile: PlanetProfile
@export var navigation_registry_path: NodePath

var _surface: MeshInstance3D
var _atmosphere: MeshInstance3D
var _atmosphere_material: ShaderMaterial
var _navigation_registry: NavigationTargetRegistry
var _registered: bool = false


func _ready() -> void:
	add_to_group("navigation_planets")
	_navigation_registry = get_node_or_null(navigation_registry_path) as NavigationTargetRegistry
	_build_visuals()
	_register_navigation()


func _exit_tree() -> void:
	if _registered and _navigation_registry != null and profile != null:
		_navigation_registry.unregister_target(profile.planet_id)


func set_approach_blend(value: float) -> void:
	if _atmosphere_material != null:
		_atmosphere_material.set_shader_parameter("approach_blend", clampf(value, 0.0, 1.0))


func get_planet_radius_m() -> float:
	return profile.radius_m if profile != null else 0.0


func _build_visuals() -> void:
	if profile == null:
		push_error("PlanetaryBody: assign a PlanetProfile resource.")
		return
	var sphere := SphereMesh.new()
	sphere.radius = profile.radius_m
	sphere.height = profile.radius_m * 2.0
	sphere.radial_segments = 64
	sphere.rings = 32
	_surface = MeshInstance3D.new()
	_surface.name = "PlanetSurface"
	_surface.mesh = sphere
	_surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var surface_material := StandardMaterial3D.new()
	surface_material.albedo_color = profile.surface_color
	surface_material.roughness = profile.surface_roughness
	_surface.material_override = surface_material
	add_child(_surface)

	var atmosphere_mesh := SphereMesh.new()
	atmosphere_mesh.radius = profile.get_atmosphere_radius_m()
	atmosphere_mesh.height = profile.get_atmosphere_radius_m() * 2.0
	atmosphere_mesh.radial_segments = 64
	atmosphere_mesh.rings = 32
	_atmosphere = MeshInstance3D.new()
	_atmosphere.name = "AtmosphereShell"
	_atmosphere.mesh = atmosphere_mesh
	_atmosphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_atmosphere_material = ShaderMaterial.new()
	_atmosphere_material.shader = ATMOSPHERE_SHADER
	_atmosphere_material.set_shader_parameter("atmosphere_color", profile.atmosphere_color)
	_atmosphere_material.set_shader_parameter("density", profile.atmosphere_density)
	_atmosphere_material.set_shader_parameter("rim_power", profile.atmosphere_rim_power)
	_atmosphere_material.set_shader_parameter("approach_blend", 0.0)
	_atmosphere.material_override = _atmosphere_material
	add_child(_atmosphere)


func _register_navigation() -> void:
	if profile == null or _navigation_registry == null or profile.planet_id == &"":
		return
	var target := NavigationTarget.new()
	target.id = profile.planet_id
	target.display_name = profile.display_name
	target.category = NavigationTarget.Category.PLANET
	target.discovered = true
	target.navigation_visible = profile.available
	_registered = _navigation_registry.register_node_target(target, self)
	if not _registered:
		push_warning("PlanetaryBody: could not register '%s' in the navigation registry." % profile.planet_id)
