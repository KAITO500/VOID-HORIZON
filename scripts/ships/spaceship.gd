class_name Spaceship
extends CharacterBody3D
## Generic spaceship entity: ties together config, attachment points, visuals and network state.
##
## NO flight logic here (Phase 03 lives in scripts/flight/: FlightInput fills `intent`, FlightController moves this body). The root is a CharacterBody3D provisionally (D-019): arcade
## flight sets velocity directly. If Phase 03 prefers RigidBody3D, only this root type changes;
## CollisionShape3D children, markers and visuals stay as they are.
##
## Expected children (see scenes/ships/light_fighter.tscn):
##   VisualRoot/ShipModel, VisualRoot/EngineVisuals, CollisionShape3D nodes, CameraTarget,
##   EnginePoints/*, WeaponPoints/*, MultiplayerSyncRoot.
## Marker3D convention: an attachment marker's -Z axis is its emission/firing direction.

@export var config: ShipConfig

## What the pilot wants (human, AI or network). Consumed by FlightController (Phase 03).
var intent: ShipIntent = ShipIntent.new()

@onready var visual_root: Node3D = get_node_or_null("VisualRoot")
@onready var engine_visuals: ShipEngineVisuals = get_node_or_null("VisualRoot/EngineVisuals") as ShipEngineVisuals
@onready var camera_target: Marker3D = get_node_or_null("CameraTarget") as Marker3D
@onready var engine_points: Node3D = get_node_or_null("EnginePoints")
@onready var weapon_points: Node3D = get_node_or_null("WeaponPoints")
@onready var network_state: ShipNetworkState = get_node_or_null("MultiplayerSyncRoot") as ShipNetworkState


func _ready() -> void:
	# Space has no "up", so the character body must not treat any direction as floor.
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	for problem in validate():
		push_warning("Spaceship '%s': %s" % [name, problem])


func get_engine_point(point_name: String) -> Marker3D:
	if engine_points == null:
		return null
	return engine_points.get_node_or_null(point_name) as Marker3D


func get_weapon_point(point_name: String) -> Marker3D:
	if weapon_points == null:
		return null
	return weapon_points.get_node_or_null(point_name) as Marker3D


func get_engine_points() -> Array[Marker3D]:
	return _markers_in(engine_points)


func get_weapon_points() -> Array[Marker3D]:
	return _markers_in(weapon_points)


func get_collision_shapes() -> Array[CollisionShape3D]:
	var shapes: Array[CollisionShape3D] = []
	for child in get_children():
		var shape := child as CollisionShape3D
		if shape != null:
			shapes.append(shape)
	return shapes


## World-space transform of the point a future camera should follow.
func get_camera_target_transform() -> Transform3D:
	if camera_target != null:
		return camera_target.global_transform
	return global_transform


## Presentation hook: drives engine glow. Gameplay calls this; visuals never call back.
func set_visual_thrust(value: float) -> void:
	if engine_visuals != null:
		engine_visuals.set_thrust(value)


## Bounding box of the visible model in ship-root space (empty AABB if there are no meshes).
func get_model_aabb() -> AABB:
	var model: Node = get_node_or_null("VisualRoot/ShipModel")
	var result := AABB()
	if model == null:
		return result
	var inverse: Transform3D = global_transform.affine_inverse()
	var first: bool = true
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		var box: AABB = (inverse * mesh_node.global_transform) * mesh_node.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result


## Presentation hook: boost glow/flame stretch (0..1).
func set_visual_boost(value: float) -> void:
	if engine_visuals != null:
		engine_visuals.set_boost(value)


## Returns human-readable problems with this ship's setup (empty array = OK).
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if config == null:
		problems.append("config is not assigned")
	else:
		for point_name in config.engine_point_names:
			if get_engine_point(point_name) == null:
				problems.append("missing engine point '%s'" % point_name)
		for point_name in config.weapon_point_names:
			if get_weapon_point(point_name) == null:
				problems.append("missing weapon point '%s'" % point_name)
	var model_box: AABB = get_model_aabb()
	if model_box.size != Vector3.ZERO and (model_box.size.z < model_box.size.y or model_box.size.z < model_box.size.x * 0.8):
		problems.append("model orientation looks wrong: extents %s (length must be along Z, height Y, nose -Z)" % model_box.size)
	if camera_target == null:
		problems.append("missing CameraTarget")
	if network_state == null:
		problems.append("missing MultiplayerSyncRoot")
	if get_collision_shapes().is_empty():
		problems.append("no CollisionShape3D children")
	return problems


func _markers_in(parent: Node3D) -> Array[Marker3D]:
	var markers: Array[Marker3D] = []
	if parent == null:
		return markers
	for child in parent.get_children():
		var marker := child as Marker3D
		if marker != null:
			markers.append(marker)
	return markers
