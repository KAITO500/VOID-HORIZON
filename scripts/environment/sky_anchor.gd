class_name SkyAnchor
extends Node3D
## Base class for distant sky layers (stars, nebulae, celestial backdrop).
##
## Keeps the layer centered on the active camera so it behaves as if infinitely far away.
## follow_factor < 1.0 lets the layer drift slightly as the camera moves (cheap parallax).
## Assumes the SpaceEnvironment (and therefore this node's parent chain) sits at the origin
## with identity rotation.

@export var follow_camera: bool = true
@export_range(0.0, 1.0, 0.001) var follow_factor: float = 1.0


func _init() -> void:
	# Run after cameras and movers so the layer never lags a frame behind.
	process_priority = 100


func _process(_delta: float) -> void:
	if not follow_camera:
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	global_position = camera.global_position * follow_factor
