class_name StarLightingController
extends DirectionalLight3D
## Single key light for the primary distant star, plus the matching sun in the sky shader.
##
## One DirectionalLight3D stands in for the whole universe's lighting: distant stars never get
## real-time lights of their own. Nearby illuminated objects (planets, ships, stations) are lit
## by this light. Shadows are off by default (cost); enable them when ships need them.
## Assumes the parent chain has identity rotation.

@export_group("Star direction (where the star is in the sky)")
@export_range(-180.0, 180.0, 0.1) var star_yaw_deg: float = 55.0
@export_range(-85.0, 85.0, 0.1) var star_pitch_deg: float = 18.0

@export_group("Light")
@export var star_color: Color = Color(1.0, 0.86, 0.68)
@export_range(0.0, 8.0, 0.05) var star_energy: float = 1.8

@export_group("Sky sun")
@export_range(0.1, 5.0, 0.05) var sun_disc_radius_deg: float = 0.6
@export_range(0.0, 8.0, 0.1) var sun_disc_energy: float = 8.0
@export_range(1.0, 30.0, 0.5) var sun_halo_size_deg: float = 7.0
@export_range(0.0, 3.0, 0.05) var sun_halo_energy: float = 0.55

var _sky_material: ShaderMaterial


func _ready() -> void:
	shadow_enabled = false
	apply()


## Direction from the scene toward the star.
func get_star_direction() -> Vector3:
	return SkyMath.direction_from_angles(star_yaw_deg, star_pitch_deg)


## Registers the sky material so the visible sun matches this light.
func bind_sky_material(sky_material: ShaderMaterial) -> void:
	_sky_material = sky_material
	apply()


func apply() -> void:
	var to_star: Vector3 = get_star_direction()
	light_color = star_color
	light_energy = star_energy
	# A DirectionalLight3D shines along its local -Z, so aim it away from the star.
	basis = Basis.looking_at(-to_star, Vector3.UP)

	if _sky_material == null:
		return
	_sky_material.set_shader_parameter("sun_direction", to_star)
	_sky_material.set_shader_parameter("sun_color", star_color)
	_sky_material.set_shader_parameter("sun_radius", deg_to_rad(sun_disc_radius_deg))
	_sky_material.set_shader_parameter("sun_disc_energy", sun_disc_energy)
	_sky_material.set_shader_parameter("sun_halo_size", deg_to_rad(sun_halo_size_deg))
	_sky_material.set_shader_parameter("sun_halo_energy", sun_halo_energy)
