class_name ShipInspectionCamera
extends Camera3D
## Orbit camera for inspecting a ship. Development tool, NOT the gameplay camera.
##
## Right mouse drag: orbit. Mouse wheel: zoom. Presets are set by the inspection scene.
## Orbit angles use SkyMath: yaw 0 = camera in FRONT of the ship (ship front is -Z), yaw 90 = right
## side, yaw 180 = rear.

@export var target: Vector3 = Vector3.ZERO
@export_range(5.0, 200.0, 0.5) var distance: float = 34.0
@export var orbit_sensitivity: float = 0.3

var yaw_deg: float = 150.0
var pitch_deg: float = -8.0


func _ready() -> void:
	current = true
	_apply()


func set_view(new_yaw_deg: float, new_pitch_deg: float, new_distance: float) -> void:
	yaw_deg = new_yaw_deg
	pitch_deg = new_pitch_deg
	distance = new_distance
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null and (motion.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0:
		yaw_deg -= motion.relative.x * orbit_sensitivity
		pitch_deg = clampf(pitch_deg + motion.relative.y * orbit_sensitivity, -85.0, 85.0)
		_apply()
		return
	var button := event as InputEventMouseButton
	if button != null and button.pressed:
		if button.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(distance * 0.9, 5.0)
			_apply()
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(distance * 1.1, 200.0)
			_apply()


func _apply() -> void:
	if not is_inside_tree():
		return
	global_position = target + SkyMath.direction_from_angles(yaw_deg, pitch_deg) * distance
	look_at(target, Vector3.UP)
