extends Node3D
## Flight test bed: the Light Fighter flying through the Phase 01 environment.
## Development tool. Builds a short slalom of gates so speed and turning are easy to judge.
## Keys (besides the flight controls): R reset ship to the start.

const GATE_COUNT: int = 18
const GATE_SPACING: float = 420.0
const GATE_RADIUS: float = 55.0

@onready var _ship: Spaceship = $LightFighter
@onready var _camera: FlightCamera = $FlightCamera
@onready var _environment: SpaceEnvironment = $SpaceEnvironment

var _start_transform: Transform3D


func _ready() -> void:
	_camera.far = maxf(_camera.far, _environment.get_required_far_plane())
	_start_transform = _ship.global_transform
	_build_gates()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_R:
		reset_ship()


func reset_ship() -> void:
	_ship.global_transform = _start_transform
	_ship.velocity = Vector3.ZERO
	_ship.reset_physics_interpolation()
	var controller := _ship.get_node_or_null("FlightController") as FlightController
	if controller != null:
		controller.throttle = 0.0
		controller.angular_velocity = Vector3.ZERO
		controller.boost.reset()
	_camera.snap_to_ship()


func _build_gates() -> void:
	var cyan := _make_gate_material(Color(0.25, 0.85, 0.8))
	var amber := _make_gate_material(Color(1.0, 0.6, 0.2))
	var mesh := TorusMesh.new()
	mesh.inner_radius = GATE_RADIUS - 1.5
	mesh.outer_radius = GATE_RADIUS
	mesh.rings = 48
	mesh.ring_segments = 8
	var holder := Node3D.new()
	holder.name = "Gates"
	add_child(holder)
	for i in GATE_COUNT:
		var gate := MeshInstance3D.new()
		gate.mesh = mesh
		gate.material_override = amber if i % 5 == 4 else cyan
		gate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Torus axis is Y; rotate so the hole faces the flight direction (Z).
		gate.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		var phase: float = float(i)
		gate.position = Vector3(sin(phase * 0.7) * 140.0, cos(phase * 0.5) * 80.0, -GATE_SPACING * float(i + 1))
		holder.add_child(gate)


func _make_gate_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material
