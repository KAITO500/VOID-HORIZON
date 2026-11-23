class_name DebugFreeCamera
extends Camera3D
## Development-only free camera for inspecting environments. NOT the gameplay camera.
##
## Hold right mouse button: mouse look.  Arrow keys: look (touchpad friendly).
## WASD: move, Q/E: down/up, Shift: faster.  Uses raw keys, so no InputMap changes are needed.

@export var look_sensitivity: float = 0.003
@export var arrow_turn_speed: float = 1.2
@export var move_speed: float = 3000.0
@export var fast_multiplier: float = 6.0

var _yaw: float = 0.0
var _pitch: float = 0.0


func _ready() -> void:
	current = true
	_yaw = rotation.y
	_pitch = rotation.x


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_RIGHT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if button.pressed else Input.MOUSE_MODE_VISIBLE
		return
	var motion := event as InputEventMouseMotion
	if motion != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= motion.relative.x * look_sensitivity
		_pitch -= motion.relative.y * look_sensitivity
		_apply_rotation()


func _process(delta: float) -> void:
	var turn: Vector2 = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_LEFT):
		turn.x += 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT):
		turn.x -= 1.0
	if Input.is_physical_key_pressed(KEY_UP):
		turn.y += 1.0
	if Input.is_physical_key_pressed(KEY_DOWN):
		turn.y -= 1.0
	if turn != Vector2.ZERO:
		_yaw += turn.x * arrow_turn_speed * delta
		_pitch += turn.y * arrow_turn_speed * delta
		_apply_rotation()

	var move: Vector3 = Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		move -= basis.z
	if Input.is_physical_key_pressed(KEY_S):
		move += basis.z
	if Input.is_physical_key_pressed(KEY_A):
		move -= basis.x
	if Input.is_physical_key_pressed(KEY_D):
		move += basis.x
	if Input.is_physical_key_pressed(KEY_E):
		move += Vector3.UP
	if Input.is_physical_key_pressed(KEY_Q):
		move -= Vector3.UP
	if move != Vector3.ZERO:
		var speed: float = move_speed
		if Input.is_physical_key_pressed(KEY_SHIFT):
			speed *= fast_multiplier
		global_position += move.normalized() * speed * delta


func reset_view() -> void:
	global_position = Vector3.ZERO
	_yaw = 0.0
	_pitch = 0.0
	_apply_rotation()


func _apply_rotation() -> void:
	_pitch = clampf(_pitch, -PI * 0.5 + 0.01, PI * 0.5 - 0.01)
	rotation = Vector3(_pitch, _yaw, 0.0)
