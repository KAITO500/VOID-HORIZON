class_name StarField
extends SkyAnchor
## Procedural star field rendered as ONE MultiMesh draw call.
##
## Stars are billboarded additive sprites on a very large shell around the camera.
## Size, brightness, color and distribution are generated from a seed, so the sky is
## identical on every client (important for co-op later).

const STAR_SHADER: Shader = preload("res://assets/materials/space/star_field.gdshader")

@export_group("Population")
@export_range(0, 50000, 1) var star_count: int = 4000
@export var seed_value: int = 1337

@export_group("Geometry")
## Shell radius in world units. Must be smaller than the camera far plane.
@export_range(1000.0, 1000000.0, 1.0) var radius: float = 300000.0
## Random +/- fraction applied to each star's distance (only affects depth sorting/parallax).
@export_range(0.0, 0.5, 0.01) var radius_jitter: float = 0.08

@export_group("Size and brightness")
## Apparent diameter of the faintest stars, in degrees of sky. ~0.07 deg is about 1 px at 1080p.
@export_range(0.01, 2.0, 0.01) var min_size_deg: float = 0.07
@export_range(0.01, 2.0, 0.01) var max_size_deg: float = 0.30
## Higher values make most stars dim and only a few bright.
@export_range(1.0, 8.0, 0.1) var brightness_skew: float = 3.0
@export_range(0.0, 4.0, 0.05) var intensity: float = 1.0

@export_group("Distribution")
## Fraction of stars squeezed into a galactic band (0 = uniform sky).
@export_range(0.0, 1.0, 0.01) var band_fraction: float = 0.55
## 0 = razor-thin band, 1 = no squeeze.
@export_range(0.02, 1.0, 0.01) var band_thickness: float = 0.2
@export_range(-90.0, 90.0, 0.5) var band_tilt_deg: float = 35.0

@export_group("Colors")
@export var cool_color: Color = Color(0.75, 0.88, 1.0)
@export var cyan_color: Color = Color(0.55, 0.95, 1.0)
@export var warm_color: Color = Color(1.0, 0.82, 0.60)
@export_range(0.0, 1.0, 0.01) var warm_ratio: float = 0.25
@export_range(0.0, 1.0, 0.01) var cyan_ratio: float = 0.20

var _instance: MultiMeshInstance3D


func _ready() -> void:
	rebuild()


## (Re)generates the star MultiMesh from the current exported settings.
func rebuild() -> void:
	if _instance != null:
		remove_child(_instance)
		_instance.free()
		_instance = null
	if star_count <= 0:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var material := ShaderMaterial.new()
	material.shader = STAR_SHADER
	material.render_priority = -10 # draw before rings/other transparent objects
	material.set_shader_parameter("intensity", intensity)
	quad.material = material

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true # must be set before instance_count
	multimesh.mesh = quad
	multimesh.instance_count = star_count

	var band: Basis = SkyMath.band_basis(band_tilt_deg)
	for i in star_count:
		var direction: Vector3 = _random_direction(rng, band)
		var brightness: float = pow(rng.randf(), brightness_skew)
		var size_deg: float = lerpf(min_size_deg, max_size_deg, sqrt(brightness))
		var distance: float = radius * (1.0 + rng.randf_range(-radius_jitter, radius_jitter))
		var world_size: float = deg_to_rad(size_deg) * distance
		var star_transform := Transform3D(Basis.from_scale(Vector3.ONE * world_size), direction * distance)
		multimesh.set_instance_transform(i, star_transform)

		var tint: Color = _pick_tint(rng)
		multimesh.set_instance_color(i, Color(tint.r, tint.g, tint.b, lerpf(0.25, 1.0, brightness)))

	_instance = MultiMeshInstance3D.new()
	_instance.name = "Stars"
	_instance.multimesh = multimesh
	_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The shell surrounds the camera; never frustum-cull it away.
	_instance.custom_aabb = AABB(Vector3.ONE * -radius * 2.0, Vector3.ONE * radius * 4.0)
	add_child(_instance)


func _random_direction(rng: RandomNumberGenerator, band: Basis) -> Vector3:
	var y: float = rng.randf_range(-1.0, 1.0)
	var angle: float = rng.randf_range(0.0, TAU)
	var ring: float = sqrt(maxf(1.0 - y * y, 0.0))
	var direction := Vector3(ring * cos(angle), y, ring * sin(angle))
	if rng.randf() < band_fraction:
		direction.y *= band_thickness
		direction = (band * direction.normalized())
	return direction.normalized()


func _pick_tint(rng: RandomNumberGenerator) -> Color:
	var roll: float = rng.randf()
	if roll < warm_ratio:
		return warm_color
	if roll < warm_ratio + cyan_ratio:
		return cyan_color
	return cool_color
