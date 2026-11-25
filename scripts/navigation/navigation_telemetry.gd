class_name NavigationTelemetry
extends Node
## Publishes real ship state for navigation consumers. Reads only; never changes flight state.

signal telemetry_updated(snapshot: NavigationTelemetrySnapshot)

@export var ship_path: NodePath
@export var coordinate_system_path: NodePath

var snapshot: NavigationTelemetrySnapshot

var _ship: Spaceship
var _coordinates: SpaceCoordinateSystem


func _ready() -> void:
	_ship = get_node_or_null(ship_path) as Spaceship
	_coordinates = get_node_or_null(coordinate_system_path) as SpaceCoordinateSystem
	if _ship == null:
		push_error("NavigationTelemetry: ship_path must resolve to a Spaceship.")
		set_physics_process(false)
		return
	if _coordinates == null:
		push_error("NavigationTelemetry: coordinate_system_path must resolve to SpaceCoordinateSystem.")
		set_physics_process(false)
		return
	capture_now()


func capture_now() -> NavigationTelemetrySnapshot:
	if _ship == null or _coordinates == null:
		return null
	var sample := NavigationTelemetrySnapshot.new()
	var ship_transform: Transform3D = _ship.global_transform
	var basis: Basis = ship_transform.basis.orthonormalized()
	sample.position = _coordinates.make_world_position(ship_transform.origin)
	sample.velocity = _ship.velocity
	sample.speed_mps = _ship.velocity.length()
	sample.movement_direction = _ship.velocity.normalized() if sample.speed_mps > 0.0001 else Vector3.ZERO
	sample.forward = -basis.z
	sample.right = basis.x
	sample.up = basis.y
	sample.orientation = basis.get_rotation_quaternion()
	sample.forward_speed_mps = -_ship.velocity.dot(basis.z)
	var horizontal_forward := Vector3(sample.forward.x, 0.0, sample.forward.z)
	sample.heading_valid = horizontal_forward.length_squared() > 0.0001
	if sample.heading_valid:
		horizontal_forward = horizontal_forward.normalized()
		sample.heading_degrees = wrapf(rad_to_deg(atan2(horizontal_forward.x, -horizontal_forward.z)), 0.0, 360.0)
	sample.pitch_degrees = rad_to_deg(asin(clampf(sample.forward.y, -1.0, 1.0)))
	var level_up := Vector3.UP - sample.forward * Vector3.UP.dot(sample.forward)
	if level_up.length_squared() > 0.0001:
		level_up = level_up.normalized()
		sample.roll_degrees = rad_to_deg(atan2(sample.forward.dot(level_up.cross(sample.up)), level_up.dot(sample.up)))
	else:
		# Heading/roll become singular when nose is vertical; preserve a finite Euler fallback.
		sample.roll_degrees = rad_to_deg(basis.get_euler().z)
	snapshot = sample
	telemetry_updated.emit(snapshot)
	return snapshot


func _physics_process(_delta: float) -> void:
	capture_now()
