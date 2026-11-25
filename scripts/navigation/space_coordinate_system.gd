class_name SpaceCoordinateSystem
extends Node
## Scene-local registry of named, nested reference frames. No floating-origin rebasing is performed.

signal reference_frame_registered(frame_id: StringName)

const ROOT_FRAME: StringName = &"universe"

var _frames: Dictionary = {}


func _ready() -> void:
	_frames[ROOT_FRAME] = {"parent": &"", "to_parent": Transform3D.IDENTITY}


func register_frame(frame_id: StringName, parent_id: StringName, transform_to_parent: Transform3D) -> bool:
	if frame_id == &"" or frame_id == ROOT_FRAME or _frames.has(frame_id) or not _frames.has(parent_id):
		return false
	_frames[frame_id] = {"parent": parent_id, "to_parent": transform_to_parent}
	reference_frame_registered.emit(frame_id)
	return true


func has_frame(frame_id: StringName) -> bool:
	return _frames.has(frame_id)


func make_world_position(world_position: Vector3) -> SpatialPosition:
	var result := SpatialPosition.new()
	result.frame_id = ROOT_FRAME
	result.coordinates = world_position
	return result


## Returns null if either frame is unknown or the frame graph is cyclic/incomplete.
func convert_position(position: SpatialPosition, target_frame: StringName) -> SpatialPosition:
	if position == null:
		return null
	var source_to_root := _transform_to_root(position.frame_id)
	var target_to_root := _transform_to_root(target_frame)
	if not source_to_root.get("valid", false) or not target_to_root.get("valid", false):
		return null
	var source_transform: Transform3D = source_to_root["transform"]
	var target_transform: Transform3D = target_to_root["transform"]
	var target_from_source: Transform3D = target_transform.affine_inverse() * source_transform
	var result := SpatialPosition.new()
	result.frame_id = target_frame
	result.coordinates = target_from_source * position.coordinates
	return result


func distance_between(a: SpatialPosition, b: SpatialPosition) -> float:
	var converted := convert_position(b, a.frame_id) if a != null else null
	return -1.0 if converted == null else a.coordinates.distance_to(converted.coordinates)


## Direction from A toward B, expressed in A's frame. Returns zero for invalid/coincident points.
func direction_between(a: SpatialPosition, b: SpatialPosition) -> Vector3:
	var converted := convert_position(b, a.frame_id) if a != null else null
	if converted == null:
		return Vector3.ZERO
	var offset: Vector3 = converted.coordinates - a.coordinates
	return offset.normalized() if offset.length_squared() > 0.000001 else Vector3.ZERO


func _transform_to_root(frame_id: StringName) -> Dictionary:
	if not _frames.has(frame_id):
		return {"valid": false}
	var current: StringName = frame_id
	var accumulated := Transform3D.IDENTITY
	var visited: Dictionary = {}
	while current != ROOT_FRAME:
		if visited.has(current) or not _frames.has(current):
			return {"valid": false}
		visited[current] = true
		var frame: Dictionary = _frames[current]
		var transform_to_parent: Transform3D = frame["to_parent"]
		var parent_id: StringName = frame["parent"]
		accumulated = transform_to_parent * accumulated
		current = parent_id
	return {"valid": true, "transform": accumulated}
