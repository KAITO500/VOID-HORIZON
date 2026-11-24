extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var flight_scene := load("res://scenes/flight/flight_test.tscn") as PackedScene
	assert(flight_scene != null, "flight test scene must load")
	var flight := flight_scene.instantiate()
	root.add_child(flight)
	await process_frame
	var hud := flight.get_node("FlightHud") as FlightHud
	assert(hud != null, "main flight scene must include FlightHud")
	assert(hud.get("_identity") is PanelContainer, "identity panel must be built")
	assert(hud.get("_heading_ribbon") is Control, "heading scale must be built")
	assert(hud.get("_speed_value") is Label, "speed readout must be built")
	assert(is_equal_approx(hud.get("_root").scale.x, 0.78), "HUD must adapt to the 720p viewport")
	root.size = Vector2i(1920, 1080)
	await process_frame
	assert(is_equal_approx(hud.get("_root").scale.x, 1.0), "HUD must use reference scale at 1080p")
	root.size = Vector2i(2560, 1440)
	await process_frame
	assert(is_equal_approx(hud.get("_root").scale.x, 1.333333), "HUD must adapt to 1440p")
	root.size = Vector2i(1280, 720)
	await process_frame

	var ship := flight.get_node("LightFighter") as Spaceship
	var controller := ship.get_node("FlightController") as FlightController
	ship.velocity = Vector3(0.0, 0.0, -150.0)
	controller.boost.energy = 0.5
	controller.boost.active = true
	ship.network_state.thrust = 0.62
	hud._process(0.0)
	assert((hud.get("_speed_value") as Label).text == "150", "speed must use live ship velocity")
	assert((hud.get("_throttle_value") as Label).text == "62%", "engine output must use live network state")
	assert(is_equal_approx((hud.get("_boost_bar") as ProgressBar).value, 0.5), "boost meter must use live reserve")
	assert((hud.get("_boost_value") as Label).text == "BOOST ENGAGED", "boost state must be reflected")

	var preview_scene := load("res://scenes/flight/flight_hud_preview.tscn") as PackedScene
	assert(preview_scene != null, "preview scene must load")
	var preview := preview_scene.instantiate()
	root.add_child(preview)
	await process_frame
	var preview_hud := preview.get_node("FlightTest/FlightHud") as FlightHud
	assert(preview_hud.visual_preview, "preview scene must enable the mock data mode")
	preview_hud._unhandled_key_input(_key_event(KEY_3))
	preview_hud._process(0.0)
	assert((preview_hud.get("_target_name") as Label).text == "RELAY K-07  ·  MOCK", "target state must be available in preview")
	preview_hud._unhandled_key_input(_key_event(KEY_5))
	preview_hud._process(0.0)
	assert((preview_hud.get("_alert_value") as Label).text.begins_with("CRITICAL"), "critical warning preview must render")

	print("phase03_hud_check: PASS")
	quit()


func _key_event(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event


