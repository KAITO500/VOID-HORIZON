class_name NavigationTarget
extends Resource
## Data-only destination. A live scene node can optionally provide a moving position at runtime.

enum Category { PLANET, STATION, STRUCTURE, SPACE_OBJECT, WAYPOINT }

@export var id: StringName = &""
@export var display_name: String = ""
@export var category: Category = Category.SPACE_OBJECT
@export var position: SpatialPosition
@export var discovered: bool = true
@export var navigation_visible: bool = true

var _node_ref: WeakRef


func bind_node(node: Node3D) -> void:
	_node_ref = weakref(node) if node != null else null


func has_live_node() -> bool:
	if _node_ref == null:
		return false
	var node: Object = _node_ref.get_ref()
	return node is Node3D and is_instance_valid(node) and (node as Node3D).is_inside_tree()


func is_available() -> bool:
	return has_live_node() or (_node_ref == null and position != null)


func resolve_position(root_frame: StringName = &"universe") -> SpatialPosition:
	if _node_ref != null:
		var node: Object = _node_ref.get_ref()
		if not node is Node3D or not is_instance_valid(node) or not (node as Node3D).is_inside_tree():
			return null
		var live := SpatialPosition.new()
		live.frame_id = root_frame
		live.coordinates = (node as Node3D).global_position
		return live
	return position.duplicate_position() if position != null else null
