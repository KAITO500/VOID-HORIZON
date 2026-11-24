class_name FlightHud
extends CanvasLayer
## Minimal flight HUD built in code: speed, throttle, boost energy, assist state, forward reticle.
## Reads from the ship's FlightController; never writes to it.

@export var ship_path: NodePath
@export var camera_path: NodePath
@export var accent_color: Color = Color(0.45, 0.85, 0.80)      # muted turquoise
@export var boost_color: Color = Color(1.0, 0.65, 0.25)        # warm amber
@export var warning_color: Color = Color(0.85, 0.35, 0.25)

var _ship: Spaceship
var _controller: FlightController
var _flight_input: FlightInput
var _camera: Camera3D
var _speed_label: Label
var _status_label: Label
var _help_label: Label
var _speed_bar: ProgressBar
var _boost_bar: ProgressBar
var _reticle: Control


func _ready() -> void:
	layer = 10
	_ship = get_node_or_null(ship_path) as Spaceship
	_camera = get_node_or_null(camera_path) as Camera3D
	if _ship != null:
		_controller = _ship.get_node_or_null("FlightController") as FlightController
		_flight_input = _ship.get_node_or_null("FlightInput") as FlightInput
	_build()
	if _flight_input != null:
		_flight_input.help_toggled.connect(func(visible_help: bool) -> void: _help_label.visible = visible_help)


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_reticle = _Reticle.new()
	_reticle.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(_reticle as _Reticle).color = accent_color
	root.add_child(_reticle)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.offset_bottom = -28.0
	box.custom_minimum_size = Vector2(360.0, 0.0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)

	_speed_label = _make_label(34, accent_color)
	_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_speed_label)
	_speed_bar = _make_bar(accent_color)
	box.add_child(_speed_bar)
	_status_label = _make_label(14, accent_color)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status_label)
	_boost_bar = _make_bar(boost_color)
	box.add_child(_boost_bar)

	_help_label = _make_label(13, Color(0.75, 0.85, 0.85, 0.85))
	_help_label.position = Vector2(14.0, 10.0)
	_help_label.text = "W/S throttle   Mouse or Up/Down pitch   A/D or Left/Right yaw   Q/E roll\nShift boost   X brake   F flight assist   Esc free mouse (click to recapture)   H hide help"
	root.add_child(_help_label)


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0.0, 8.0)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.0, 0.0, 0.0, 0.45)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)
	return bar


func _process(_delta: float) -> void:
	if _controller == null or _ship == null:
		return
	var cfg: FlightConfig = _controller.get_flight_config()
	if cfg == null:
		return
	var boost: FlightBoost = _controller.boost
	_speed_label.text = "%d m/s" % int(round(_controller.get_speed()))
	_speed_bar.value = clampf(_controller.get_speed() / (cfg.max_speed * cfg.boost_speed_multiplier), 0.0, 1.0)
	_boost_bar.value = boost.energy
	(_boost_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = warning_color if boost.locked else boost_color

	var status: PackedStringArray = PackedStringArray()
	status.append("THR %d%%" % int(round(_controller.throttle * 100.0)))
	status.append("ASSIST ON" if _ship.intent.assist else "ASSIST OFF")
	if boost.active:
		status.append("BOOST")
	elif boost.locked:
		status.append("BOOST RECHARGING")
	if _ship.intent.brake:
		status.append("BRAKE")
	_status_label.text = "   ".join(status)

	if _camera != null:
		# Interpolated transform: this runs in _process, so the physics-tick transform would make the
		# reticle step at the physics rate (60 Hz) on higher refresh-rate displays.
		var ship_tf: Transform3D = _ship.get_global_transform_interpolated()
		var forward: Vector3 = -ship_tf.basis.z.normalized()
		var point: Vector3 = ship_tf.origin + forward * 300.0
		_reticle.visible = not _camera.is_position_behind(point)
		if _reticle.visible:
			(_reticle as _Reticle).screen_point = _camera.unproject_position(point)
			_reticle.queue_redraw()


## Small circle showing where the nose points (the camera lags behind the ship's orientation).
class _Reticle extends Control:
	var color: Color = Color.WHITE
	var screen_point: Vector2 = Vector2.ZERO

	func _draw() -> void:
		draw_arc(screen_point, 11.0, 0.0, TAU, 32, color, 1.5, true)
		draw_circle(screen_point, 1.8, color)
