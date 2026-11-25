class_name FlightHud
extends CanvasLayer
## Temporary, deliberately simple 2D readout. Reads flight/navigation state only.

const PANEL_BG := Color(0.025, 0.035, 0.045, 0.82)
const PANEL_LINE := Color(0.62, 0.53, 0.37, 0.82)
const TEXT_MAIN := Color(0.91, 0.90, 0.84)
const TEXT_MUTED := Color(0.62, 0.64, 0.63)
const TEXT_ACCENT := Color(0.86, 0.65, 0.39)

@export var ship_path: NodePath
@export var camera_path: NodePath
@export var telemetry_path: NodePath
@export var target_manager_path: NodePath
@export var waypoint_manager_path: NodePath
@export var coordinate_system_path: NodePath
@export var planetary_approach_path: NodePath

var _ship: Spaceship
var _controller: FlightController
var _camera: Camera3D
var _telemetry: NavigationTelemetry
var _target_manager: NavigationTargetManager
var _waypoint_manager: NavigationWaypointManager
var _coordinate_system: SpaceCoordinateSystem
var _planetary_approach: PlanetaryApproachController

var _speed_value: Label
var _heading_value: Label
var _thrust_value: Label
var _boost_value: Label
var _target_name: Label
var _target_distance: Label
var _planetary_state_label: Label
var _planetary_altitude_label: Label
var _crosshair: _SimpleReticle


func _ready() -> void:
	layer = 10
	_ship = get_node_or_null(ship_path) as Spaceship
	_camera = get_node_or_null(camera_path) as Camera3D
	_telemetry = get_node_or_null(telemetry_path) as NavigationTelemetry
	_target_manager = get_node_or_null(target_manager_path) as NavigationTargetManager
	_waypoint_manager = get_node_or_null(waypoint_manager_path) as NavigationWaypointManager
	_coordinate_system = get_node_or_null(coordinate_system_path) as SpaceCoordinateSystem
	_planetary_approach = get_node_or_null(planetary_approach_path) as PlanetaryApproachController
	if _ship != null:
		_controller = _ship.get_node_or_null("FlightController") as FlightController
	_build_hud()
	_update_hud()


func _process(_delta: float) -> void:
	_update_hud()


func _build_hud() -> void:
	var root := Control.new()
	root.name = "SimpleHud"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var flight_panel := _make_panel(root, "FlightReadout", Vector2(20.0, 20.0), Vector2(250.0, 128.0))
	_add_label(flight_panel, "VH-01  /  WRAITH", 13, TEXT_ACCENT)
	_speed_value = _add_label(flight_panel, "SPEED  --- M/S", 16, TEXT_MAIN)
	_heading_value = _add_label(flight_panel, "HEADING  ---°", 12, TEXT_MUTED)
	_thrust_value = _add_label(flight_panel, "THRUST  --%", 12, TEXT_MUTED)
	_boost_value = _add_label(flight_panel, "BOOST  ---%", 12, TEXT_MUTED)

	var nav_panel := _make_panel(root, "NavigationReadout", Vector2(-290.0, 20.0), Vector2(270.0, 100.0), true)
	_add_label(nav_panel, "NAVIGATION", 11, TEXT_ACCENT)
	_target_name = _add_label(nav_panel, "NO TARGET SELECTED", 13, TEXT_MAIN, HORIZONTAL_ALIGNMENT_RIGHT)
	_target_distance = _add_label(nav_panel, "TAB: CYCLE DESTINATION", 11, TEXT_MUTED, HORIZONTAL_ALIGNMENT_RIGHT)

	var planet_panel := _make_panel(root, "PlanetReadout", Vector2(-290.0, -132.0), Vector2(270.0, 112.0), true, true)
	_add_label(planet_panel, "PLANETARY APPROACH", 11, TEXT_ACCENT, HORIZONTAL_ALIGNMENT_RIGHT)
	_planetary_state_label = _add_label(planet_panel, "SPACE  /  NO PLANET", 13, TEXT_MAIN, HORIZONTAL_ALIGNMENT_RIGHT)
	_planetary_altitude_label = _add_label(planet_panel, "ALTITUDE  /  --", 11, TEXT_MUTED, HORIZONTAL_ALIGNMENT_RIGHT)

	_crosshair = _SimpleReticle.new()
	_crosshair.name = "Reticle"
	_crosshair.anchor_left = 0.5
	_crosshair.anchor_right = 0.5
	_crosshair.anchor_top = 0.5
	_crosshair.anchor_bottom = 0.5
	_crosshair.offset_left = -18.0
	_crosshair.offset_right = 18.0
	_crosshair.offset_top = -18.0
	_crosshair.offset_bottom = 18.0
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_crosshair)


func _make_panel(root: Control, panel_name: String, offset: Vector2, panel_size: Vector2, right_aligned: bool = false, bottom_aligned: bool = false) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.size = panel_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = PANEL_LINE
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)
	if right_aligned:
		panel.anchor_left = 1.0
		panel.anchor_right = 1.0
	if bottom_aligned:
		panel.anchor_top = 1.0
		panel.anchor_bottom = 1.0
	panel.offset_left = offset.x
	panel.offset_top = offset.y
	panel.offset_right = offset.x + panel_size.x
	panel.offset_bottom = offset.y + panel_size.y
	root.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(stack)
	return stack


func _add_label(parent: Control, value: String, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _update_hud() -> void:
	if _ship == null or _controller == null:
		return
	var sample: NavigationTelemetrySnapshot = _telemetry.snapshot if _telemetry != null else null
	var speed: float = sample.speed_mps if sample != null else _controller.get_speed()
	_speed_value.text = "SPEED  %s M/S" % _format_number(speed)
	if sample != null and sample.heading_valid:
		_heading_value.text = "HEADING  %03d°  /  PITCH %+03d°" % [int(round(sample.heading_degrees)) % 360, int(round(sample.pitch_degrees))]
	else:
		_heading_value.text = "HEADING  ---°"
	var boost_percent: int = int(round(_controller.boost.energy * 100.0))
	var thrust: float = _ship.network_state.thrust if _ship.network_state != null else clampf(_controller.throttle, 0.0, 1.0)
	_thrust_value.text = "THRUST  %d%%" % int(round(clampf(thrust, 0.0, 1.0) * 100.0))
	_boost_value.text = "BOOST  %s  /  %d%%" % ["ACTIVE" if _controller.boost.active else "READY", boost_percent]
	_update_navigation(sample)
	_update_planetary_approach()


func _update_navigation(sample: NavigationTelemetrySnapshot) -> void:
	if _target_manager == null or _coordinate_system == null or sample == null:
		_target_name.text = "NAVIGATION OFFLINE"
		_target_distance.text = "NO TELEMETRY"
		return
	var target := _target_manager.get_selected_target()
	if target != null:
		_target_name.text = target.display_name.to_upper()
		_update_target_metrics(target.resolve_position(SpaceCoordinateSystem.ROOT_FRAME), sample)
		return
	var waypoint := _waypoint_manager.get_active_waypoint() if _waypoint_manager != null else null
	if waypoint != null:
		_target_name.text = "WAYPOINT  /  %s" % waypoint.display_name.to_upper()
		_update_target_metrics(waypoint.position, sample)
	else:
		_target_name.text = "NO TARGET SELECTED"
		_target_distance.text = "TAB: CYCLE DESTINATION"


func _update_target_metrics(target_position: SpatialPosition, sample: NavigationTelemetrySnapshot) -> void:
	var distance_m: float = _coordinate_system.distance_between(sample.position, target_position)
	if distance_m < 0.0:
		_target_distance.text = "DESTINATION UNAVAILABLE"
	elif distance_m < 0.01:
		_target_distance.text = "DESTINATION REACHED"
	else:
		var direction: Vector3 = _coordinate_system.direction_between(sample.position, target_position)
		var bearing: float = wrapf(rad_to_deg(atan2(direction.dot(sample.right), direction.dot(sample.forward))), -180.0, 180.0)
		_target_distance.text = "%s  /  %+03.0f°" % [_format_distance(distance_m), bearing]


func _update_planetary_approach() -> void:
	if _planetary_approach == null or _planetary_approach.snapshot == null:
		_planetary_state_label.text = "SPACE  /  NO PLANET"
		_planetary_altitude_label.text = "ALTITUDE  /  --"
		return
	var approach: PlanetaryApproachSnapshot = _planetary_approach.snapshot
	_planetary_state_label.text = "%s  /  %02d%%" % [approach.state_name, int(round(approach.atmosphere_progress * 100.0))]
	_planetary_altitude_label.text = "%s  /  ALT %s" % [approach.planet_name.to_upper(), _format_distance(absf(approach.altitude_m))]


func _format_number(value: float) -> String:
	return "%.0f" % value


func _format_distance(distance_m: float) -> String:
	return "%.1f KM" % (distance_m / 1000.0) if absf(distance_m) >= 1000.0 else "%.0f M" % distance_m


class _SimpleReticle:
	extends Control
	func _draw() -> void:
		var color := Color(0.86, 0.72, 0.49, 0.82)
		draw_line(Vector2(18.0, 2.0), Vector2(18.0, 11.0), color, 1.0)
		draw_line(Vector2(18.0, 25.0), Vector2(18.0, 34.0), color, 1.0)
		draw_line(Vector2(2.0, 18.0), Vector2(11.0, 18.0), color, 1.0)
		draw_line(Vector2(25.0, 18.0), Vector2(34.0, 18.0), color, 1.0)
		draw_circle(Vector2(18.0, 18.0), 1.5, color)
