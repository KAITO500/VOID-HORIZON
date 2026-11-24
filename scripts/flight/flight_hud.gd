class_name FlightHud
extends CanvasLayer
## WRAITH instruments rendered as independent planes on three concave 3D display layers.
## The source UI stays flat and readable; physical surface transforms create the wraparound view.

# COSMIC VIOLET is an interface-only palette; space, ship and planet assets keep their own colors.
const VOID := Color("171323")
const GRAPHITE := Color("20152F")
const ICE_WHITE := Color("F1DFFF")
const MAGENTA := Color("C04DDB")
const LUMINOUS_VIOLET := Color("A45BDF")
const COSMIC_PURPLE := Color("7139A8")
const PURPLE_SURFACE := Color("302044")
const LAVENDER := Color("C9A5F0")
const MUTED_TEXT := Color("A99AB8")

@export var ship_path: NodePath
@export var camera_path: NodePath
## Preview mode uses clearly labelled mock states, and is only enabled in the preview scene.
@export var visual_preview: bool = false
@export var three_quarter_presentation: bool = false

var _ship: Spaceship
var _controller: FlightController
var _camera: Camera3D
var _ui_viewport: SubViewport
var _surface_viewport: SubViewport
var _surface_camera: Camera3D
var _surface_root: Node3D
var _display_rect: TextureRect
var _root: Control
var _surface_panels: Array[Dictionary] = []
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
var _preview_banner: Label


func _ready() -> void:
	layer = 10
	_ship = get_node_or_null(ship_path) as Spaceship
	_camera = get_node_or_null(camera_path) as Camera3D
	if _ship != null:
		_controller = _ship.get_node_or_null("FlightController") as FlightController
	_setup_spatial_display()
	_build()
	set_process(true)
	_resize_spatial_display()
	get_viewport().size_changed.connect(_resize_spatial_display)
	set_presentation_view(three_quarter_presentation)


func set_visual_preview(enabled: bool) -> void:
	visual_preview = enabled
	if _preview_banner != null:
		_preview_banner.visible = visual_preview
	if visual_preview:
		_render_preview()


func set_presentation_view(three_quarter: bool) -> void:
	three_quarter_presentation = three_quarter
	if _surface_camera == null:
		return
	if three_quarter_presentation:
		_surface_camera.position = Vector3(3.2, 0.45, 0.0)
		_surface_camera.look_at(Vector3(0.0, 0.0, -10.0), Vector3.UP)
	else:
		_surface_camera.position = Vector3.ZERO
		_surface_camera.rotation = Vector3.ZERO


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


func _setup_spatial_display() -> void:
	_ui_viewport = SubViewport.new()
	_ui_viewport.name = "HudArtworkViewport"
	_ui_viewport.size = Vector2i(1920, 1080)
	_ui_viewport.transparent_bg = true
	_ui_viewport.gui_disable_input = true
	_ui_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_ui_viewport)
	_root = Control.new()
	_root.name = "HudArtwork"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_viewport.add_child(_root)

	_surface_viewport = SubViewport.new()
	_surface_viewport.name = "ConcaveDisplayViewport"
	_surface_viewport.size = Vector2i(1920, 1080)
	_surface_viewport.transparent_bg = true
	_surface_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_surface_viewport.world_3d = World3D.new()
	add_child(_surface_viewport)
	_surface_root = Node3D.new()
	_surface_root.name = "ConcaveDisplaySurfaces"
	_surface_viewport.add_child(_surface_root)

	_surface_camera = Camera3D.new()
	_surface_camera.name = "PilotDisplayCamera"
	_surface_camera.fov = 70.0
	_surface_camera.near = 0.05
	_surface_camera.far = 80.0
	_surface_camera.current = true
	_surface_root.add_child(_surface_camera)

	_display_rect = TextureRect.new()
	_display_rect.name = "SpatialHudComposite"
	_display_rect.texture = _surface_viewport.get_texture()
	_display_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_display_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_display_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_display_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_display_rect)
	_create_concave_backing()


func _build() -> void:
	# Most recessed: peripheral identification and system context, far around the cockpit arc.
	_identity = _group("Identity", Vector2(78.0, 70.0), Vector2(450.0, 132.0), 11.4, 0)
	_add_label(_identity, "VOID HORIZON", Vector2(0.0, 8.0), Vector2(420.0, 18.0), 10, MUTED_TEXT, 2.1)
	_add_label(_identity, "VH-01  /  WRAITH", Vector2(0.0, 36.0), Vector2(420.0, 34.0), 22, ICE_WHITE, 0.8)
	_add_status_dot(_identity, Vector2(2.0, 91.0), COSMIC_PURPLE)
	_add_label(_identity, "FLIGHT INTERFACE / ACTIVE", Vector2(18.0, 82.0), Vector2(370.0, 20.0), 10, MUTED_TEXT, 1.3)
	var sector := _group("Sector", Vector2(1392.0, 76.0), Vector2(450.0, 112.0), 11.4, 0)
	var sector_label := _add_label(sector, "ORBITAL DATA / UNAVAILABLE", Vector2(0.0, 8.0), Vector2(440.0, 20.0), 10, MUTED_TEXT, 1.5)
	sector_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var zone_label := _add_label(sector, "DEEP SPACE  Â·  FREE FLIGHT", Vector2(0.0, 37.0), Vector2(440.0, 20.0), 9, ICE_WHITE, 1.3)
	zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_add_label(sector, "VH-01  /  SYSTEM STATUS", Vector2(0.0, 68.0), Vector2(440.0, 18.0), 8, PURPLE_SURFACE, 1.5).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_alert_panel = _group("SystemFeed", Vector2(78.0, 904.0), Vector2(450.0, 106.0), 11.4, 2)
	_add_label(_alert_panel, "SYSTEM FEED", Vector2(0.0, 7.0), Vector2(420.0, 18.0), 10, MUTED_TEXT, 1.8)
	_add_status_dot(_alert_panel, Vector2(2.0, 48.0), PURPLE_SURFACE)
	_alert_value = _add_label(_alert_panel, "ALERT FEED  /  NO DATA", Vector2(18.0, 39.0), Vector2(390.0, 20.0), 10, ICE_WHITE, 0.8)

	# Recessed side instruments sit farther back and face the pilot from each side of the arc.
	_engine_panel = _group("Propulsion", Vector2(90.0, 625.0), Vector2(500.0, 260.0), 10.0, 1)
	_add_label(_engine_panel, "PROPULSION", Vector2(18.0, 14.0), Vector2(450.0, 18.0), 10, MUTED_TEXT, 2.0)
	_add_label(_engine_panel, "ENGINE OUTPUT", Vector2(18.0, 49.0), Vector2(300.0, 32.0), 18, ICE_WHITE, 0.4)
	_throttle_value = _add_label(_engine_panel, "0%", Vector2(380.0, 49.0), Vector2(90.0, 32.0), 22, LUMINOUS_VIOLET)
	_throttle_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_throttle_bar = _make_bar(COSMIC_PURPLE)
	_throttle_bar.position = Vector2(18.0, 91.0)
	_throttle_bar.size = Vector2(450.0, 5.0)
	_engine_panel.add_child(_throttle_bar)
	_add_label(_engine_panel, "BOOST RESERVE", Vector2(18.0, 121.0), Vector2(260.0, 18.0), 9, MUTED_TEXT, 1.5)
	_boost_bar = _make_bar(LUMINOUS_VIOLET)
	_boost_bar.position = Vector2(18.0, 145.0)
	_boost_bar.size = Vector2(450.0, 7.0)
	_engine_panel.add_child(_boost_bar)
	_boost_value = _add_label(_engine_panel, "READY  Â·  100%", Vector2(18.0, 165.0), Vector2(300.0, 18.0), 10, LUMINOUS_VIOLET, 1.0)
	_assist_value = _add_label(_engine_panel, "FLIGHT ASSIST  /  ON", Vector2(18.0, 212.0), Vector2(440.0, 18.0), 10, COSMIC_PURPLE, 1.5)

	_target_panel = _group("NavigationTarget", Vector2(1390.0, 206.0), Vector2(450.0, 206.0), 10.0, 1)
	_add_label(_target_panel, "NAVIGATION TARGET", Vector2(18.0, 14.0), Vector2(400.0, 18.0), 10, MUTED_TEXT, 1.8)
	_target_name = _add_label(_target_panel, "NO TARGET LOCK", Vector2(18.0, 52.0), Vector2(400.0, 32.0), 18, ICE_WHITE, 0.5)
	_target_distance = _add_label(_target_panel, "NAV FEED  /  UNAVAILABLE", Vector2(18.0, 95.0), Vector2(400.0, 18.0), 9, PURPLE_SURFACE, 1.1)
	_add_label(_target_panel, "LOCK DATA NOT PROVIDED", Vector2(18.0, 152.0), Vector2(400.0, 18.0), 8, PURPLE_SURFACE, 1.3)

	# Closest display glass: primary flight data, sight and heading stay near the pilot's sightline.
	_heading = _group("Navigation", Vector2(790.0, 62.0), Vector2(340.0, 142.0), 8.6, 0)
	_heading_label = _add_label(_heading, "000Â°  N", Vector2(0.0, 20.0), Vector2(300.0, 44.0), 34, ICE_WHITE, 1.0)
	_heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heading_ribbon = _HeadingRibbon.new()
	_heading_ribbon.position = Vector2(20.0, 76.0)
	_heading_ribbon.size = Vector2(300.0, 25.0)
	_heading_ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_heading.add_child(_heading_ribbon)
	_pitch_roll_label = _add_label(_heading, "PITCH  +00Â°     ROLL  +00Â°", Vector2(0.0, 111.0), Vector2(300.0, 20.0), 9, MUTED_TEXT, 1.0)
	_pitch_roll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_speed_panel = _group("Velocity", Vector2(748.0, 711.0), Vector2(424.0, 246.0), 8.8, 0)
	_add_label(_speed_panel, "VELOCITY  /  RELATIVE", Vector2(24.0, 16.0), Vector2(350.0, 18.0), 10, MUTED_TEXT, 1.8)
	_speed_value = _add_label(_speed_panel, "000", Vector2(22.0, 49.0), Vector2(250.0, 76.0), 60, ICE_WHITE, -1.0)
	_speed_unit = _add_label(_speed_panel, "M/S", Vector2(282.0, 90.0), Vector2(95.0, 18.0), 11, LAVENDER, 1.0)
	_speed_bar = _make_bar(COSMIC_PURPLE)
	_speed_bar.position = Vector2(24.0, 147.0)
	_speed_bar.size = Vector2(370.0, 5.0)
	_speed_panel.add_child(_speed_bar)
	_add_label(_speed_panel, "SPEED ENVELOPE", Vector2(24.0, 177.0), Vector2(300.0, 18.0), 8, PURPLE_SURFACE, 1.4)

	_reticle = _FlightReticle.new()
	_reticle.position = Vector2(922.0, 502.0)
	_reticle.size = Vector2(76.0, 76.0)
	_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reticle.color = ICE_WHITE
	_root.add_child(_reticle)
	_register_surface_panel(_reticle, Rect2(922.0, 502.0, 76.0, 76.0), 8.45)
	_reticle.set_screen_point(Vector2(38.0, 38.0))

	_help_label = _label("W / S  THRUST     MOUSE  FLIGHT     Q / E  ROLL     SHIFT  BOOST     X  BRAKE     F  ASSIST", 9, MUTED_TEXT)
	_help_label.position = Vector2(700.0, 1020.0)
	_help_label.size = Vector2(520.0, 20.0)
	_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_help_label.visible = false
	_root.add_child(_help_label)
	_preview_banner = _label("VISUAL PREVIEW  Â·  MOCK DATA  Â·  1â€“5 CHANGE STATE  Â·  H TOGGLE HELP", 9, LUMINOUS_VIOLET)
	_preview_banner.name = "PreviewBanner"
	_preview_banner.position = Vector2(650.0, 1050.0)
	_preview_banner.size = Vector2(620.0, 20.0)
	_preview_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_banner.visible = visual_preview
	_root.add_child(_preview_banner)
	_rebuild_surface_panels()


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
		_boost_value.add_theme_color_override("font_color", LUMINOUS_VIOLET)
	elif _controller.boost.locked:
		_boost_value.text = "RECHARGING"
		_boost_value.add_theme_color_override("font_color", MAGENTA)
	else:
		_boost_value.text = "READY  Â·  %02d%%" % int(round(_controller.boost.energy * 100.0))
		_boost_value.add_theme_color_override("font_color", LUMINOUS_VIOLET)
	_assist_value.text = "ASSIST  /  ON" if _ship.intent.assist else "ASSIST  /  OFF"
	_assist_value.add_theme_color_override("font_color", COSMIC_PURPLE if _ship.intent.assist else MUTED_TEXT)
	_update_heading()


func _update_heading() -> void:
	var basis := _ship.get_global_transform_interpolated().basis.orthonormalized()
	var forward := -basis.z
	var heading_degrees: float = wrapf(rad_to_deg(atan2(forward.x, -forward.z)), 0.0, 360.0)
	var pitch_degrees: float = rad_to_deg(asin(clampf(forward.y, -1.0, 1.0)))
	var roll_degrees: float = rad_to_deg(atan2(basis.x.y, basis.y.y))
	var cardinal: String = "N" if heading_degrees < 22.5 or heading_degrees >= 337.5 else "E" if heading_degrees < 112.5 else "S" if heading_degrees < 202.5 else "W"
	_heading_label.text = "%03dÂ°  /  %s" % [int(round(heading_degrees)) % 360, cardinal]
	_pitch_roll_label.text = "PITCH  %+03dÂ°     ROLL  %+03dÂ°" % [int(round(pitch_degrees)), int(round(roll_degrees))]
	_heading_ribbon.heading_degrees = heading_degrees
	_heading_ribbon.queue_redraw()


func _resize_spatial_display() -> void:
	if _surface_viewport == null or get_viewport() == null:
		return
	var view_size := get_viewport().get_visible_rect().size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		return
	_surface_viewport.size = Vector2i(view_size)
	_rebuild_surface_panels()


func _render_preview() -> void:
	var heading: float = [0.0, 36.0, 126.0, 218.0, 302.0][_preview_state - 1]
	_heading_label.text = "%03dÂ°  /  %s" % [int(heading), ["N", "N", "E", "S", "W"][_preview_state - 1]]
	_pitch_roll_label.text = ["PITCH  +02Â°     ROLL  +00Â°", "PITCH  +05Â°     ROLL  +08Â°", "PITCH  -02Â°     ROLL  -04Â°", "PITCH  +01Â°     ROLL  +00Â°", "PITCH  -06Â°     ROLL  +13Â°"][_preview_state - 1]
	_heading_ribbon.heading_degrees = heading
	_heading_ribbon.queue_redraw()
	_speed_value.text = ["000", "286", "142", "094", "061"][_preview_state - 1]
	_speed_bar.value = [0.0, 0.82, 0.43, 0.28, 0.18][_preview_state - 1]
	_throttle_value.text = ["0%", "100%", "68%", "42%", "26%"][_preview_state - 1]
	_throttle_bar.value = [0.0, 1.0, 0.68, 0.42, 0.26][_preview_state - 1]
	_boost_bar.value = [1.0, 0.43, 0.72, 0.88, 0.18][_preview_state - 1]
	_boost_value.text = ["READY  Â·  100%", "BOOST ENGAGED", "READY  Â·  72%", "READY  Â·  88%", "RECHARGING"][_preview_state - 1]
	_boost_value.add_theme_color_override("font_color", MAGENTA if _preview_state == 5 else LUMINOUS_VIOLET)
	_assist_value.text = "ASSIST  /  ON"
	_target_name.text = "RELAY K-07  Â·  MOCK" if _preview_state == 3 else "NO TARGET LOCK"
	_target_name.add_theme_color_override("font_color", COSMIC_PURPLE if _preview_state == 3 else MUTED_TEXT)
	_target_distance.text = "18.4 KM  /  MOCK FEED" if _preview_state == 3 else "NAV FEED  /  UNAVAILABLE"
	if _preview_state == 4:
		_alert_value.text = "WARNING  /  HULL STRESS"
		_alert_value.add_theme_color_override("font_color", LUMINOUS_VIOLET)
	elif _preview_state == 5:
		_alert_value.text = "CRITICAL  /  MOCK ALERT"
		_alert_value.add_theme_color_override("font_color", MAGENTA)
	else:
		_alert_value.text = "ALERT FEED  /  NO DATA"
		_alert_value.add_theme_color_override("font_color", MUTED_TEXT)


func _refresh_preview_hint() -> void:
	_help_label.visible = _help_visible
	var banner := _root.get_node_or_null("PreviewBanner") as Label
	if banner != null:
		banner.text = "VISUAL PREVIEW  Â·  MOCK DATA  Â·  STATE %d  Â·  1â€“5 CHANGE  Â·  H TOGGLE HELP" % _preview_state


func _format_speed(speed: float) -> String:
	return "%03d" % int(round(maxf(speed, 0.0))) if speed < 1000.0 else "%.1fk" % (speed / 1000.0)


func _group(group_name: String, origin: Vector2, group_size: Vector2, radius: float, depth_level: int) -> Control:
	var backing := Panel.new()
	backing.name = group_name + "PanelFinish"
	backing.position = origin
	backing.size = group_size
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(GRAPHITE.r, GRAPHITE.g, GRAPHITE.b, 0.74 if depth_level == 0 else 0.82)
	style.border_color = Color(LUMINOUS_VIOLET.r, LUMINOUS_VIOLET.g, LUMINOUS_VIOLET.b, 0.48) if depth_level == 0 else Color(PURPLE_SURFACE.r, PURPLE_SURFACE.g, PURPLE_SURFACE.b, 0.62)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.18)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0.0, 2.0)
	backing.add_theme_stylebox_override("panel", style)
	_root.add_child(backing)
	var group := Control.new()
	group.name = group_name
	group.position = origin
	group.size = group_size
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(group)
	_register_surface_panel(group, Rect2(origin, group_size), radius)
	return group


func _register_surface_panel(panel: Control, source_rect: Rect2, radius: float) -> void:
	_surface_panels.append({"node": panel, "rect": source_rect, "radius": radius})


func _create_concave_backing() -> void:
	var backing := MeshInstance3D.new()
	backing.name = "ContinuousConcaveGlass"
	backing.mesh = _make_concave_mesh(12.3, 50.0, 10.6, 48)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(GRAPHITE.r, GRAPHITE.g, GRAPHITE.b, 0.12)
	backing.material_override = material
	backing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_surface_root.add_child(backing)


func _make_concave_mesh(radius: float, arc_degrees: float, height: float, segments: int) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var half_arc := deg_to_rad(arc_degrees)
	for step in range(segments + 1):
		var fraction := float(step) / float(segments)
		var theta := lerpf(-half_arc, half_arc, fraction)
		var surface_normal := Vector3(-sin(theta), 0.0, cos(theta))
		for row in range(2):
			var y := height * (0.5 if row == 1 else -0.5)
			vertices.append(Vector3(radius * sin(theta), y, -radius * cos(theta)))
			uvs.append(Vector2(fraction, 1.0 - float(row)))
			normals.append(surface_normal)
		if step < segments:
			var base := step * 2
			indices.append_array(PackedInt32Array([base, base + 2, base + 3, base, base + 3, base + 1]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _rebuild_surface_panels() -> void:
	if _surface_root == null or _ui_viewport == null or _surface_viewport == null:
		return
	for child in _surface_root.get_children():
		if child != _surface_camera and child.name != "ContinuousConcaveGlass":
			child.queue_free()
	var aspect := float(_surface_viewport.size.x) / maxf(float(_surface_viewport.size.y), 1.0)
	var vertical_fov := deg_to_rad(_surface_camera.fov)
	var horizontal_fov := 2.0 * atan(tan(vertical_fov * 0.5) * aspect)
	for item in _surface_panels:
		var control := item["node"] as Control
		if not is_instance_valid(control) or control.is_queued_for_deletion():
			continue
		var source_rect: Rect2 = item["rect"]
		var radius: float = item["radius"]
		var center_x := source_rect.position.x + source_rect.size.x * 0.5
		var center_y := source_rect.position.y + source_rect.size.y * 0.5
		var center_u := center_x / float(_ui_viewport.size.x)
		var theta := atan((center_u * 2.0 - 1.0) * tan(horizontal_fov * 0.5))
		var cos_theta := cos(theta)
		var sine_theta := sin(theta)
		var center_depth := radius * cos_theta
		var center_y_world := (0.5 - center_y / float(_ui_viewport.size.y)) * 2.0 * center_depth * tan(vertical_fov * 0.5)
		# Compensate for the shorter camera-space depth at the sides so the panels
		# remain inside their authored safe areas instead of ballooning toward the edges.
		var horizontal_scale := 2.0 * radius * cos_theta * cos_theta * tan(horizontal_fov * 0.5) / float(_ui_viewport.size.x)
		var vertical_scale := 2.0 * center_depth * tan(vertical_fov * 0.5) / float(_ui_viewport.size.y)
		var plane_size := Vector2(source_rect.size.x * horizontal_scale, source_rect.size.y * vertical_scale)
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = control.name + "SpatialPanel"
		mesh_instance.mesh = _make_panel_mesh(source_rect, plane_size)
		mesh_instance.position = Vector3(radius * sine_theta, center_y_world, -radius * cos_theta)
		var tangent := Vector3(cos_theta, 0.0, sine_theta)
		var normal := Vector3(-sine_theta, 0.0, cos_theta)
		mesh_instance.basis = Basis(tangent, Vector3.UP, normal)
		mesh_instance.material_override = _make_viewport_material()
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_surface_root.add_child(mesh_instance)


func _make_panel_mesh(source_rect: Rect2, plane_size: Vector2) -> ArrayMesh:
	var left := source_rect.position.x / float(_ui_viewport.size.x)
	var right := (source_rect.position.x + source_rect.size.x) / float(_ui_viewport.size.x)
	# ViewportTexture samples in viewport screen order: V=0 is the top row.
	var top := source_rect.position.y / float(_ui_viewport.size.y)
	var bottom := (source_rect.position.y + source_rect.size.y) / float(_ui_viewport.size.y)
	var vertices := PackedVector3Array([
		Vector3(-plane_size.x * 0.5, -plane_size.y * 0.5, 0.0),
		Vector3(plane_size.x * 0.5, -plane_size.y * 0.5, 0.0),
		Vector3(plane_size.x * 0.5, plane_size.y * 0.5, 0.0),
		Vector3(-plane_size.x * 0.5, plane_size.y * 0.5, 0.0),
	])
	var uvs := PackedVector2Array([Vector2(left, bottom), Vector2(right, bottom), Vector2(right, top), Vector2(left, top)])
	var normals := PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK])
	var indices := PackedInt32Array([0, 1, 2, 0, 2, 3])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _make_viewport_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_PREMULT_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_texture = _ui_viewport.get_texture()
	return material


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
	back.bg_color = Color(PURPLE_SURFACE.r, PURPLE_SURFACE.g, PURPLE_SURFACE.b, 0.20)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)
	return bar


class _HeadingRibbon:
	extends Control
	var heading_degrees: float = 0.0

	func _draw() -> void:
		var size := get_rect().size
		if size.x <= 0.0 or size.y <= 0.0:
			return
		var center := size.x * 0.5
		var baseline := size.y - 2.0
		draw_line(Vector2(0.0, baseline), Vector2(size.x, baseline), Color(MUTED_TEXT.r, MUTED_TEXT.g, MUTED_TEXT.b, 0.40), 1.0, true)
		for index in range(-6, 7):
			var degrees := wrapf(heading_degrees + index * 10.0, 0.0, 360.0)
			var x := center + index * 22.0
			var cardinal := int(round(degrees / 90.0)) % 4 == 0
			var tick_height := 15.0 if index == 0 else 9.0 if cardinal else 5.0
			draw_line(Vector2(x, baseline - tick_height), Vector2(x, baseline), Color(ICE_WHITE.r, ICE_WHITE.g, ICE_WHITE.b, 0.60), 1.0, true)
		draw_colored_polygon(PackedVector2Array([Vector2(center - 4.0, 0.0), Vector2(center + 4.0, 0.0), Vector2(center, 6.0)]), LUMINOUS_VIOLET)


class _FlightReticle:
	extends Control
	var color: Color = ICE_WHITE
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
		draw_circle(point, 1.5, LUMINOUS_VIOLET)



