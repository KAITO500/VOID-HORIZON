class_name FlightController
extends Node
## Flight physics for one Spaceship: reads `ship.intent`, moves the ship. No input handling here.
##
## Child of the Spaceship root (node name "FlightController"). The same node serves human, AI and
## (later) remote ships: only the peer that owns the ship simulates it (see _is_simulating()).
## Math lives in FlightMath / FlightBoost so it can be tested without a scene.

signal boost_state_changed(active: bool, locked: bool)

## Optional override. Empty = use `ship.config.flight_config`.
@export var config_override: FlightConfig

var boost: FlightBoost = FlightBoost.new()
## Smoothed throttle actually applied (-1..1).
var throttle: float = 0.0
## Local-space angular velocity (rad/s): x pitch, y yaw, z roll.
var angular_velocity: Vector3 = Vector3.ZERO

var _ship: Spaceship
var _last_boost_active: bool = false
var _last_boost_locked: bool = false


func _ready() -> void:
	_ship = get_parent() as Spaceship
	if _ship == null:
		push_error("FlightController must be a child of a Spaceship.")
		set_physics_process(false)
		return
	if get_flight_config() == null:
		push_warning("FlightController: no FlightConfig (set ShipConfig.flight_config). Flight disabled.")
		set_physics_process(false)


func get_flight_config() -> FlightConfig:
	if config_override != null:
		return config_override
	if _ship != null and _ship.config != null:
		return _ship.config.flight_config
	return null


func get_speed() -> float:
	return _ship.velocity.length() if _ship != null else 0.0


## Speed relative to the un-boosted maximum (can exceed 1.0 while boosting).
func get_speed_ratio() -> float:
	var cfg := get_flight_config()
	if cfg == null or _ship == null:
		return 0.0
	return _ship.velocity.length() / maxf(cfg.max_speed, 0.001)


## Signed speed along the ship's forward axis (m/s).
func get_forward_speed() -> float:
	return -_ship.velocity.dot(_ship.global_transform.basis.z) if _ship != null else 0.0


func _physics_process(delta: float) -> void:
	if not _is_simulating():
		return
	var cfg: FlightConfig = get_flight_config()
	var intent: ShipIntent = _ship.intent

	boost.update(intent.boost, delta, cfg)
	if boost.active != _last_boost_active or boost.locked != _last_boost_locked:
		_last_boost_active = boost.active
		_last_boost_locked = boost.locked
		boost_state_changed.emit(boost.active, boost.locked)

	# Throttle: boosting always pushes forward (arcade), otherwise follow the smoothed input.
	var throttle_request: float = 1.0 if boost.active else intent.throttle
	throttle = lerpf(throttle, throttle_request, FlightMath.smooth_factor(cfg.throttle_response, delta))

	# Rotation (ship-local angular velocity, smoothed).
	var speed_ratio: float = get_speed_ratio()
	var target_rates: Vector3 = FlightMath.target_angular_velocity(cfg, intent.pitch, intent.yaw, intent.roll, speed_ratio)
	angular_velocity = FlightMath.step_angular_velocity(angular_velocity, target_rates, cfg.rotation_response, delta)
	_ship.global_transform.basis = FlightMath.apply_rotation(_ship.global_transform.basis, angular_velocity, delta)

	# Translation.
	var forward: Vector3 = -_ship.global_transform.basis.z
	_ship.velocity = FlightMath.step_velocity(_ship.velocity, forward, throttle, intent.brake, intent.assist,
			boost.strength, cfg, delta)
	_ship.move_and_slide()

	_update_feedback()


func _update_feedback() -> void:
	var visual_thrust: float = clampf(0.15 + 0.6 * maxf(throttle, 0.0) + 0.25 * boost.strength, 0.0, 1.0)
	if _ship.network_state != null:
		_ship.network_state.thrust = visual_thrust
	_ship.set_visual_thrust(visual_thrust)
	_ship.set_visual_boost(boost.strength)


## Only the peer that owns the ship simulates it. Offline the local peer owns everything.
func _is_simulating() -> bool:
	if _ship == null:
		return false
	return _ship.network_state == null or _ship.network_state.is_owned_locally()
