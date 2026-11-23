class_name SpaceEnvironment
extends Node3D
## Root of the space environment. Owns the WorldEnvironment (sky, ambient, tonemap, glow) and
## wires the independent layers together. It contains no layer logic itself.
##
## Expected children (see scenes/environment/space_environment.tscn):
##   WorldEnvironment, StarLightingController, StarField, NebulaLayer (1+), CelestialBackdrop.
## Place this node at the origin with identity rotation.

const SKY_SHADER: Shader = preload("res://assets/materials/space/space_sky.gdshader")
const FAR_PLANE_MARGIN: float = 1.1

@export_group("Sky")
@export var zenith_color: Color = Color(0.012, 0.028, 0.075)
@export var horizon_color: Color = Color(0.004, 0.009, 0.028)

@export_group("Rendering")
@export_range(0.0, 3.0, 0.05) var ambient_energy: float = 1.0
@export_range(0.25, 4.0, 0.05) var tonemap_exposure: float = 1.0
@export var glow_enabled: bool = true
@export_range(0.0, 2.0, 0.05) var glow_intensity: float = 0.8

var star_field: StarField
var nebula_layers: Array[NebulaLayer] = []
var backdrop: CelestialBackdrop
var lighting: StarLightingController

var _world_environment: WorldEnvironment
var _environment: Environment
var _sky_material: ShaderMaterial


func _ready() -> void:
	_collect_layers()
	_build_environment()
	if lighting != null:
		lighting.bind_sky_material(_sky_material)
	_check_camera.call_deferred()


## Minimum camera far plane needed to see every layer.
func get_required_far_plane() -> float:
	var extent: float = 0.0
	if star_field != null:
		extent = maxf(extent, star_field.radius * (1.0 + star_field.radius_jitter))
	for layer in nebula_layers:
		extent = maxf(extent, layer.radius)
	if backdrop != null:
		extent = maxf(extent, backdrop.get_max_distance())
	return extent * FAR_PLANE_MARGIN


func set_glow_enabled(value: bool) -> void:
	glow_enabled = value
	if _environment != null:
		_environment.glow_enabled = value


func _collect_layers() -> void:
	_world_environment = get_node_or_null("WorldEnvironment") as WorldEnvironment
	for child in get_children():
		if child is StarField:
			star_field = child as StarField
		elif child is NebulaLayer:
			nebula_layers.append(child as NebulaLayer)
		elif child is CelestialBackdrop:
			backdrop = child as CelestialBackdrop
		elif child is StarLightingController:
			lighting = child as StarLightingController


func _build_environment() -> void:
	_sky_material = ShaderMaterial.new()
	_sky_material.shader = SKY_SHADER
	_sky_material.set_shader_parameter("zenith_color", zenith_color)
	_sky_material.set_shader_parameter("horizon_color", horizon_color)

	var sky := Sky.new()
	sky.sky_material = _sky_material

	_environment = Environment.new()
	_environment.background_mode = Environment.BG_SKY
	_environment.sky = sky
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_environment.ambient_light_energy = ambient_energy
	_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_environment.tonemap_exposure = tonemap_exposure
	# Glow only catches HDR-bright pixels (sun, brightest stars). Toggle off to save GPU time.
	_environment.glow_enabled = glow_enabled
	_environment.glow_intensity = glow_intensity
	_environment.glow_hdr_threshold = 1.0

	if _world_environment == null:
		_world_environment = WorldEnvironment.new()
		_world_environment.name = "WorldEnvironment"
		add_child(_world_environment)
	_world_environment.environment = _environment


func _check_camera() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var required: float = get_required_far_plane()
	if camera.far < required:
		push_warning(
			"SpaceEnvironment: camera far plane (%d) is smaller than the %d needed to show every layer."
			% [int(camera.far), int(required)])
