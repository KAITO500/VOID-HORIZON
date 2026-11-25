extends SceneTree
## Functional checks for Phase 04 coordinates, live telemetry, POIs, targeting and waypoints.

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _check_coordinates()
	var flight_scene := load("res://scenes/flight/flight_test.tscn") as PackedScene
	_check(flight_scene != null, "F5 flight scene loads with navigation components")
	if flight_scene == null:
		_finish()
		return
	var flight := flight_scene.instantiate()
	root.add_child(flight)
	await process_frame
	await physics_frame

	var ship := flight.get_node("LightFighter") as Spaceship
	var navigation := flight.get_node("SpaceNavigation")
	var telemetry := navigation.get_node("Telemetry") as NavigationTelemetry
	var coordinates := navigation.get_node("Coordinates") as SpaceCoordinateSystem
	var registry := navigation.get_node("Registry") as NavigationTargetRegistry
	var target_manager := navigation.get_node("TargetManager") as NavigationTargetManager
	var waypoints := navigation.get_node("WaypointManager") as NavigationWaypointManager
	var hud := flight.get_node("FlightHud") as FlightHud
	var overlay := flight.get_node("NavigationHud/Overlay") as NavigationHudOverlay

	_check(telemetry.snapshot != null, "telemetry captures a live ship sample")
	_check(registry.get_target_count() == 4, "testbed registers three POIs and the Phase 05 planet")
	_check(registry.get_targets(NavigationTarget.Category.PLANET).size() == 1, "Phase 05 planet is available through the existing navigation category")
	_check(telemetry.snapshot.position.frame_id == SpaceCoordinateSystem.ROOT_FRAME, "ship position is tagged with the universe frame")
	_check(InputMap.has_action(&"navigation_target_next") and InputMap.has_action(&"navigation_waypoint_set"), "navigation bindings register without replacing flight controls")
	_check(target_manager.cycle_target(1), "target manager selects the next visible POI")
	var first_cycle_id := target_manager.selected_target_id
	_check(target_manager.cycle_target(1) and target_manager.selected_target_id != first_cycle_id, "target manager can change the selected POI")
	target_manager.clear_target()
	_check(target_manager.get_selected_target() == null, "target selection can be cancelled")

	ship.velocity = Vector3(3.0, 4.0, -12.0)
	var sample := telemetry.capture_now()
	_check(is_equal_approx(sample.speed_mps, 13.0), "speed matches the real velocity magnitude")
	_check(sample.movement_direction.is_equal_approx(ship.velocity.normalized()), "movement direction is distinct telemetry")
	_check(is_equal_approx(sample.forward_speed_mps, 12.0), "signed forward speed uses the ship's actual axis")
	ship.velocity = Vector3(20.0, 0.0, 0.0)
	sample = telemetry.capture_now()
	_check(sample.movement_direction.dot(sample.forward) < 0.01, "motion vector remains separate from facing direction")

	ship.global_basis = Basis(Vector3.UP, deg_to_rad(-90.0))
	sample = telemetry.capture_now()
	_check(sample.heading_valid and is_equal_approx(sample.heading_degrees, 90.0), "heading follows full 3D ship orientation")
	ship.global_basis = Basis(Vector3.RIGHT, PI * 0.5)
	sample = telemetry.capture_now()
	_check(not sample.heading_valid and absf(sample.pitch_degrees - 90.0) < 0.01, "vertical nose reports undefined compass heading and valid pitch")
	_check(is_finite(sample.roll_degrees), "orientation telemetry stays finite at the vertical singularity")
	ship.global_basis = Basis.IDENTITY
	ship.global_position = Vector3.ZERO
	ship.velocity = Vector3(0.0, 0.0, -150.0)
	sample = telemetry.capture_now()

	var target := _make_target(&"test_station", "TEST STATION", Vector3(0.0, 0.0, -1000.0), NavigationTarget.Category.STATION)
	_check(registry.register_target(target), "POI registration succeeds")
	_check(not registry.register_target(target), "duplicate POI IDs are rejected")
	_check(registry.get_target(&"test_station") == target, "POI lookup returns its data object")
	_check(registry.get_targets(NavigationTarget.Category.STATION).has(target), "POI categories can be filtered")
	_check(is_equal_approx(coordinates.distance_between(sample.position, target.position), 1000.0), "distance to POI is measured in meters")
	_check(coordinates.direction_between(sample.position, target.position).is_equal_approx(Vector3(0.0, 0.0, -1.0)), "direction to POI is expressed in the ship's world frame")
	_check(target_manager.select_target(&"test_station"), "target selection succeeds")
	_check(target_manager.get_selected_target() == target, "selected target is queryable")
	_check(not target_manager.select_target(&"missing_target"), "unknown targets cannot be selected")
	hud._process(0.0)
	_check((hud.get("_target_name") as Label).text == "TEST STATION", "HUD displays the selected registered target")
	_check((hud.get("_target_distance") as Label).text.begins_with("1.0 KM"), "HUD displays live target distance and relative direction")
	_check((hud.get("_speed_value") as Label).text == "SPEED  150 M/S", "HUD speed is driven by navigation telemetry")
	hud._update_target_metrics(sample.position, sample)
	_check((hud.get("_target_distance") as Label).text == "DESTINATION REACHED", "coincident destination is not mistaken for invalid data")
	hud._process(0.0)

	var marker_before := overlay.project_target_position(target)
	_check(marker_before != Vector2.INF, "on-screen POI produces a navigation marker")
	ship.global_position.x = 180.0
	ship.reset_physics_interpolation()
	telemetry.capture_now()
	await physics_frame
	await process_frame
	var marker_after := overlay.project_target_position(target)
	_check(marker_after != Vector2.INF and not marker_after.is_equal_approx(marker_before), "POI marker updates when ship/camera moves")

	_check(waypoints.set_waypoint_to_target(&"test_station"), "selected POI can become the active waypoint")
	_check(waypoints.get_active_waypoint().target_id == &"test_station", "target waypoint follows the POI ID")
	var custom_position := coordinates.make_world_position(Vector3(100.0, 40.0, -500.0))
	_check(waypoints.set_waypoint(custom_position, "MANUAL DESTINATION"), "manual waypoint can replace the active destination")
	_check(waypoints.get_active_waypoint().display_name == "MANUAL DESTINATION", "waypoint replacement updates route state")
	var route: Array[NavigationWaypoint] = [
		_make_waypoint(&"route_a", Vector3(0.0, 0.0, -250.0)),
		_make_waypoint(&"route_b", Vector3(0.0, 0.0, -500.0)),
	]
	waypoints.set_route(route)
	_check(waypoints.get_waypoint_count() == 2, "waypoint manager accepts an ordered multi-point route")
	_check(waypoints.advance_waypoint() and waypoints.get_active_waypoint().id == &"route_b", "route advances to the next waypoint")
	waypoints.clear_waypoint()
	_check(waypoints.get_active_waypoint() == null, "waypoint route can be removed")
	registry.unregister_target(&"test_station")
	_check(target_manager.get_selected_target() == null, "unregistering the selected POI clears selection")
	_check(waypoints.set_waypoint_to_target(&"relay_k07"), "a live POI can be set as a waypoint after target selection is cleared")
	hud._process(0.0)
	_check((hud.get("_target_name") as Label).text == "WAYPOINT  /  RELAY K-07", "HUD promotes the active waypoint when no target is selected")
	_check((hud.get("_target_distance") as Label).text != "SELECT A DESTINATION", "HUD shows distance for an active waypoint")
	waypoints.clear_waypoint()

	var hidden := _make_target(&"hidden_station", "HIDDEN", Vector3(0.0, 0.0, -50.0), NavigationTarget.Category.STATION)
	hidden.navigation_visible = false
	_check(registry.register_target(hidden), "hidden POI can remain registered")
	_check(not target_manager.select_target(hidden.id), "hidden POI cannot be selected")
	var node_target := _make_target(&"moving_target", "MOVING", Vector3.ZERO, NavigationTarget.Category.SPACE_OBJECT)
	var moving_node := Node3D.new()
	flight.add_child(moving_node)
	_check(registry.register_node_target(node_target, moving_node), "node-backed dynamic POI can be registered")
	_check(node_target.resolve_position().coordinates.is_equal_approx(moving_node.global_position), "dynamic POI resolves its current scene position")
	_check(target_manager.select_target(node_target.id), "live node-backed POI can be selected")
	moving_node.free()
	_check(not node_target.is_available(), "freed POI source becomes unavailable")
	_check(target_manager.get_selected_target() == null, "selected POI clears when its source node disappears")
	_check(not target_manager.select_target(node_target.id), "unavailable POI cannot be selected")

	flight.free()
	_finish()


func _check_coordinates() -> void:
	var coordinates := SpaceCoordinateSystem.new()
	root.add_child(coordinates)
	await process_frame
	_check(coordinates.register_frame(&"sol", SpaceCoordinateSystem.ROOT_FRAME, Transform3D(Basis.IDENTITY, Vector3(1000.0, 0.0, 0.0))), "system frame registers beneath universe")
	_check(coordinates.register_frame(&"moon", &"sol", Transform3D(Basis.IDENTITY, Vector3(0.0, 200.0, 0.0))), "nested planetary frame registers")
	var local_point := SpatialPosition.new()
	local_point.frame_id = &"moon"
	local_point.coordinates = Vector3(0.0, 0.0, -300.0)
	var converted := coordinates.convert_position(local_point, SpaceCoordinateSystem.ROOT_FRAME)
	_check(converted != null and converted.coordinates.is_equal_approx(Vector3(1000.0, 200.0, -300.0)), "nested frames convert to universe coordinates")
	var root_point := coordinates.make_world_position(Vector3.ZERO)
	_check(is_equal_approx(coordinates.distance_between(root_point, local_point), Vector3(1000.0, 200.0, -300.0).length()), "distance converts frames before measuring")
	_check(coordinates.convert_position(local_point, &"unknown") == null, "unknown coordinate frames fail safely")
	_check(not coordinates.register_frame(&"invalid", &"unknown", Transform3D.IDENTITY), "frames with missing parents are rejected")
	coordinates.free()


func _make_target(id: StringName, label: String, location: Vector3, kind: NavigationTarget.Category) -> NavigationTarget:
	var target := NavigationTarget.new()
	target.id = id
	target.display_name = label
	target.category = kind
	target.position = SpatialPosition.new()
	target.position.frame_id = SpaceCoordinateSystem.ROOT_FRAME
	target.position.coordinates = location
	return target


func _make_waypoint(id: StringName, location: Vector3) -> NavigationWaypoint:
	var waypoint := NavigationWaypoint.new()
	waypoint.id = id
	waypoint.display_name = String(id).to_upper()
	waypoint.position = SpatialPosition.new()
	waypoint.position.frame_id = SpaceCoordinateSystem.ROOT_FRAME
	waypoint.position.coordinates = location
	return waypoint


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + label)


func _finish() -> void:
	print("phase04_navigation_check: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)
