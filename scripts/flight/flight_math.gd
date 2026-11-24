class_name FlightMath
extends RefCounted
## Pure flight math (no nodes, no input). Static so it can be unit-tested headless and reused by
## AI or by a future server-side simulation. All smoothing is frame-rate independent (exp decay).
##
## Ship convention (D-022): forward = -Z, up = +Y, right = +X. Intent: pitch + = nose up,
## yaw + = nose right, roll + = roll right (clockwise seen from behind).


## Frame-rate independent smoothing factor for a rate in 1/s.
static func smooth_factor(rate: float, delta: float) -> float:
	return 1.0 - exp(-maxf(rate, 0.0) * delta)


## Requested angular velocity in ship-local axes (rad/s). x = pitch, y = yaw, z = roll.
static func target_angular_velocity(config: FlightConfig, pitch: float, yaw: float, roll: float, speed_ratio: float) -> Vector3:
	var scale: float = 1.0 - config.speed_turn_penalty * clampf(speed_ratio, 0.0, 1.0)
	var pitch_in: float = -pitch if config.invert_pitch else pitch
	return Vector3(
		deg_to_rad(config.pitch_rate_deg) * clampf(pitch_in, -1.0, 1.0) * scale,
		deg_to_rad(config.yaw_rate_deg) * -clampf(yaw, -1.0, 1.0) * scale,
		deg_to_rad(config.roll_rate_deg) * -clampf(roll, -1.0, 1.0) * scale)


static func step_angular_velocity(current: Vector3, target: Vector3, response: float, delta: float) -> Vector3:
	return current.lerp(target, smooth_factor(response, delta))


## Rotates a basis by a LOCAL-space angular velocity for delta seconds. Result is orthonormal.
static func apply_rotation(basis: Basis, angular_velocity: Vector3, delta: float) -> Basis:
	var angle: float = angular_velocity.length() * delta
	if angle < 0.000001:
		return basis.orthonormalized()
	var step := Basis(angular_velocity.normalized(), angle)
	return (basis * step).orthonormalized()


## Maximum forward speed for a boost strength in 0..1.
static func max_speed_for(config: FlightConfig, boost_strength: float) -> float:
	return config.max_speed * lerpf(1.0, config.boost_speed_multiplier, clampf(boost_strength, 0.0, 1.0))


## One velocity step. `throttle` -1..1 (already smoothed), `assist` toggles lateral damping.
static func step_velocity(velocity: Vector3, forward: Vector3, throttle: float, brake: bool, assist: bool,
		boost_strength: float, config: FlightConfig, delta: float) -> Vector3:
	var result: Vector3 = velocity
	if brake:
		var speed: float = result.length()
		if speed > 0.0:
			result *= maxf(speed - config.brake_deceleration * delta, 0.0) / speed
		return _cap(result, config)

	var boost: float = clampf(boost_strength, 0.0, 1.0)
	var v_max: float = max_speed_for(config, boost)
	var accel: float = config.acceleration * lerpf(1.0, config.boost_acceleration_multiplier, boost)
	var forward_speed: float = result.dot(forward)
	var lateral: Vector3 = result - forward * forward_speed

	if assist:
		lateral *= exp(-config.lateral_damping * delta)

	if absf(throttle) < 0.001:
		forward_speed *= exp(-config.idle_drag * delta)
	else:
		var target: float = v_max * throttle if throttle > 0.0 else v_max * config.reverse_speed_fraction * throttle
		var difference: float = target - forward_speed
		var rate: float
		if difference > 0.0:
			rate = accel
		elif throttle > 0.0:
			rate = config.overspeed_deceleration
		else:
			rate = config.deceleration
		var band: float = maxf(v_max * config.approach_band, 0.001)
		var taper: float = clampf(absf(difference) / band, config.min_taper, 1.0)
		forward_speed = move_toward(forward_speed, target, rate * taper * delta)

	return _cap(forward * forward_speed + lateral, config)


static func _cap(velocity: Vector3, config: FlightConfig) -> Vector3:
	return velocity.limit_length(config.hard_speed_cap)
