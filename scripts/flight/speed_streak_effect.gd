class_name SpeedStreakEffect
extends ColorRect
## Full-screen, speed-gated radial streaks. Replaces the always-visible space-dust point field.

@export var ship_path: NodePath
@export_range(100.0, 5000.0, 50.0) var start_speed_mps: float = 900.0
@export_range(500.0, 10000.0, 100.0) var full_effect_speed_mps: float = 4200.0
@export_range(0.5, 12.0, 0.1) var response: float = 3.5

var _ship: Spaceship
var _material: ShaderMaterial
var _intensity: float = 0.0
var _last_viewport_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ship = get_node_or_null(ship_path) as Spaceship
	_material = ShaderMaterial.new()
	_material.shader = load("res://assets/materials/space/space_speed_streaks.gdshader") as Shader
	material = _material
	_update_aspect_ratio()


func _process(delta: float) -> void:
	if _ship == null or _material == null:
		return
	var speed_mps: float = _ship.velocity.length()
	var raw: float = clampf(inverse_lerp(start_speed_mps, full_effect_speed_mps, speed_mps), 0.0, 1.0)
	var target: float = raw * raw * (3.0 - 2.0 * raw)
	_intensity = lerpf(_intensity, target, FlightMath.smooth_factor(response, delta))
	_material.set_shader_parameter("intensity", _intensity)
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size != _last_viewport_size:
		_update_aspect_ratio()


func _update_aspect_ratio() -> void:
	if _material == null:
		return
	_last_viewport_size = get_viewport_rect().size
	if _last_viewport_size.y > 0.0:
		_material.set_shader_parameter("aspect_ratio", _last_viewport_size.x / _last_viewport_size.y)
