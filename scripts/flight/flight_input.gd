class_name FlightInput
extends Node
## Human input -> ShipIntent. No physics here. Add as a child of the player's Spaceship.
##
## Mouse: a virtual stick (pitch/yaw) that recenters. Keyboard: see FlightInputMap.
## Runs before FlightController (lower process_physics_priority) so intent is fresh each tick.

signal help_toggled(visible: bool)

@export var config_override: FlightConfig
@export var capture_mouse_on_start: bool = true

var _ship: Spaceship
var _stick: Vector2 = Vector2.ZERO          # x yaw (+right), y pitch (+up), -1..1
var _key_pitch: float = 0.0
var _key_yaw: float = 0.0
var _key_roll: float = 0.0
var _help_visible: bool = true


func _ready() -> void:
	_ship = get_parent() as Spaceship
	process_physics_priority = -10
	FlightInputMap.ensure_actions()
	if _ship == null:
		push_error("FlightInput must be a child of a Spaceship.")
		set_physics_process(false)
		set_process_unhandled_input(false)
		return
	if capture_mouse_on_start:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _get_config() -> FlightConfig:
	if config_override != null:
		return config_override
	if _ship != null and _ship.config != null:
		return _ship.config.flight_config
	return null


func _unhandled_input(event: InputEvent) -> void:
	var cfg: FlightConfig = _get_config()
	var motion := event as InputEventMouseMotion
	if motion != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and cfg != null:
		_stick.x += motion.relative.x * cfg.mouse_sensitivity
		_stick.y -= motion.relative.y * cfg.mouse_sensitivity
		_stick = _stick.limit_length(1.0)
		return
	var button := event as InputEventMouseButton
	if button != null and button.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if event.is_action_pressed(&"flight_release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed(&"flight_toggle_assist"):
		_ship.intent.assist = not _ship.intent.assist
	elif event.is_action_pressed(&"flight_toggle_hud_help"):
		_help_visible = not _help_visible
		help_toggled.emit(_help_visible)


func _physics_process(delta: float) -> void:
	var cfg: FlightConfig = _get_config()
	if cfg == null:
		return
	var intent: ShipIntent = _ship.intent
	intent.throttle = Input.get_axis(&"flight_throttle_down", &"flight_throttle_up")

	var ramp: float = cfg.key_axis_ramp * delta
	_key_pitch = move_toward(_key_pitch, Input.get_axis(&"flight_pitch_down", &"flight_pitch_up"), ramp)
	_key_yaw = move_toward(_key_yaw, Input.get_axis(&"flight_yaw_left", &"flight_yaw_right"), ramp)
	_key_roll = move_toward(_key_roll, Input.get_axis(&"flight_roll_left", &"flight_roll_right"), ramp)

	_stick *= exp(-cfg.mouse_recenter_rate * delta)
	intent.pitch = clampf(_key_pitch + _stick.y, -1.0, 1.0)
	intent.yaw = clampf(_key_yaw + _stick.x, -1.0, 1.0)
	intent.roll = _key_roll
	intent.boost = Input.is_action_pressed(&"flight_boost")
	intent.brake = Input.is_action_pressed(&"flight_brake")


func is_help_visible() -> bool:
	return _help_visible
