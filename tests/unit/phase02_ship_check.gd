extends SceneTree
## Headless sanity check for the Light Fighter (Phase 02).
##
## Run after the project was imported once (so class_name scripts are registered):
##   godot --headless --path . --import
##   godot --headless --path . -s res://tests/unit/phase02_ship_check.gd
## Exit code 0 = all checks passed.

var _failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_mesh("fuselage", ShipHullBuilder.fuselage(), Vector3(3.2, 2.0, 18.2), 0.6)
	_check_mesh("wings", ShipHullBuilder.wings(), Vector3(15.1, 1.0, 7.7), 0.6)
	_check_mesh("nacelles", ShipHullBuilder.nacelles(), Vector3(7.5, 1.5, 8.0), 0.6)
	_check_has_geometry("canopy", ShipHullBuilder.canopy())
	_check_has_geometry("canards", ShipHullBuilder.canards())
	_check_has_geometry("fins", ShipHullBuilder.fins())
	_check_has_geometry("accents", ShipHullBuilder.accents())

	var scene: PackedScene = load("res://scenes/ships/light_fighter.tscn")
	_check(scene != null, "light_fighter.tscn loads")
	if scene != null:
		var ship := scene.instantiate() as Spaceship
		_check(ship != null, "root is a Spaceship")
		if ship != null:
			root.add_child(ship)
			await process_frame
			var problems: PackedStringArray = ship.validate()
			_check(problems.is_empty(), "ship validates (%s)" % "; ".join(problems))
			_check(ship.get_engine_points().size() == 2, "two engine points")
			_check(ship.get_weapon_points().size() == 2, "two weapon points")
			_check(ship.get_collision_shapes().size() == 4, "four collision shapes")
			_check(ship.network_state != null and ship.network_state.is_owned_locally(), "offline owner is local")
			var ship_model := ship.get_node_or_null("VisualRoot/ShipModel") as Node3D
			_check(ship_model != null, "ShipModel visual instance exists")
			if ship_model != null:
				var model_meshes := ship_model.find_children("*", "MeshInstance3D", true, false)
				_check(not model_meshes.is_empty(), "imported GLB has visible mesh parts")
				var model_bounds := _model_bounds(ship_model)
				_check(
					_size_matches(model_bounds.size, Vector3(15.2, 3.5, 19.0), 0.6),
					"GLB bounds align with ship axes (X span, Y height, Z length): %s" % model_bounds.size)
				var nose_center := _named_mesh_center(ship_model, "NOSE")
				var engine_center := _named_mesh_center(ship_model, "ENGINE")
				_check(nose_center.z < engine_center.z, "nose faces -Z and engines sit toward +Z")

	print("phase02_ship_check: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: %s" % label)


## Compares mesh bounding-box size with an expected size within a tolerance (per axis).
func _check_mesh(label: String, mesh: ArrayMesh, expected: Vector3, tolerance: float) -> void:
	var size: Vector3 = mesh.get_aabb().size
	var ok: bool = (
		absf(size.x - expected.x) <= tolerance
		and absf(size.y - expected.y) <= tolerance
		and absf(size.z - expected.z) <= tolerance)
	_check(ok, "%s size %s expected about %s" % [label, size, expected])


func _check_has_geometry(label: String, mesh: ArrayMesh) -> void:
	_check(mesh.get_surface_count() == 1 and mesh.get_aabb().size.length() > 0.5, "%s has geometry" % label)


func _model_bounds(model: Node3D) -> AABB:
	var bounds := AABB()
	var has_bounds := false
	for candidate in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := candidate as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var world_bounds: AABB = mesh_instance.global_transform * mesh_instance.get_aabb()
		bounds = world_bounds if not has_bounds else bounds.merge(world_bounds)
		has_bounds = true
	return bounds


func _named_mesh_center(model: Node3D, name_fragment: String) -> Vector3:
	var center := Vector3.ZERO
	var count := 0
	for candidate in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := candidate as MeshInstance3D
		if mesh_instance != null and name_fragment in mesh_instance.name.to_upper():
			center += mesh_instance.global_position
			count += 1
	return center / float(maxi(count, 1))


func _size_matches(actual: Vector3, expected: Vector3, tolerance: float) -> bool:
	return (
		absf(actual.x - expected.x) <= tolerance
		and absf(actual.y - expected.y) <= tolerance
		and absf(actual.z - expected.z) <= tolerance)

