class_name NebulaLayer
extends SkyAnchor
## One procedural nebula layer: an inside-out sphere with an additive noise shader.
##
## Cost: one full-screen additive pass per layer. Keep layer count low (1-3).
## Different seed_offset values give different nebula shapes from the same shader.

const NEBULA_SHADER: Shader = preload("res://assets/materials/space/nebula_layer.gdshader")

## Sphere radius in world units. Must be smaller than the camera far plane and larger
## than the star shell so nebulae sit behind the stars.
@export_range(1000.0, 1000000.0, 1.0) var radius: float = 350000.0

@export_group("Shape")
@export var seed_offset: Vector3 = Vector3(12.3, 4.5, 7.8)
@export_range(0.5, 8.0, 0.05) var noise_scale: float = 2.2
@export_range(1, 6, 1) var octaves: int = 4
## Noise values below this are empty space. Higher = sparser, subtler nebula.
@export_range(0.0, 1.0, 0.01) var density_threshold: float = 0.52
@export_range(0.01, 1.0, 0.01) var density_softness: float = 0.35

@export_group("Look")
@export_range(0.0, 2.0, 0.01) var intensity: float = 0.35
@export var color_a: Color = Color(0.28, 0.10, 0.55) # violet
@export var color_b: Color = Color(0.05, 0.25, 0.70) # electric blue
@export var color_c: Color = Color(0.0, 0.70, 0.90)  # cyan accent

@export_group("Band")
@export_range(0.0, 1.0, 0.01) var band_strength: float = 0.6
@export_range(0.05, 1.0, 0.01) var band_width: float = 0.5
## Keep equal to StarField.band_tilt_deg so nebulae follow the star band.
@export_range(-90.0, 90.0, 0.5) var band_tilt_deg: float = 35.0
## Render order among transparent objects. Lower draws first (behind).
@export_range(-128, 127, 1) var render_priority: int = -20

var _instance: MeshInstance3D
var _material: ShaderMaterial


func _ready() -> void:
	rebuild()


func rebuild() -> void:
	if _instance != null:
		remove_child(_instance)
		_instance.free()
		_instance = null

	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 48
	sphere.rings = 24

	_material = ShaderMaterial.new()
	_material.shader = NEBULA_SHADER
	_material.render_priority = render_priority
	apply_settings()

	_instance = MeshInstance3D.new()
	_instance.name = "Nebula"
	_instance.mesh = sphere
	_instance.material_override = _material
	_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_instance)


## Pushes the exported values to the shader. Call after changing exports at runtime.
func apply_settings() -> void:
	if _material == null:
		return
	_material.set_shader_parameter("seed_offset", seed_offset)
	_material.set_shader_parameter("noise_scale", noise_scale)
	_material.set_shader_parameter("octaves", octaves)
	_material.set_shader_parameter("threshold", density_threshold)
	_material.set_shader_parameter("softness", density_softness)
	_material.set_shader_parameter("intensity", intensity)
	_material.set_shader_parameter("color_a", color_a)
	_material.set_shader_parameter("color_b", color_b)
	_material.set_shader_parameter("color_c", color_c)
	_material.set_shader_parameter("band_normal", SkyMath.band_normal(band_tilt_deg))
	_material.set_shader_parameter("band_strength", band_strength)
	_material.set_shader_parameter("band_width", band_width)
