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
var _identity: PanelContainer
var _heading: PanelContainer
var _speed_panel: PanelContainer
var _engine_panel: PanelContainer
var _target_panel: PanelContainer
var _alert_panel: PanelContainer
var _reticle: _FlightReticle
var _help_label: Label
var _heading_label: Label
var _pitch_roll_label: Label
var _heading_ribbon: _HeadingRibbon
var _speed_value: Label
var _speed_unit: Label
var _speed_bar: ProgressBar
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

	_frame = _HudFrame.new()
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_frame)

	_identity = _make_panel("IDENTITY", 256.0, 76.0)
	_place(_identity, Control.PRESET_TOP_LEFT, 42.0, 34.0, 256.0, 76.0)
	var identity_box := _content(_identity)
	var id := _label("VH-01  /  WRAITH", 19, IVORY)
	id.add_theme_font_size_override("font_size", 19)
	identity_box.add_child(id)
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	identity_box.add_child(mode_row)
	var mode_marker := ColorRect.new()
	mode_marker.color = TURQUOISE
	mode_marker.custom_minimum_size = Vector2(5.0, 5.0)
	mode_marker.size = Vector2(5.0, 5.0)
	mode_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mode_row.add_child(mode_marker)
	var mode := _label("FLIGHT SYSTEM  /  ACTIVE", 10, STONE)
	mode_row.add_child(mode)

	_heading = _make_panel("NAVIGATION", 310.0, 76.0)
	_place(_heading, Control.PRESET_CENTER_TOP, -155.0, 28.0, 310.0, 76.0)
	var heading_box := _content(_heading)
	_heading_label = _label("000°  /  N", 18, IVORY)
	_heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading_box.add_child(_heading_label)
	_heading_ribbon = _HeadingRibbon.new()
	_heading_ribbon.custom_minimum_size = Vector2(270.0, 18.0)
	_heading_ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading_box.add_child(_heading_ribbon)
	_pitch_roll_label = _label("PITCH  +00°     ROLL  +00°", 9, STEEL)
	_pitch_roll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading_box.add_child(_pitch_roll_label)

	_speed_panel = _make_panel("VELOCITY  /  M/S", 228.0, 136.0)
	_place(_speed_panel, Control.PRESET_CENTER_LEFT, 42.0, -45.0, 228.0, 136.0)
	var speed_box := _content(_speed_panel)
	var speed_row := HBoxContainer.new()
	speed_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	speed_box.add_child(speed_row)
	_speed_value = _label("000", 34, IVORY)
	speed_row.add_child(_speed_value)
	_speed_unit = _label("m/s", 11, STONE)
	_speed_unit.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_speed_unit_box(speed_row, _speed_unit)
	_speed_bar = _make_bar(TURQUOISE)
	speed_box.add_child(_speed_bar)
	var speed_caption := _label("RELATIVE VELOCITY", 9, STEEL)
	speed_box.add_child(speed_caption)

	_engine_panel = _make_panel("PROPULSION", 228.0, 186.0)
	_place(_engine_panel, Control.PRESET_CENTER_RIGHT, -270.0, -90.0, 228.0, 186.0)
	var engine_box := _content(_engine_panel)
	var throttle_row := _readout_row("THRUST", "0%", IVORY)
	engine_box.add_child(throttle_row[0])
	_throttle_value = throttle_row[1]
	var boost_label := _label("BOOST RESERVE", 9, STEEL)
	engine_box.add_child(boost_label)
	_boost_bar = _make_bar(AMBER)
	engine_box.add_child(_boost_bar)
	_boost_value = _label("READY", 10, AMBER)
	engine_box.add_child(_boost_value)
	_assist_value = _label("ASSIST  /  ON", 10, TURQUOISE)
	engine_box.add_child(_assist_value)

	_target_panel = _make_panel("NAVIGATION TARGET", 228.0, 92.0)
	_place(_target_panel, Control.PRESET_BOTTOM_RIGHT, -270.0, -152.0, 228.0, 92.0)
	var target_box := _content(_target_panel)
	_target_name = _label("NO TARGET LOCK", 12, STONE)
	target_box.add_child(_target_name)
	_target_distance = _label("NAV FEED  /  UNAVAILABLE", 9, STEEL)
	target_box.add_child(_target_distance)

	_alert_panel = _make_panel("SYSTEM FEED", 228.0, 58.0)
	_place(_alert_panel, Control.PRESET_BOTTOM_LEFT, 42.0, -52.0, 228.0, 58.0)
	var alert_box := _content(_alert_panel)
	_alert_value = _label("ALERT FEED  /  NO DATA", 10, STONE)
	alert_box.add_child(_alert_value)

	_reticle = _FlightReticle.new()
	_reticle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reticle.color = IVORY
	_root.add_child(_reticle)

	_help_label = _label("W/S  THRUST     MOUSE / ARROWS  PITCH · YAW     Q/E  ROLL     SHIFT  BOOST     X  BRAKE     F  ASSIST     ESC  MOUSE", 10, STONE)
	_help_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_help_label.offset_left = 300.0
	_help_label.offset_right = -300.0
	_help_label.offset_top = -27.0
	_help_label.offset_bottom = -9.0
	_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_help_label.visible = false
	_root.add_child(_help_label)
	_add_parallax(_speed_panel)
	_add_parallax(_engine_panel)
	_add_parallax(_target_panel)
	_add_parallax(_alert_panel)
	if visual_preview:
		var banner := _label("VISUAL PREVIEW  ·  MOCK DATA  ·  1–5 CHANGE STATE  ·  H TOGGLE HELP", 10, AMBER)
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
	_throttle_value.text = "%d%%" % int(round(clampf(_controller.throttle, -1.0, 1.0) * 100.0))
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
	var factor := clampf(viewport_size.y / 1080.0, 0.78, 1.35)
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


func _make_panel(title: String, width: float, height: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = title.replace(" ", "")
	panel.custom_minimum_size = Vector2(width, height)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(GRAPHITE.r, GRAPHITE.g, GRAPHITE.b, 0.82)
	style.border_color = Color(COPPER.r, COPPER.g, COPPER.b, 0.66)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 4
	style.shadow_offset = Vector2(1.0, 2.0)
	panel.add_theme_stylebox_override("panel", style)
	_root.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(stack)
	var title_label := _label(title, 9, COPPER)
	stack.add_child(title_label)
	return panel


func _content(panel: PanelContainer) -> VBoxContainer:
	return panel.get_child(0) as VBoxContainer


func _place(panel: Control, preset: Control.LayoutPreset, x: float, y: float, width: float, height: float) -> void:
	panel.set_anchors_and_offsets_preset(preset)
	if preset == Control.PRESET_CENTER_LEFT:
		panel.offset_left = x
		panel.offset_right = x + width
		panel.offset_top = y
		panel.offset_bottom = y + height
	elif preset == Control.PRESET_CENTER_RIGHT:
		panel.offset_left = x
		panel.offset_right = x + width
		panel.offset_top = y
		panel.offset_bottom = y + height
	elif preset == Control.PRESET_CENTER_TOP:
		panel.offset_left = x
		panel.offset_right = x + width
		panel.offset_top = y
		panel.offset_bottom = y + height
	elif preset == Control.PRESET_BOTTOM_LEFT:
		panel.offset_left = x
		panel.offset_right = x + width
		panel.offset_top = y - height
		panel.offset_bottom = y
	elif preset == Control.PRESET_BOTTOM_RIGHT:
		panel.offset_left = x
		panel.offset_right = x + width
		panel.offset_top = y - height
		panel.offset_bottom = y
	else:
		panel.offset_left = x
		panel.offset_right = x + width
		panel.offset_top = y
		panel.offset_bottom = y + height


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


func _readout_row(caption: String, value: String, color: Color) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(_label(caption, 10, STONE))
	var value_label := _label(value, 10, color)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	return [row, value_label]


func _speed_unit_box(row: HBoxContainer, unit: Label) -> void:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(unit)


func _add_parallax(panel: Control) -> void:
	_parallax_panels.append(panel)
	_parallax_origins.append(panel.position)


class _HudFrame:
	extends Control

	func _draw() -> void:
		var size := get_rect().size
		if size.x <= 0.0 or size.y <= 0.0:
			return
		var safe := Rect2(Vector2(20.0, 18.0), size - Vector2(40.0, 36.0))
		draw_rect(safe, Color(STEEL.r, STEEL.g, STEEL.b, 0.14), false, 1.0)
		var mid := size * 0.5
		var rail_color := Color(TURQUOISE.r, TURQUOISE.g, TURQUOISE.b, 0.22)
		var left_points := PackedVector2Array([Vector2(18, mid.y - size.y * 0.29), Vector2(36, mid.y - size.y * 0.36), Vector2(52, mid.y - size.y * 0.22), Vector2(52, mid.y + size.y * 0.22), Vector2(36, mid.y + size.y * 0.36), Vector2(18, mid.y + size.y * 0.29)])
		var right_points := PackedVector2Array()
		for point in left_points:
			right_points.append(Vector2(size.x - point.x, point.y))
		draw_polyline(left_points, rail_color, 1.0, true)
		draw_polyline(right_points, rail_color, 1.0, true)
		var tick_color := Color(COPPER.r, COPPER.g, COPPER.b, 0.56)
		draw_line(Vector2(30.0, 28.0), Vector2(82.0, 28.0), tick_color, 1.0, true)
		draw_line(Vector2(size.x - 82.0, 28.0), Vector2(size.x - 30.0, 28.0), tick_color, 1.0, true)


class _HeadingRibbon:
	extends Control
	var heading_degrees: float = 0.0

	func _draw() -> void:
		var size := get_rect().size
		if size.x <= 0.0 or size.y <= 0.0:
			return
		var center := size.x * 0.5
		var baseline := size.y - 2.0
		draw_line(Vector2(0.0, baseline), Vector2(size.x, baseline), Color(STEEL.r, STEEL.g, STEEL.b, 0.42), 1.0, true)
		for index in range(-6, 7):
			var degrees := wrapf(heading_degrees + index * 10.0, 0.0, 360.0)
			var x := center + index * 22.0
			var cardinal := int(round(degrees / 90.0)) % 4 == 0
			var tick_height := 8.0 if cardinal else 4.0
			draw_line(Vector2(x, baseline - tick_height), Vector2(x, baseline), Color(IVORY.r, IVORY.g, IVORY.b, 0.65), 1.0, true)
		draw_colored_polygon(PackedVector2Array([Vector2(center - 3.0, 0.0), Vector2(center + 3.0, 0.0), Vector2(center, 4.0)]), AMBER)


class _FlightReticle:
	extends Control
	var color: Color = IVORY
	var screen_point: Vector2 = Vector2.ZERO

	func set_screen_point(point: Vector2) -> void:
		screen_point = point
		queue_redraw()

	func _draw() -> void:
		var point := screen_point
		var tint := Color(color.r, color.g, color.b, 0.72)
		draw_arc(point, 10.0, deg_to_rad(36.0), deg_to_rad(144.0), 12, tint, 1.2, true)
		draw_arc(point, 10.0, deg_to_rad(216.0), deg_to_rad(324.0), 12, tint, 1.2, true)
		draw_line(point + Vector2(-17.0, 0.0), point + Vector2(-11.0, 0.0), tint, 1.0, true)
		draw_line(point + Vector2(11.0, 0.0), point + Vector2(17.0, 0.0), tint, 1.0, true)
		draw_line(point + Vector2(0.0, -17.0), point + Vector2(0.0, -11.0), tint, 1.0, true)
		draw_line(point + Vector2(0.0, 11.0), point + Vector2(0.0, 17.0), tint, 1.0, true)
		draw_circle(point, 1.5, AMBER)

