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
	assert(hud.get("_identity") is Control, "open identity group must be built")
	assert(hud.get("_heading_ribbon") is Control, "heading scale must be built")
	assert(hud.get("_speed_value") is Label, "speed readout must be built")
	assert(hud.get("_surface_viewport") is SubViewport, "HUD surfaces must render through a 3D viewport")
	assert(hud.get("_surface_camera") is Camera3D, "HUD must have a separate pilot presentation camera")
	var spatial_panels: Array = hud.get("_surface_panels")
	assert(spatial_panels.size() >= 8, "each HUD instrument must have an independent spatial surface")
	var surface_root := hud.get("_surface_root") as Node3D
	var navigation_surface := surface_root.get_node("NavigationSpatialPanel") as MeshInstance3D
	var navigation_uvs: PackedVector2Array = navigation_surface.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	assert(navigation_uvs[2].y < navigation_uvs[0].y, "SubViewport text must be upright on the 3D panels")
	var radii: Array[float] = []
	for panel: Dictionary in spatial_panels:
		if not radii.has(float(panel["radius"])):
			radii.append(float(panel["radius"]))
	assert(radii.size() >= 3, "primary, secondary and peripheral groups must occupy three depths")
	assert(is_equal_approx(hud.get("_reticle").screen_point.x, 38.0), "reticle must stay centered on its own front plane")
	root.size = Vector2i(1280, 720)
	await process_frame
	assert(hud.get("_surface_viewport").size == Vector2i(1280, 720), "3D display must fit 720p output")
	root.size = Vector2i(1600, 900)
	await process_frame
	assert(hud.get("_surface_viewport").size == Vector2i(1600, 900), "3D display must fit 900p output")
	root.size = Vector2i(1920, 1080)
	await process_frame
	assert(hud.get("_surface_viewport").size == Vector2i(1920, 1080), "3D display must use its reference resolution")
	root.size = Vector2i(2560, 1440)
	await process_frame
	assert(hud.get("_surface_viewport").size == Vector2i(2560, 1440), "3D display must adapt to 1440p output")
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
	assert(is_equal_approx((hud.get("_throttle_bar") as ProgressBar).value, 0.62), "engine bar must use live network state")
	assert(is_equal_approx((hud.get("_boost_bar") as ProgressBar).value, 0.5), "boost meter must use live reserve")
	assert((hud.get("_boost_value") as Label).text == "BOOST ENGAGED", "boost state must be reflected")

	var preview_scene := load("res://scenes/flight/flight_hud_preview.tscn") as PackedScene
	assert(preview_scene != null, "preview scene must load")
	var front_view := (load("res://scenes/flight/flight_hud_front_view.tscn") as PackedScene).instantiate()
	assert(not front_view.get("three_quarter_view"), "front presentation scene must use the pilot-facing view")
	var three_quarter_view := (load("res://scenes/flight/flight_hud_three_quarter_view.tscn") as PackedScene).instantiate()
	assert(three_quarter_view.get("three_quarter_view"), "three-quarter presentation scene must expose the concave display")
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
	preview_hud.set_presentation_view(true)
	assert((preview_hud.get("_surface_camera") as Camera3D).position.x > 0.0, "three-quarter view must move the spatial presentation camera")
	preview_hud.set_presentation_view(false)
	assert((preview_hud.get("_surface_camera") as Camera3D).position == Vector3.ZERO, "front view must restore the pilot camera")

	print("phase03_hud_check: PASS")
	quit()


func _key_event(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event



