extends SceneTree
## Headless integration checks for scale, nav registration, ingress/egress and swept transitions.

const FLIGHT_SCENE: PackedScene = preload("res://scenes/flight/flight_test.tscn")

var failures: Array[String] = []
var assertions: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := FLIGHT_SCENE.instantiate()
	root.add_child(world)
	await process_frame
	await physics_frame
	var ship := world.get_node("LightFighter") as Spaceship
	var controller := world.get_node("PlanetaryApproachController") as PlanetaryApproachController
	var planet := world.get_node("KhepriTestWorld") as PlanetaryBody
	var telemetry := world.get_node("SpaceNavigation/Telemetry") as NavigationTelemetry
	var registry := world.get_node("SpaceNavigation/Registry") as NavigationTargetRegistry
	var target_manager := world.get_node("SpaceNavigation/TargetManager") as NavigationTargetManager
	var space_environment := world.get_node("SpaceEnvironment") as SpaceEnvironment
	var camera := world.get_node("FlightCamera") as Camera3D
	var original_camera_fov: float = camera.fov
	var original_forward: Vector3 = ship.global_basis.z
	var center: Vector3 = planet.global_position
	var profile: PlanetProfile = planet.profile
	var events: Array[int] = []
	controller.approach_state_changed.connect(func(_id: StringName, _previous: int, next: int) -> void: events.append(next))

	_check(profile != null and profile.planet_id == &"test_world_01", "PlanetProfile has a stable ID")
	_check(is_equal_approx(profile.get_atmosphere_radius_m(), profile.radius_m + profile.atmosphere_height_m), "Atmosphere radius derives from configured scale")
	var nav_target := registry.get_target(profile.planet_id)
	_check(nav_target != null and nav_target.category == NavigationTarget.Category.PLANET, "Planet registers as a navigation target")
	_check(nav_target != null and target_manager.select_target(profile.planet_id), "Navigation can select the planet")

	_set_ship_distance(ship, center, profile.get_approach_radius_m() + 5000.0)
	var snapshot := controller.capture_now()
	_check(snapshot != null and snapshot.state == PlanetaryApproachController.State.SPACE, "Far-range state is SPACE")
	_check(snapshot != null and is_equal_approx(snapshot.distance_to_center_m, profile.get_approach_radius_m() + 5000.0), "Center distance uses configured planet position")

	_set_ship_distance(ship, center, profile.get_approach_radius_m() - 1000.0)
	snapshot = controller.capture_now()
	_check(snapshot != null and snapshot.state == PlanetaryApproachController.State.PLANET_APPROACH, "Approach state uses radius-relative threshold")
	_check(snapshot != null and is_equal_approx(snapshot.altitude_m, snapshot.distance_to_center_m - profile.radius_m), "Altitude subtracts configured surface radius")

	_set_ship_distance(ship, center, profile.get_orbital_radius_m() - 1200.0)
	snapshot = controller.capture_now()
	_check(snapshot != null and snapshot.state == PlanetaryApproachController.State.ORBITAL_REGION, "Orbital region is detected")

	_set_ship_distance(ship, center, profile.get_atmosphere_radius_m() - profile.atmosphere_height_m * 0.12)
	snapshot = controller.capture_now()
	_check(snapshot != null and snapshot.state == PlanetaryApproachController.State.ATMOSPHERE_ENTRY, "Outer atmosphere entry is detected")
	_check(snapshot != null and snapshot.atmosphere_progress > 0.0 and snapshot.atmosphere_progress < 0.25, "Atmosphere progress begins smoothly")

	_set_ship_distance(ship, center, profile.radius_m + profile.atmosphere_height_m * 0.5)
	snapshot = controller.capture_now()
	_check(snapshot != null and snapshot.state == PlanetaryApproachController.State.ATMOSPHERE_TRANSITION, "Atmosphere transition region is detected")
	_check(snapshot != null and is_equal_approx(snapshot.atmosphere_progress, 0.5), "Atmosphere progress follows configured height")
	_check(space_environment._world_environment.environment.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR, "Existing environment blends into the configured atmosphere")

	_set_ship_distance(ship, center, profile.radius_m + profile.atmosphere_height_m * 0.08)
	var sample_position_before: Vector3 = ship.global_position
	var sample_velocity_before: Vector3 = ship.velocity
	var assist_before: bool = ship.intent.assist
	snapshot = controller.capture_now()
	_check(snapshot != null and snapshot.state == PlanetaryApproachController.State.ATMOSPHERE_ACTIVE, "Inner atmosphere state is detected")
	_check(planet.get_node("AtmosphereShell").material_override.get_shader_parameter("approach_blend") > 0.0, "Atmosphere visual blend responds to approach")
	_check(ship.global_position.is_equal_approx(sample_position_before), "Approach sampling preserves ship position")
	_check(ship.velocity.is_equal_approx(sample_velocity_before) and ship.intent.assist == assist_before, "Approach sampling preserves flight velocity and assist control")

	# Jitter inside the configured hysteresis band must not flap out of the active state.
	for jitter_radius: float in [profile.radius_m + profile.atmosphere_height_m * 0.22, profile.radius_m + profile.atmosphere_height_m * 0.19, profile.radius_m + profile.atmosphere_height_m * 0.22]:
		_set_ship_distance(ship, center, jitter_radius)
		snapshot = controller.capture_now()
	_check(snapshot != null and snapshot.state == PlanetaryApproachController.State.ATMOSPHERE_ACTIVE, "Boundary hysteresis suppresses state chatter")

	_set_ship_distance(ship, center, profile.get_atmosphere_radius_m() + 2000.0)
	snapshot = controller.capture_now()
	_check(snapshot != null and snapshot.state == PlanetaryApproachController.State.ORBITAL_REGION, "Egress returns to orbital state")
	_set_ship_distance(ship, center, profile.get_approach_radius_m() + 5000.0)
	snapshot = controller.capture_now()
	_check(snapshot != null and snapshot.state == PlanetaryApproachController.State.SPACE, "Egress clears the atmosphere without getting stuck")
	_check(planet.get_node("AtmosphereShell").material_override.get_shader_parameter("approach_blend") < 0.01, "Atmosphere visual blend clears on egress")
	_check(space_environment._world_environment.environment.ambient_light_source == Environment.AMBIENT_SOURCE_SKY, "Existing environment restores its space lighting on egress")

	# A single physics interval can cross the whole body and finish in SPACE; swept sphere intersections must report every intermediate band.
	events.clear()
	_set_ship_distance(ship, center, profile.get_approach_radius_m() + 12000.0)
	controller.capture_now()
	_set_ship_distance(ship, center, -(profile.get_approach_radius_m() + 12000.0))
	snapshot = controller.capture_now()
	_check(snapshot != null and snapshot.state == PlanetaryApproachController.State.SPACE, "High-speed traversal finishes in the correct outer state")
	_check(events.has(PlanetaryApproachController.State.ATMOSPHERE_ENTRY) and events.has(PlanetaryApproachController.State.ATMOSPHERE_TRANSITION) and events.has(PlanetaryApproachController.State.ATMOSPHERE_ACTIVE), "High-speed traversal emits intermediate ingress states")
	_check(events.size() >= 10, "High-speed pass-through also emits the egress sequence")

	_check(ship.global_basis.z.is_equal_approx(original_forward), "Approach sampling preserves ship orientation")
	_check(is_equal_approx(camera.fov, original_camera_fov), "Approach sampling preserves the camera")
	_check(telemetry.snapshot != null and telemetry.snapshot.position != null, "Navigation telemetry remains available")
	var elapsed_usec: int = Time.get_ticks_usec()
	for _index: int in range(300):
		controller.capture_now()
	var sample_cost_ms: float = float(Time.get_ticks_usec() - elapsed_usec) / 300.0 / 1000.0
	_check(sample_cost_ms < 2.0, "300 headless samples stay below 2 ms per sample (%.3f ms)" % sample_cost_ms)

	if failures.is_empty():
		print("PHASE05_PLANETARY_APPROACH_CHECK: PASS (%d assertions; 300 samples %.3f ms/sample)" % [assertions, sample_cost_ms])
	else:
		for failure: String in failures:
			push_error(failure)
		print("PHASE05_PLANETARY_APPROACH_CHECK: FAIL (%d/%d)" % [failures.size(), assertions])
	quit(0 if failures.is_empty() else 1)


func _set_ship_distance(ship: Spaceship, center: Vector3, signed_distance: float) -> void:
	ship.global_position = center + Vector3(0.0, 0.0, signed_distance)


func _check(condition: bool, description: String) -> void:
	assertions += 1
	if not condition:
		failures.append(description)
