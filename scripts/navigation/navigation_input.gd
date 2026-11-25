class_name NavigationInput
extends Node
## Small local navigation bindings; flight controls remain owned by FlightInput.

@export var target_manager_path: NodePath
@export var waypoint_manager_path: NodePath

var _targets: NavigationTargetManager
var _waypoints: NavigationWaypointManager


func _ready() -> void:
	_targets = get_node_or_null(target_manager_path) as NavigationTargetManager
	_waypoints = get_node_or_null(waypoint_manager_path) as NavigationWaypointManager
	_register_actions()
	if _targets == null or _waypoints == null:
		push_error("NavigationInput requires target and waypoint managers.")


func _unhandled_input(event: InputEvent) -> void:
	if _targets == null or _waypoints == null:
		return
	if event.is_action_pressed(&"navigation_target_next"):
		_targets.cycle_target(1)
	elif event.is_action_pressed(&"navigation_target_previous"):
		_targets.cycle_target(-1)
	elif event.is_action_pressed(&"navigation_target_clear"):
		_targets.clear_target()
	elif event.is_action_pressed(&"navigation_waypoint_set"):
		var target := _targets.get_selected_target()
		if target != null:
			_waypoints.set_waypoint_to_target(target.id)
	elif event.is_action_pressed(&"navigation_waypoint_clear"):
		_waypoints.clear_waypoint()


func _register_actions() -> void:
	_add_key_action(&"navigation_target_next", KEY_TAB)
	_add_key_action(&"navigation_target_previous", KEY_TAB, true)
	_add_key_action(&"navigation_target_clear", KEY_BACKSPACE)
	_add_key_action(&"navigation_waypoint_set", KEY_ENTER)
	_add_key_action(&"navigation_waypoint_clear", KEY_DELETE)


func _add_key_action(action: StringName, key: Key, shift: bool = false) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.2)
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.shift_pressed = shift
	InputMap.action_add_event(action, event)
