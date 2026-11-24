class_name FlightCamera
extends Camera3D
## Third-person chase camera for a Spaceship. Smooth, no shake.
##
## Orientation lags the ship (so turns feel weighty) while the position stays glued to the ship
## (no world-space position lag, so the ship never drifts on screen at 400 m/s).
## Speed effects are limited to a small FOV widening and a small pull-back.
## Uses the ship's interpolated transform in _process (physics interpolation, Godot 4.7).

@export var ship_path: NodePath
@export_group("Follow")
@export_range(5.0, 80.0, 0.5) var follow_distance: float = 26.0
@export_range(0.0, 30.0, 0.5) var follow_height: float = 6.5
@export_range(0.0, 200.0, 1.0) var look_ahead: float = 45.0
## Orientation follow rate (1/s). Lower = lazier camera, higher = glued to the ship.
@export_range(0.5, 30.0, 0.1) var rotation_follow_rate: float = 5.0
@export_group("Speed effects (subtle)")
@export_range(30.0, 120.0, 0.5) var base_fov: float = 70.0
@export_range(0.0, 30.0, 0.5) var speed_fov_gain: float = 6.0
@export_range(0.0, 30.0, 0.5) var boost_fov_gain: float = 6.0
@export_range(0.0, 30.0, 0.5) var speed_pullback: float = 4.0
@export_range(0.5, 20.0, 0.1) var effect_response: float = 2.5

var _ship: Spaceship
var _controller: FlightController
var _rotation: Quaternion = Quaternion.IDENTITY
var _speed_effect: float = 0.0
var _boost_effect: float = 0.0
var _needs_snap: bool = true


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	current = true
	if not ship_path.is_empty():
		set_ship(get_node_or_null(ship_path) as Spaceship)


func set_ship(ship: Spaceship) -> void:
	_ship = ship
	_controller = null
	if _ship != null:
		_controller = _ship.get_node_or_null("FlightController") as FlightController
		# Call once now so Godot creates the interpolation pump before the first reset.
		_ship.get_global_transform_interpolated()
	_needs_snap = true


func snap_to_ship() -> void:
	_needs_snap = true


func _process(delta: float) -> void:
	if _ship == null:
		return
	var ship_tf: Transform3D = _ship.get_global_transform_interpolated()
	var ship_basis: Basis = ship_tf.basis.orthonormalized()
	if _needs_snap:
		_rotation = ship_basis.get_rotation_quaternion()
		_needs_snap = false
	else:
		_rotation = _rotation.slerp(ship_basis.get_rotation_quaternion(), FlightMath.smooth_factor(rotation_follow_rate, delta))

	var speed_target: float = 0.0
	var boost_target: float = 0.0
	if _controller != null:
		speed_target = clampf(_controller.get_speed_ratio(), 0.0, 1.0)
		boost_target = _controller.boost.strength
	var effect_factor: float = FlightMath.smooth_factor(effect_response, delta)
	_speed_effect = lerpf(_speed_effect, speed_target, effect_factor)
	_boost_effect = lerpf(_boost_effect, boost_target, effect_factor)

	var anchor_local: Vector3 = _ship.camera_target.position if _ship.camera_target != null else Vector3.ZERO
	var anchor: Vector3 = ship_tf * anchor_local
	var smoothed_basis := Basis(_rotation)
	var distance: float = follow_distance + speed_pullback * maxf(_speed_effect, _boost_effect)
	var position_world: Vector3 = anchor + smoothed_basis * Vector3(0.0, follow_height, distance)
	var look_point: Vector3 = anchor - ship_basis.z * look_ahead

	var to_target: Vector3 = look_point - position_world
	if to_target.length_squared() > 0.0001:
		var up: Vector3 = smoothed_basis.y
		if absf(to_target.normalized().dot(up)) > 0.99:
			up = smoothed_basis.x
		global_transform = Transform3D(Basis.looking_at(to_target, up), position_world)
	fov = base_fov + speed_fov_gain * _speed_effect + boost_fov_gain * _boost_effect
