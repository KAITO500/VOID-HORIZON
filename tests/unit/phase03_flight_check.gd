extends SceneTree
## Headless sanity check for the Phase 03 flight math, boost and scene wiring.
##
## Run after the project was imported once:
##   godot --headless --path . --import
##   godot --headless --path . -s res://tests/unit/phase03_flight_check.gd
## Exit code 0 = all checks passed. NOT run by the author (no Godot binary was available).

var _failures: int = 0


func _init() -> void:
	var cfg := FlightConfig.new()
	var forward := Vector3(0.0, 0.0, -1.0)

	# Acceleration reaches max speed and never exceeds it, at several frame rates.
	for delta: float in [1.0 / 30.0, 1.0 / 60.0, 1.0 / 144.0]:
		var v := Vector3.ZERO
		var steps: int = int(6.0 / delta)
		for i in steps:
			v = FlightMath.step_velocity(v, forward, 1.0, false, true, 0.0, cfg, delta)
			_check(v.length() <= cfg.max_speed + 0.01, "speed never exceeds max (dt %.4f)" % delta)
		_check(absf(v.length() - cfg.max_speed) < 1.0, "reaches max speed in 6 s (dt %.4f, got %.2f)" % [delta, v.length()])

	# Boost raises the limit, then overspeed decays back.
	var vb := forward * cfg.max_speed
	for i in 300:
		vb = FlightMath.step_velocity(vb, forward, 1.0, false, true, 1.0, cfg, 1.0 / 60.0)
	_check(vb.length() > cfg.max_speed * 1.6, "boost exceeds normal max speed (%.1f)" % vb.length())
	for i in 600:
		vb = FlightMath.step_velocity(vb, forward, 1.0, false, true, 0.0, cfg, 1.0 / 60.0)
	_check(absf(vb.length() - cfg.max_speed) < 1.0, "speed returns to max after boost (%.1f)" % vb.length())

	# Brake stops the ship; hard cap holds.
	var vs := forward * cfg.max_speed
	for i in 240:
		vs = FlightMath.step_velocity(vs, forward, 0.0, true, true, 0.0, cfg, 1.0 / 60.0)
	_check(vs.length() < 0.01, "brake stops the ship")
	var capped := FlightMath.step_velocity(forward * 99999.0, forward, 1.0, false, true, 0.0, cfg, 1.0 / 60.0)
	_check(capped.length() <= cfg.hard_speed_cap + 0.01, "hard speed cap")

	# Flight assist removes sideways drift; assist off keeps it.
	var side := Vector3(100.0, 0.0, 0.0)
	var with_assist := side
	var without_assist := side
	for i in 120:
		with_assist = FlightMath.step_velocity(with_assist, forward, 0.0, false, true, 0.0, cfg, 1.0 / 60.0)
		without_assist = FlightMath.step_velocity(without_assist, forward, 0.0, false, false, 0.0, cfg, 1.0 / 60.0)
	_check(with_assist.length() < 20.0, "assist damps lateral velocity")
	_check(without_assist.length() > with_assist.length(), "assist off drifts more")

	# Rotation: signs and orthonormality (nose up = +pitch, nose right = +yaw).
	var rates := FlightMath.target_angular_velocity(cfg, 1.0, 0.0, 0.0, 0.0)
	var pitched := FlightMath.apply_rotation(Basis.IDENTITY, rates, 0.1)
	_check((-pitched.z).y > 0.0, "positive pitch raises the nose")
	rates = FlightMath.target_angular_velocity(cfg, 0.0, 1.0, 0.0, 0.0)
	var yawed := FlightMath.apply_rotation(Basis.IDENTITY, rates, 0.1)
	_check((-yawed.z).x > 0.0, "positive yaw turns the nose right")
	rates = FlightMath.target_angular_velocity(cfg, 0.0, 0.0, 1.0, 0.0)
	var rolled := FlightMath.apply_rotation(Basis.IDENTITY, rates, 0.1)
	_check(rolled.x.y < 0.0, "positive roll lowers the right wing")
	var spun := Basis.IDENTITY
	for i in 5000:
		spun = FlightMath.apply_rotation(spun, Vector3(1.0, 2.0, 3.0), 1.0 / 60.0)
	_check(absf(spun.determinant() - 1.0) < 0.0001 and spun.is_equal_approx(spun.orthonormalized()), "basis stays orthonormal")

	# Boost energy: drains, locks, needs key release, recharges.
	var boost := FlightBoost.new()
	var t: float = 0.0
	while boost.energy > 0.0 and t < 20.0:
		boost.update(true, 1.0 / 60.0, cfg)
		t += 1.0 / 60.0
	_check(absf(t - cfg.boost_duration) < 0.1, "boost lasts boost_duration (%.2f s)" % t)
	_check(boost.locked, "boost locks when empty")
	for i in 60 * 10:
		boost.update(true, 1.0 / 60.0, cfg)
	_check(not boost.active, "boost stays off while the key is held after running dry")
	boost.update(false, 1.0 / 60.0, cfg)
	for i in 60 * 3:
		boost.update(false, 1.0 / 60.0, cfg)
	boost.update(true, 1.0 / 60.0, cfg)
	_check(boost.active, "boost works again after release and recovery")

	_check_scene()
	print("phase03_flight_check: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _check_scene() -> void:
	var scene: PackedScene = load("res://scenes/flight/flight_test.tscn")
	_check(scene != null, "flight_test.tscn loads")
	if scene == null:
		return
	var root := scene.instantiate()
	var ship := root.get_node_or_null("LightFighter") as Spaceship
	_check(ship != null, "LightFighter is a Spaceship")
	if ship != null:
		_check(ship.config != null and ship.config.flight_config != null, "ship config has a FlightConfig")
		_check(ship.get_node_or_null("FlightController") is FlightController, "FlightController present")
		_check(ship.get_node_or_null("FlightInput") is FlightInput, "FlightInput present")
		# The scene is not added to the tree, so Spaceship's @onready vars are still null here:
		# inspect the EnginePoints node directly instead of ship.get_engine_points().
		var engine_points := ship.get_node_or_null("EnginePoints")
		_check(engine_points != null and engine_points.get_child_count() == 3, "three engine points")
	root.free()


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + label)
