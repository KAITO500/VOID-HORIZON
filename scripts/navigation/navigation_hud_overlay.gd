class_name NavigationHudOverlay
extends Control
## Sparse screen-space POI/waypoint indicators layered over the basic flight HUD.

const MARKER_COLOR := Color("B990EA")
const SELECTED_COLOR := Color("F0C487")
const TEXT_COLOR := Color("E8E0F0")
const MAX_MARKERS: int = 6
const DRAW_INTERVAL: float = 1.0 / 30.0

@export var camera_path: NodePath
@export var telemetry_path: NodePath
@export var registry_path: NodePath
@export var target_manager_path: NodePath
@export var waypoint_manager_path: NodePath
@export var coordinate_system_path: NodePath

var _camera: Camera3D
var _telemetry: NavigationTelemetry
var _registry: NavigationTargetRegistry
var _targets: NavigationTargetManager
var _waypoints: NavigationWaypointManager
var _coordinates: SpaceCoordinateSystem
var _draw_timer: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camera = get_node_or_null(camera_path) as Camera3D
	_telemetry = get_node_or_null(telemetry_path) as NavigationTelemetry
	_registry = get_node_or_null(registry_path) as NavigationTargetRegistry
	_targets = get_node_or_null(target_manager_path) as NavigationTargetManager
	_waypoints = get_node_or_null(waypoint_manager_path) as NavigationWaypointManager
	_coordinates = get_node_or_null(coordinate_system_path) as SpaceCoordinateSystem
	set_process(true)


func _process(delta: float) -> void:
	_draw_timer += delta
	if _draw_timer < DRAW_INTERVAL:
		return
	_draw_timer = 0.0
	queue_redraw()


func _draw() -> void:
	if _camera == null or _registry == null or _telemetry == null or _telemetry.snapshot == null:
		return
	var selected := _targets.get_selected_target() if _targets != null else null
	var targets := _registry.get_targets()
	var ship_pos: SpatialPosition = _telemetry.snapshot.position
	targets.sort_custom(func(a: NavigationTarget, b: NavigationTarget) -> bool:
		return _distance_to(ship_pos, a) < _distance_to(ship_pos, b))
	var shown := 0
	for target in targets:
		if selected != null and target.id == selected.id:
			continue
		if _draw_target_marker(target, false):
			shown += 1
		if shown >= MAX_MARKERS:
			break
	if selected != null:
		_draw_target_marker(selected, true)
	var waypoint := _waypoints.get_active_waypoint() if _waypoints != null else null
	var waypoint_is_selected := waypoint != null and selected != null and waypoint.target_id == selected.id
	if waypoint != null and not waypoint_is_selected:
		var waypoint_pos := _coordinates.convert_position(waypoint.position, _coordinates.ROOT_FRAME) if _coordinates != null else null
		if waypoint_pos != null:
			_draw_marker(waypoint_pos.coordinates, waypoint.display_name, SELECTED_COLOR, true)


func _draw_target_marker(target: NavigationTarget, selected: bool) -> bool:
	var screen_position := project_target_position(target)
	if screen_position.is_equal_approx(Vector2.INF):
		return false
	_draw_screen_marker(screen_position, target.display_name, SELECTED_COLOR if selected else MARKER_COLOR, selected)
	return true


## Shared projection helper, also used by the headless navigation check.
func project_target_position(target: NavigationTarget) -> Vector2:
	if _camera == null or _coordinates == null or target == null:
		return Vector2.INF
	var position := target.resolve_position(SpaceCoordinateSystem.ROOT_FRAME)
	var world_position := _coordinates.convert_position(position, SpaceCoordinateSystem.ROOT_FRAME)
	if world_position == null or _camera.is_position_behind(world_position.coordinates):
		return Vector2.INF
	var point := _camera.unproject_position(world_position.coordinates)
	return point if Rect2(Vector2.ZERO, size).grow(-20.0).has_point(point) else Vector2.INF


func _draw_marker(world_position: Vector3, label: String, color: Color, emphasized: bool) -> bool:
	if _camera.is_position_behind(world_position):
		return false
	var point := _camera.unproject_position(world_position)
	var bounds := Rect2(Vector2.ZERO, size)
	if not bounds.grow(-20.0).has_point(point):
		return false
	_draw_screen_marker(point, label, color, emphasized)
	return true


func _draw_screen_marker(point: Vector2, label: String, color: Color, emphasized: bool) -> void:
	var radius := 6.0 if emphasized else 4.0
	var diamond := PackedVector2Array([
		point + Vector2(0.0, -radius), point + Vector2(radius, 0.0),
		point + Vector2(0.0, radius), point + Vector2(-radius, 0.0),
	])
	draw_colored_polygon(diamond, color)
	if emphasized:
		draw_arc(point, 11.0, 0.0, TAU, 24, color, 1.0, true)
	var text := label.left(24)
	draw_string(ThemeDB.fallback_font, point + Vector2(10.0, 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, TEXT_COLOR)


func _distance_to(origin: SpatialPosition, target: NavigationTarget) -> float:
	if _coordinates == null or origin == null:
		return INF
	return _coordinates.distance_between(origin, target.resolve_position(_coordinates.ROOT_FRAME))
