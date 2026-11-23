extends SceneTree
## Headless sanity check for Phase 01 math helpers.
##
## Run (after the project was imported once, so class_name scripts are registered):
##   godot --headless --path . --import
##   godot --headless --path . -s res://tests/unit/phase01_math_check.gd
## Exit code 0 = all checks passed.

var _failures: int = 0


func _init() -> void:
	_check_vec(SkyMath.direction_from_angles(0.0, 0.0), Vector3(0.0, 0.0, -1.0), "yaw0 pitch0 = -Z")
	_check_vec(SkyMath.direction_from_angles(90.0, 0.0), Vector3(1.0, 0.0, 0.0), "yaw90 = +X")
	_check_vec(SkyMath.direction_from_angles(0.0, 90.0), Vector3(0.0, 1.0, 0.0), "pitch90 = +Y")
	_check_float(SkyMath.direction_from_angles(37.0, 21.0).length(), 1.0, "direction is unit length")

	var radius: float = CelestialBody.radius_from_angular(80000.0, 28.0)
	_check_float(radius, 80000.0 * tan(deg_to_rad(14.0)), "radius from angular size")
	_check_float(CelestialBody.angular_diameter_from_radius(radius, 80000.0), 28.0, "angular size round trip")

	_check_float(SkyMath.band_normal(0.0).y, 1.0, "band normal untilted = +Y")
	_check_float(SkyMath.band_normal(35.0).length(), 1.0, "band normal is unit length")

	print("phase01_math_check: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _check_float(actual: float, expected: float, label: String) -> void:
	if absf(actual - expected) > 0.001:
		_failures += 1
		printerr("FAIL %s: got %f expected %f" % [label, actual, expected])


func _check_vec(actual: Vector3, expected: Vector3, label: String) -> void:
	if not actual.is_equal_approx(expected):
		_failures += 1
		printerr("FAIL %s: got %s expected %s" % [label, actual, expected])
