extends SceneTree
## Ensures the dedicated planetary test entry point wires existing flight/navigation services.

const TEST_SCENE: PackedScene = preload("res://scenes/planetary/planetary_approach_test.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var test_root := TEST_SCENE.instantiate()
	root.add_child(test_root)
	await process_frame
	await physics_frame
	var flight := test_root.get_node_or_null("FlightTest")
	var ship := test_root.get_node_or_null("FlightTest/LightFighter") as Spaceship
	var planet := test_root.get_node_or_null("FlightTest/KhepriTestWorld") as PlanetaryBody
	var approach := test_root.get_node_or_null("FlightTest/PlanetaryApproachController") as PlanetaryApproachController
	var valid: bool = flight != null and ship != null and planet != null and approach != null
	if valid:
		valid = approach.snapshot != null and approach.snapshot.planet_id == planet.profile.planet_id
		valid = valid and test_root.get_node_or_null("FlightTest/FlightCamera") is Camera3D
		valid = valid and test_root.get_node_or_null("FlightTest/FlightHud") is FlightHud
	print("PHASE05_PLANETARY_SCENE_CHECK: %s" % ("PASS" if valid else "FAIL"))
	if not valid:
		push_error("Planetary approach test scene is missing or disconnected from existing flight services.")
	quit(0 if valid else 1)
