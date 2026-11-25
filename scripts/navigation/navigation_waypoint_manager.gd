class_name NavigationWaypointManager
extends Node
## Manages a route as ordered data; only the active waypoint is presented to the player.

signal route_changed(active_waypoint: NavigationWaypoint)

@export var registry_path: NodePath
@export var coordinate_system_path: NodePath

var _route: Array[NavigationWaypoint] = []
var _active_index: int = 0
var _registry: NavigationTargetRegistry
var _coordinates: SpaceCoordinateSystem


func _ready() -> void:
	_registry = get_node_or_null(registry_path) as NavigationTargetRegistry
	_coordinates = get_node_or_null(coordinate_system_path) as SpaceCoordinateSystem
	if _registry == null or _coordinates == null:
		push_error("NavigationWaypointManager: registry and coordinate system paths are required.")


func set_waypoint(position: SpatialPosition, display_name: String = "WAYPOINT") -> bool:
	if position == null or _coordinates == null or _coordinates.convert_position(position, position.frame_id) == null:
		return false
	var waypoint := NavigationWaypoint.new()
	waypoint.id = &"manual_waypoint"
	waypoint.display_name = display_name
	waypoint.position = position.duplicate_position()
	set_route([waypoint])
	return true


func set_waypoint_to_target(target_id: StringName) -> bool:
	if _registry == null:
		return false
	var target := _registry.get_target(target_id)
	if target == null or not target.is_available():
		return false
	var waypoint := NavigationWaypoint.new()
	waypoint.id = StringName("target_" + String(target_id))
	waypoint.display_name = target.display_name
	waypoint.target_id = target_id
	waypoint.position = target.resolve_position()
	set_route([waypoint])
	return true


func set_route(waypoints: Array[NavigationWaypoint]) -> void:
	_route.clear()
	for waypoint in waypoints:
		if waypoint != null and waypoint.position != null:
			_route.append(waypoint)
	_active_index = 0
	route_changed.emit(get_active_waypoint())


func advance_waypoint() -> bool:
	if _active_index + 1 >= _route.size():
		return false
	_active_index += 1
	route_changed.emit(get_active_waypoint())
	return true


func clear_waypoint() -> void:
	if _route.is_empty():
		return
	_route.clear()
	_active_index = 0
	route_changed.emit(null)


func get_active_waypoint() -> NavigationWaypoint:
	if _active_index < 0 or _active_index >= _route.size():
		return null
	var waypoint := _route[_active_index]
	if waypoint.target_id != &"":
		var target := _registry.get_target(waypoint.target_id) if _registry != null else null
		if target == null or not target.is_available():
			clear_waypoint()
			return null
		waypoint.position = target.resolve_position()
	return waypoint


func get_waypoint_count() -> int:
	return _route.size()
