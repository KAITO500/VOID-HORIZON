class_name SpatialPosition
extends Resource
## A position expressed in a named coordinate frame. Coordinates are Godot world units (meters).

@export var frame_id: StringName = &"universe"
@export var coordinates: Vector3 = Vector3.ZERO


func duplicate_position() -> SpatialPosition:
	var copy := SpatialPosition.new()
	copy.frame_id = frame_id
	copy.coordinates = coordinates
	return copy
