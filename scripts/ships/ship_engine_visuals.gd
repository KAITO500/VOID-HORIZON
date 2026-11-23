class_name ShipEngineVisuals
extends Node3D
## Engine glow and flame cones, placed at the ship's engine Marker3D nodes.
##
## Presentation only. Gameplay never reads from here; it calls set_thrust(0..1) and the glow follows.
## The Marker3D nodes (EnginePoints/*) stay on the ship root so a replacement model keeps working.
## Exhaust direction convention: an engine marker's -Z axis points where the exhaust goes (+Z of the ship).

@export var engine_points_path: NodePath = ^"../../EnginePoints"
@export var engine_color: Color = Color(0.10, 0.75, 1.0)
@export_range(0.5, 20.0, 0.1) var flame_length: float = 5.0
@export_range(0.1, 2.0, 0.01) var nozzle_radius: float = 0.42
@export_range(0.0, 1.0, 0.01) var thrust: float = 0.35:
	set = set_thrust

var _nozzle_material: StandardMaterial3D
var _flame_material: StandardMaterial3D
var _flame_scalers: Array[Node3D] = []


func _ready() -> void:
	_build()
	_apply_thrust()


func set_thrust(value: float) -> void:
	thrust = clampf(value, 0.0, 1.0)
	_apply_thrust()


func _build() -> void:
	_nozzle_material = StandardMaterial3D.new()
	_nozzle_material.albedo_color = Color.BLACK
	_nozzle_material.emission_enabled = true
	_nozzle_material.emission = engine_color

	_flame_material = StandardMaterial3D.new()
	_flame_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flame_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flame_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_flame_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_flame_material.albedo_color = Color(engine_color.r, engine_color.g, engine_color.b, 0.5)

	var points: Node = get_node_or_null(engine_points_path)
	if points == null:
		push_warning("ShipEngineVisuals: engine points not found at %s" % engine_points_path)
		return
	for child in points.get_children():
		var marker := child as Marker3D
		if marker != null:
			_build_engine(to_local(marker.global_position))


func _build_engine(local_position: Vector3) -> void:
	# Pivot rotated so its local +Y axis points along ship +Z (toward the rear).
	var pivot := Node3D.new()
	pivot.name = "Engine"
	pivot.position = local_position
	pivot.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	add_child(pivot)

	var nozzle_mesh := CylinderMesh.new()
	nozzle_mesh.top_radius = nozzle_radius
	nozzle_mesh.bottom_radius = nozzle_radius
	nozzle_mesh.height = 0.08
	var nozzle := MeshInstance3D.new()
	nozzle.name = "Nozzle"
	nozzle.mesh = nozzle_mesh
	nozzle.material_override = _nozzle_material
	nozzle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pivot.add_child(nozzle)

	# Scaler keeps the flame base fixed at the nozzle while its length changes with thrust.
	var scaler := Node3D.new()
	scaler.name = "FlameScaler"
	pivot.add_child(scaler)
	_flame_scalers.append(scaler)

	var flame_mesh := CylinderMesh.new()
	flame_mesh.top_radius = 0.0
	flame_mesh.bottom_radius = nozzle_radius * 0.9
	flame_mesh.height = flame_length
	var flame := MeshInstance3D.new()
	flame.name = "Flame"
	flame.mesh = flame_mesh
	flame.material_override = _flame_material
	flame.position = Vector3(0.0, flame_length * 0.5, 0.0)
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scaler.add_child(flame)


func _apply_thrust() -> void:
	if _nozzle_material == null:
		return
	_nozzle_material.emission_energy_multiplier = lerpf(2.0, 6.0, thrust)
	_flame_material.albedo_color.a = lerpf(0.25, 0.8, thrust)
	var length_scale: float = lerpf(0.3, 1.0, thrust)
	for scaler in _flame_scalers:
		scaler.scale = Vector3(1.0, length_scale, 1.0)
