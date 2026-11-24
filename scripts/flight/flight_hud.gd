class_name FlightHud
extends CanvasLayer
## Minimal, panoramic WRAITH cockpit instrumentation. Presentation only: it reads the
## existing flight controller and never changes ship physics or input intent.

const VOID := Color("171C20")
const GRAPHITE := Color("252B31")
const IVORY := Color("D6CEB8")
const COPPER := Color("9B6848")
const AMBER := Color("C58D50")
const TURQUOISE := Color("527F7D")
const STEEL := Color("777D83")
const STONE := Color("A8A99E")

@export var ship_path: NodePath
@export var camera_path: NodePath
@export_range(0.0, 12.0, 0.25) var parallax_strength: float = 4.0
## Preview mode uses clearly labelled mock states, and is only enabled in the preview scene.
@export var visual_preview: bool = false

var _ship: Spaceship
var _controller: FlightController
var _camera: Camera3D
var _root: Control
var _frame: Control
var _identity: Control
var _heading: Control
var _speed_panel: Control
var _engine_panel: Control
var _target_panel: Control
var _alert_panel: Control
var _reticle: _FlightReticle
var _help_label: Label
var _heading_label: Label
var _pitch_roll_label: Label
var _heading_ribbon: _HeadingRibbon
var _speed_value: Label
var _speed_unit: Label
var _speed_bar: ProgressBar
var _throttle_bar: ProgressBar
var _throttle_value: Label
var _boost_value: Label
var _boost_bar: ProgressBar
var _assist_value: Label
var _target_name: Label
var _target_distance: Label
var _alert_value: Label
var _preview_state: int = 1
var _help_visible: bool = false
var _parallax_panels: Array[Control] = []
var _parallax_origins: Array[Vector2] = []


func _ready() -> void:
	layer = 10
	_ship = get_node_or_null(ship_path) as Spaceship
	_camera = get_node_or_null(camera_path) as Camera3D
	if _ship != null:
		_controller = _ship.get_node_or_null("FlightController") as FlightController
	_build()
	set_process(true)
	_apply_responsive_scale()
	get_viewport().size_changed.connect(_apply_responsive_scale)
	_reticle.set_screen_point(_screen_to_hud(get_viewport().get_visible_rect().size * 0.5))


func set_visual_preview(enabled: bool) -> void:
	visual_preview = enabled
	if _root != null:
		_root.queue_free()
		_root = null
		_parallax_panels.clear()
		_parallax_origins.clear()
		_build()
		_apply_responsive_scale()
		_reticle.set_screen_point(_screen_to_hud(get_viewport().get_visible_rect().size * 0.5))


func _unhandled_key_input(event: InputEvent) -> void:
	if not visual_preview or not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1: _preview_state = 1
		KEY_2: _preview_state = 2
		KEY_3: _preview_state = 3
		KEY_4: _preview_state = 4
		KEY_5: _preview_state = 5
		KEY_H: _help_visible = not _help_visible
		_: return
	_refresh_preview_hint()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_frame = _HudOrnaments.new()
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_frame)

	# Open, borderless instrument groups. Their visual reference is authored at 1920×1080.
	_identity = _group("Identity", Vector2(82.0, 66.0), Vector2(390.0, 112.0))
	_add_label(_identity, "VOID HORIZON", Vector2(42.0, 0.0), Vector2(300.0, 18.0), 11, STONE, 2.0)
	_add_label(_identity, "VH-01  /  WRAITH", Vector2(0.0, 31.0), Vector2(340.0, 32.0), 21, IVORY, 1.0)
	_add_status_dot(_identity, Vector2(3.0, 81.0), TURQUOISE)
	_add_label(_identity, "FLIGHT INTERFACE / ACTIVE", Vector2(17.0, 74.0), Vector2(300.0, 20.0), 10, STONE, 1.5)

	_heading = _group("Navigation", Vector2(810.0, 66.0), Vector2(300.0, 160.0))
	_heading_label = _add_label(_heading, "000°  N", Vector2(0.0, 20.0), Vector2(300.0, 44.0), 34, IVORY, 1.0)
	_heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heading_ribbon = _HeadingRibbon.new()
	_heading_ribbon.position = Vector2(10.0, 78.0)
	_heading_ribbon.size = Vector2(280.0, 25.0)
	_heading_ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_heading.add_child(_heading_ribbon)
	_pitch_roll_label = _add_label(_heading, "PITCH  +00°     ROLL  +00°", Vector2(0.0, 111.0), Vector2(300.0, 20.0), 9, STONE, 1.0)
	_pitch_roll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sector := _group("Sector", Vector2(1518.0, 72.0), Vector2(320.0, 75.0))
	var sector_label := _add_label(sector, "ORBITAL DATA  /  UNAVAILABLE", Vector2(0.0, 0.0), Vector2(320.0, 20.0), 10, STONE, 1.5)
	sector_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var zone_label := _add_label(sector, "DEEP SPACE  ·  FREE FLIGHT", Vector2(0.0, 29.0), Vector2(320.0, 20.0), 9, STONE, 1.5)
	zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_speed_panel = _group("Velocity", Vector2(84.0, 423.0), Vector2(250.0, 200.0))
	_add_label(_speed_panel, "VELOCITY", Vector2(23.0, 0.0), Vector2(210.0, 18.0), 11, STONE, 2.0)
	_add_label(_speed_panel, "RELATIVE  /  M·S⁻¹", Vector2(23.0, 20.0), Vector2(220.0, 17.0), 9, STEEL, 1.5)
	_speed_value = _add_label(_speed_panel, "000", Vector2(19.0, 45.0), Vector2(180.0, 66.0), 52, IVORY)
	_speed_unit = _add_label(_speed_panel, "M/S", Vector2(23.0, 112.0), Vector2(160.0, 18.0), 11, STONE, 1.0)
	_speed_bar = _make_bar(TURQUOISE)
	_speed_bar.position = Vector2(22.0, 141.0)
	_speed_bar.size = Vector2(183.0, 5.0)
	_speed_panel.add_child(_speed_bar)
	_add_label(_speed_panel, "SPEED ENVELOPE", Vector2(22.0, 162.0), Vector2(160.0, 17.0), 8, STEEL, 1.4)

	_engine_panel = _group("Propulsion", Vector2(1612.0, 389.0), Vector2(224.0, 240.0))
	_add_label(_engine_panel, "PROPULSION", Vector2(0.0, 0.0), Vector2(210.0, 18.0), 11, STONE, 2.0)
	_add_label(_engine_panel, "ENGINE OUTPUT", Vector2(0.0, 26.0), Vector2(170.0, 28.0), 18, IVORY, 0.4)
	_throttle_value = _add_label(_engine_panel, "0%", Vector2(156.0, 26.0), Vector2(68.0, 28.0), 20, AMBER)
	_throttle_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_throttle_bar = _make_bar(TURQUOISE)
	_throttle_bar.position = Vector2(0.0, 61.0)
	_throttle_bar.size = Vector2(224.0, 4.0)
	_engine_panel.add_child(_throttle_bar)
	_add_label(_engine_panel, "BOOST RESERVE", Vector2(0.0, 81.0), Vector2(160.0, 17.0), 9, STONE, 1.5)
	_boost_bar = _make_bar(AMBER)
	_boost_bar.position = Vector2(0.0, 101.0)
	_boost_bar.size = Vector2(224.0, 7.0)
	_engine_panel.add_child(_boost_bar)
	_boost_value = _add_label(_engine_panel, "READY  ·  100%", Vector2(0.0, 115.0), Vector2(224.0, 18.0), 10, AMBER, 1.0)
	_assist_value = _add_label(_engine_panel, "FLIGHT ASSIST  /  ON", Vector2(0.0, 151.0), Vector2(224.0, 18.0), 10, TURQUOISE, 1.5)
	_add_label(_engine_panel, "THROTTLE  /  MANUAL", Vector2(0.0, 181.0), Vector2(224.0, 18.0), 9, STEEL, 1.5)

	_alert_panel = _group("SystemFeed", Vector2(84.0, 896.0), Vector2(300.0, 90.0))
	_add_label(_alert_panel, "SYSTEM FEED", Vector2(0.0, 7.0), Vector2(230.0, 18.0), 10, STONE, 1.8)
	_add_status_dot(_alert_panel, Vector2(3.0, 42.0), STEEL)
	_alert_value = _add_label(_alert_panel, "ALERT FEED  /  NO DATA", Vector2(18.0, 34.0), Vector2(280.0, 20.0), 10, IVORY, 0.8)

	_target_panel = _group("NavigationTarget", Vector2(1612.0, 866.0), Vector2(224.0, 104.0))
	_add_label(_target_panel, "NAVIGATION TARGET", Vector2(0.0, 7.0), Vector2(224.0, 18.0), 10, STONE, 1.8)
	_target_name = _add_label(_target_panel, "NO TARGET LOCK", Vector2(18.0, 34.0), Vector2(206.0, 20.0), 11, IVORY, 0.5)
	_target_distance = _add_label(_target_panel, "NAV FEED  /  UNAVAILABLE", Vector2(0.0, 62.0), Vector2(224.0, 18.0), 8, STEEL, 1.1)

	_reticle = _FlightReticle.new()
	_reticle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reticle.color = IVORY
	_root.add_child(_reticle)

	_help_label = _label("W / S  THRUST     MOUSE  FLIGHT     Q / E  ROLL     SHIFT  BOOST     X  BRAKE", 9, STONE)
	_help_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_help_label.offset_left = 360.0
	_help_label.offset_right = -360.0
	_help_label.offset_top = -48.0
	_help_label.offset_bottom = -24.0
	_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_help_label.visible = false
	_root.add_child(_help_label)
	_add_parallax(_speed_panel)
	_add_parallax(_engine_panel)
	_add_parallax(_target_panel)
	_add_parallax(_alert_panel)
	if visual_preview:
		var banner := _label("VISUAL PREVIEW  ·  MOCK DATA  ·  1–5 CHANGE STATE  ·  H TOGGLE HELP", 9, AMBER)
		banner.name = "PreviewBanner"
		banner.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		banner.offset_top = -48.0
		banner.offset_bottom = -30.0
		banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_root.add_child(banner)


func _process(_delta: float) -> void:
	if visual_preview:
		_render_preview()
		return
	if _ship == null or _controller == null:
		return
	var speed: float = _controller.get_speed()
	var config := _controller.get_flight_config()
	var maximum: float = config.max_speed * config.boost_speed_multiplier if config != null else 1.0
	_speed_value.text = _format_speed(speed)
	_speed_bar.value = clampf(speed / maxf(maximum, 0.001), 0.0, 1.0)
	var engine_output: float = _ship.network_state.thrust if _ship.network_state != null else clampf(maxf(_controller.throttle, 0.0), 0.0, 1.0)
	_throttle_value.text = "%d%%" % int(round(clampf(engine_output, 0.0, 1.0) * 100.0))
	_throttle_bar.value = clampf(engine_output, 0.0, 1.0)
	_boost_bar.value = _controller.boost.energy
	if _controller.boost.active:
		_boost_value.text = "BOOST ENGAGED"
		_boost_value.add_theme_color_override("font_color", AMBER)
	elif _controller.boost.locked:
		_boost_value.text = "RECHARGING"
		_boost_value.add_theme_color_override("font_color", COPPER)
	else:
		_boost_value.text = "READY  ·  %02d%%" % int(round(_controller.boost.energy * 100.0))
		_boost_value.add_theme_color_override("font_color", AMBER)
	_assist_value.text = "ASSIST  /  ON" if _ship.intent.assist else "ASSIST  /  OFF"
	_assist_value.add_theme_color_override("font_color", TURQUOISE if _ship.intent.assist else STONE)
	_update_heading()
	_update_reticle()
	_update_parallax()


func _update_heading() -> void:
	var basis := _ship.get_global_transform_interpolated().basis.orthonormalized()
	var forward := -basis.z
	var heading_degrees: float = wrapf(rad_to_deg(atan2(forward.x, -forward.z)), 0.0, 360.0)
	var pitch_degrees: float = rad_to_deg(asin(clampf(forward.y, -1.0, 1.0)))
	var roll_degrees: float = rad_to_deg(atan2(basis.x.y, basis.y.y))
	var cardinal: String = "N" if heading_degrees < 22.5 or heading_degrees >= 337.5 else "E" if heading_degrees < 112.5 else "S" if heading_degrees < 202.5 else "W"
	_heading_label.text = "%03d°  /  %s" % [int(round(heading_degrees)) % 360, cardinal]
	_pitch_roll_label.text = "PITCH  %+03d°     ROLL  %+03d°" % [int(round(pitch_degrees)), int(round(roll_degrees))]
	_heading_ribbon.heading_degrees = heading_degrees
	_heading_ribbon.queue_redraw()


func _update_reticle() -> void:
	if _camera == null:
		_reticle.set_screen_point(_screen_to_hud(get_viewport().get_visible_rect().size * 0.5))
		return
	var ship_tf: Transform3D = _ship.get_global_transform_interpolated()
	var forward := -ship_tf.basis.z.normalized()
	var point: Vector3 = ship_tf.origin + forward * 300.0
	_reticle.visible = not _camera.is_position_behind(point)
	if _reticle.visible:
		_reticle.set_screen_point(_screen_to_hud(_camera.unproject_position(point)))


func _update_parallax() -> void:
	if _camera == null or parallax_strength <= 0.0:
		return
	var ship_forward := -_ship.get_global_transform_interpolated().basis.z.normalized()
	var camera_local_forward := _camera.global_basis.inverse() * ship_forward
	var parallax := Vector2(-camera_local_forward.x, camera_local_forward.y) * parallax_strength
	for index in _parallax_panels.size():
		var panel: Control = _parallax_panels[index]
		var origin: Vector2 = _parallax_origins[index]
		var amount: float = 0.45 if panel == _speed_panel or panel == _alert_panel else 1.0
		panel.position = origin + parallax * amount


func _apply_responsive_scale() -> void:
	if _root == null or get_viewport() == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.y <= 0.0:
		return
	var factor := minf(viewport_size.y / 1080.0, viewport_size.x / 1920.0)
	factor = minf(factor, 1.35)
	_root.scale = Vector2.ONE * factor
	_root.position = viewport_size * (1.0 - factor) * 0.5
	_frame.queue_redraw()


func _screen_to_hud(screen_point: Vector2) -> Vector2:
	return (screen_point - _root.position) / maxf(_root.scale.x, 0.001)


func _render_preview() -> void:
	var heading: float = [0.0, 36.0, 126.0, 218.0, 302.0][_preview_state - 1]
	_heading_label.text = "%03d°  /  %s" % [int(heading), ["N", "N", "E", "S", "W"][_preview_state - 1]]
	_pitch_roll_label.text = ["PITCH  +02°     ROLL  +00°", "PITCH  +05°     ROLL  +08°", "PITCH  -02°     ROLL  -04°", "PITCH  +01°     ROLL  +00°", "PITCH  -06°     ROLL  +13°"][_preview_state - 1]
	_heading_ribbon.heading_degrees = heading
	_heading_ribbon.queue_redraw()
	_speed_value.text = ["000", "286", "142", "094", "061"][_preview_state - 1]
	_speed_bar.value = [0.0, 0.82, 0.43, 0.28, 0.18][_preview_state - 1]
	_throttle_value.text = ["0%", "100%", "68%", "42%", "26%"][_preview_state - 1]
	_throttle_bar.value = [0.0, 1.0, 0.68, 0.42, 0.26][_preview_state - 1]
	_boost_bar.value = [1.0, 0.43, 0.72, 0.88, 0.18][_preview_state - 1]
	_boost_value.text = ["READY  ·  100%", "BOOST ENGAGED", "READY  ·  72%", "READY  ·  88%", "RECHARGING"][_preview_state - 1]
	_boost_value.add_theme_color_override("font_color", COPPER if _preview_state == 5 else AMBER)
	_assist_value.text = "ASSIST  /  ON"
	_target_name.text = "RELAY K-07  ·  MOCK" if _preview_state == 3 else "NO TARGET LOCK"
	_target_name.add_theme_color_override("font_color", TURQUOISE if _preview_state == 3 else STONE)
	_target_distance.text = "18.4 KM  /  MOCK FEED" if _preview_state == 3 else "NAV FEED  /  UNAVAILABLE"
	if _preview_state == 4:
		_alert_value.text = "WARNING  /  HULL STRESS"
		_alert_value.add_theme_color_override("font_color", AMBER)
	elif _preview_state == 5:
		_alert_value.text = "CRITICAL  /  MOCK ALERT"
		_alert_value.add_theme_color_override("font_color", COPPER)
	else:
		_alert_value.text = "ALERT FEED  /  NO DATA"
		_alert_value.add_theme_color_override("font_color", STONE)


func _refresh_preview_hint() -> void:
	_help_label.visible = _help_visible
	var banner := _root.get_node_or_null("PreviewBanner") as Label
	if banner != null:
		banner.text = "VISUAL PREVIEW  ·  MOCK DATA  ·  STATE %d  ·  1–5 CHANGE  ·  H TOGGLE HELP" % _preview_state


func _format_speed(speed: float) -> String:
	return "%03d" % int(round(maxf(speed, 0.0))) if speed < 1000.0 else "%.1fk" % (speed / 1000.0)


func _group(group_name: String, origin: Vector2, group_size: Vector2) -> Control:
	var group := Control.new()
	group.name = group_name
	group.position = origin
	group.size = group_size
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(group)
	return group


func _add_label(parent: Control, value: String, origin: Vector2, label_size: Vector2, font_size: int, color: Color, tracking: float = 0.0) -> Label:
	var label := _label(value, font_size, color)
	label.position = origin
	label.size = label_size
	label.add_theme_constant_override("font_spacing", int(round(tracking)))
	parent.add_child(label)
	return label


func _add_status_dot(parent: Control, origin: Vector2, color: Color) -> void:
	var dot := ColorRect.new()
	dot.position = origin
	dot.size = Vector2(6.0, 6.0)
	dot.color = color
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(dot)


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(VOID.r, VOID.g, VOID.b, 0.95))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0.0, 5.0)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var back := StyleBoxFlat.new()
	back.bg_color = Color(STEEL.r, STEEL.g, STEEL.b, 0.20)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)
	return bar


func _add_parallax(panel: Control) -> void:
	_parallax_panels.append(panel)
	_parallax_origins.append(panel.position)


class _HudOrnaments:
	extends Control

	func _draw() -> void:
		var size := get_rect().size
		if size.x <= 0.0 or size.y <= 0.0:
			return
		var edge := Color(STEEL.r, STEEL.g, STEEL.b, 0.30)
		var hair := Color(STONE.r, STONE.g, STONE.b, 0.17)
		var teal := Color(TURQUOISE.r, TURQUOISE.g, TURQUOISE.b, 0.30)
		var amber := Color(AMBER.r, AMBER.g, AMBER.b, 0.55)
		# Clipped perimeter instead of boxed panels.
		draw_line(Vector2(30, 92), Vector2(30, 32), edge)
		draw_line(Vector2(30, 32), Vector2(90, 32), edge)
		draw_line(Vector2(size.x - 90, 32), Vector2(size.x - 30, 32), edge)
		draw_line(Vector2(size.x - 30, 32), Vector2(size.x - 30, 92), edge)
		draw_line(Vector2(30, size.y - 92), Vector2(30, size.y - 32), edge)
		draw_line(Vector2(30, size.y - 32), Vector2(90, size.y - 32), edge)
		draw_line(Vector2(size.x - 90, size.y - 32), Vector2(size.x - 30, size.y - 32), edge)
		draw_line(Vector2(size.x - 30, size.y - 32), Vector2(size.x - 30, size.y - 92), edge)
		# Inward-curving side rails echo the reference craft's wing profile.
		var left_rail := PackedVector2Array([Vector2(30, size.y * 0.24), Vector2(44, size.y * 0.34), Vector2(52, size.y * 0.46), Vector2(52, size.y * 0.60), Vector2(44, size.y * 0.72), Vector2(30, size.y * 0.82)])
		var right_rail := PackedVector2Array()
		for point in left_rail:
			right_rail.append(Vector2(size.x - point.x, point.y))
		draw_polyline(left_rail, teal, 1.0, true)
		draw_polyline(right_rail, teal, 1.0, true)
		# Short registration ticks give the interface a technical drawing quality.
		draw_colored_polygon(PackedVector2Array([Vector2(82, 66), Vector2(110, 66), Vector2(96, 91), Vector2(82, 91)]), AMBER)
		# Open, center sight and sparse attitude ladder.
		var center := size * 0.5
		for offset in [-130.0, 130.0]:
			var y := center.y + 82.0
			var direction := 1.0 if offset > 0.0 else -1.0
			draw_line(center + Vector2(offset, y - center.y), center + Vector2(offset + direction * 36.0, y - center.y), hair)
			draw_line(center + Vector2(offset, y - center.y), center + Vector2(offset, y - center.y - 4.0), hair)
		for offset in [-190.0, 190.0]:
			var y := center.y + 135.0
			var direction := 1.0 if offset > 0.0 else -1.0
			draw_line(center + Vector2(offset, y - center.y), center + Vector2(offset + direction * 28.0, y - center.y), hair)
		# Instrument anchor strokes, deliberately not full rectangles.
		draw_line(Vector2(84, 423), Vector2(84, 604), amber, 2.0)
		draw_line(Vector2(size.x - 62, 389), Vector2(size.x - 62, 612), teal, 2.0)
		draw_line(Vector2(84, 896), Vector2(294, 896), edge)
		draw_line(Vector2(size.x - 308, 866), Vector2(size.x - 84, 866), edge)
		draw_line(Vector2(700, size.y - 64), Vector2(size.x - 700, size.y - 64), hair)


class _HeadingRibbon:
	extends Control
	var heading_degrees: float = 0.0

	func _draw() -> void:
		var size := get_rect().size
		if size.x <= 0.0 or size.y <= 0.0:
			return
		var center := size.x * 0.5
		var baseline := size.y - 2.0
		draw_line(Vector2(0.0, baseline), Vector2(size.x, baseline), Color(STONE.r, STONE.g, STONE.b, 0.40), 1.0, true)
		for index in range(-6, 7):
			var degrees := wrapf(heading_degrees + index * 10.0, 0.0, 360.0)
			var x := center + index * 22.0
			var cardinal := int(round(degrees / 90.0)) % 4 == 0
			var tick_height := 15.0 if index == 0 else 9.0 if cardinal else 5.0
			draw_line(Vector2(x, baseline - tick_height), Vector2(x, baseline), Color(IVORY.r, IVORY.g, IVORY.b, 0.60), 1.0, true)
		draw_colored_polygon(PackedVector2Array([Vector2(center - 4.0, 0.0), Vector2(center + 4.0, 0.0), Vector2(center, 6.0)]), AMBER)


class _FlightReticle:
	extends Control
	var color: Color = IVORY
	var screen_point: Vector2 = Vector2.ZERO

	func set_screen_point(point: Vector2) -> void:
		screen_point = point
		queue_redraw()

	func _draw() -> void:
		var point := screen_point
		var tint := Color(color.r, color.g, color.b, 0.75)
		draw_line(point + Vector2(-30.0, 0.0), point + Vector2(-12.0, 0.0), tint, 1.0, true)
		draw_line(point + Vector2(12.0, 0.0), point + Vector2(30.0, 0.0), tint, 1.0, true)
		draw_line(point + Vector2(0.0, -30.0), point + Vector2(0.0, -12.0), tint, 1.0, true)
		draw_line(point + Vector2(0.0, 12.0), point + Vector2(0.0, 30.0), tint, 1.0, true)
		draw_arc(point, 8.0, deg_to_rad(35.0), deg_to_rad(145.0), 16, tint, 1.0, true)
		draw_arc(point, 8.0, deg_to_rad(215.0), deg_to_rad(325.0), 16, tint, 1.0, true)
		draw_circle(point, 1.5, AMBER)



