class_name NavigationWaypoint
extends Resource
## One route point. `target_id` keeps it attached to a moving registered destination when set.

@export var id: StringName = &""
@export var display_name: String = "WAYPOINT"
@export var position: SpatialPosition
@export var target_id: StringName = &""
