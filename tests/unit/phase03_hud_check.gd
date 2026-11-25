extends SceneTree
## Checks the temporary basic flight HUD and its live flight data.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var flight_scene := load("res://scenes/flight/flight_test.tscn") as PackedScene
	assert(flight_scene != null, "flight test scene must load")
	var flight := flight_scene.instantiate()
	root.add_child(flight)
	await process_frame
	await physics_frame
	var hud := flight.get_node("FlightHud") as FlightHud
	assert(hud != null, "main flight scene must include FlightHud")
	assert(hud.get_node_or_null("SimpleHud/FlightReadout") is PanelContainer, "simple flight panel must be built")
	assert(hud.get_node_or_null("SimpleHud/NavigationReadout") is PanelContainer, "simple navigation panel must be built")
	assert(hud.get_node_or_null("SimpleHud/PlanetReadout") is PanelContainer, "simple planetary panel must be built")
	assert(hud.get_node_or_null("SimpleHud/Reticle") is Control, "stable center reticle must be built")
	assert(hud.get_node_or_null("HudArtworkViewport") == null, "the previous 3D HUD compositor must be removed")
	assert((hud.get("_planetary_state_label") as Label).text != "", "planetary status must be visible")

	var ship := flight.get_node("LightFighter") as Spaceship
	var controller := ship.get_node("FlightController") as FlightController
	ship.velocity = Vector3(0.0, 0.0, -150.0)
	controller.boost.energy = 0.5
	controller.boost.active = true
	ship.network_state.thrust = 0.62
	(flight.get_node("SpaceNavigation/Telemetry") as NavigationTelemetry).capture_now()
	hud._process(0.0)
	assert((hud.get("_speed_value") as Label).text == "SPEED  150 M/S", "speed must use live ship velocity")
	assert((hud.get("_thrust_value") as Label).text == "THRUST  62%", "thrust must use live ship state")
	assert((hud.get("_boost_value") as Label).text == "BOOST  ACTIVE  /  50%", "boost state must be reflected")
	assert((hud.get("_target_name") as Label).text == "NO TARGET SELECTED", "navigation defaults to no selected destination")

	flight.queue_free()
	await process_frame
	print("phase03_hud_check: PASS")
	quit()
