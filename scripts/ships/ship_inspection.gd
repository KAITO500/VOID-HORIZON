extends Node3D
## Inspection scene for the Light Fighter inside the Phase 01 environment. Development tool only.
##
## Keys:  1 front  2 right side  3 rear  4 top  5 hero (ship against the planet)
##        C collision shapes   M attachment points   E engine thrust (off/idle/full)   H hide HUD
## Mouse: hold right button and move to orbit, wheel to zoom.

const VIEWS: Dictionary = {
	"front": Vector3(0.0, 0.0, 32.0),
	"side": Vector3(90.0, 0.0, 32.0),
	"rear": Vector3(180.0, 0.0, 32.0),
	"top": Vector3(0.0, 80.0, 40.0),
	"hero": Vector3(150.0, -8.0, 34.0),
}
const THRUST_STEPS: Array[float] = [0.0, 0.35, 1.0]

@onready var _ship: Spaceship = $LightFighter
@onready var _camera: ShipInspectionCamera = $Camera3D
@onready var _environment: SpaceEnvironment = $SpaceEnvironment

var _label: Label
var _view_name: String = "hero"
var _thrust_index: int = 1
var _collision_overlays: Array[MeshInstance3D] = []
var _marker_overlays: Array[Node3D] = []


func _ready() -> void:
	_camera.far = maxf(_camera.far, _environment.get_required_far_plane())
	var canvas := CanvasLayer.new()
	_label = Label.new()
	_label.position = Vector2(12.0, 8.0)
	_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	_label.add_theme_constant_override("outline_size", 4)
	canvas.add_child(_label)
	add_child(canvas)

	_build_collision_overlays()
	_build_marker_overlays()
	_ship.set_visual_thrust(THRUST_STEPS[_thrust_index])
	_set_view("hero")


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1:
			_set_view("front")
		KEY_2:
			_set_view("side")
		KEY_3:
			_set_view("rear")
		KEY_4:
			_set_view("top")
		KEY_5:
			_set_view("hero")
		KEY_C:
			_toggle(_collision_overlays)
		KEY_M:
			_toggle(_marker_overlays)
		KEY_E:
			_thrust_index = (_thrust_index + 1) % THRUST_STEPS.size()
			_ship.set_visual_thrust(THRUST_STEPS[_thrust_index])
		KEY_H:
			_label.visible = not _label.visible
	_refresh_hud()


func _set_view(view_name: String) -> void:
	_view_name = view_name
	var view: Vector3 = VIEWS[view_name]
	_camera.set_view(view.x, view.y, view.z)
	_refresh_hud()


func _toggle(overlays: Array) -> void:
	for overlay in overlays:
		overlay.visible = not overlay.visible


func _build_collision_overlays() -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.2, 1.0, 0.3)
	material.no_depth_test = true
	for collision in _ship.get_collision_shapes():
		if collision.shape == null:
			continue
		var overlay := MeshInstance3D.new()
		overlay.name = "DebugShape"
		overlay.mesh = collision.shape.get_debug_mesh()
		overlay.material_override = material
		overlay.visible = false
		collision.add_child(overlay)
		_collision_overlays.append(overlay)


func _build_marker_overlays() -> void:
	for marker in _ship.get_engine_points():
		_marker_overlays.append(_add_marker_overlay(marker, Color(0.1, 0.8, 1.0)))
	for marker in _ship.get_weapon_points():
		_marker_overlays.append(_add_marker_overlay(marker, Color(1.0, 0.3, 0.2)))
	if _ship.camera_target != null:
		_marker_overlays.append(_add_marker_overlay(_ship.camera_target, Color(0.3, 1.0, 0.4)))


func _add_marker_overlay(marker: Marker3D, color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Overlay"

	var sphere := SphereMesh.new()
	sphere.radius = 0.25
	sphere.height = 0.5
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.no_depth_test = true
	var dot := MeshInstance3D.new()
	dot.mesh = sphere
	dot.material_override = material
	root.add_child(dot)

	# Arrow along the marker's -Z axis (emission/firing direction).
	var arrow_mesh := CylinderMesh.new()
	arrow_mesh.top_radius = 0.0
	arrow_mesh.bottom_radius = 0.12
	arrow_mesh.height = 1.2
	var arrow := MeshInstance3D.new()
	arrow.mesh = arrow_mesh
	arrow.material_override = material
	arrow.rotation_degrees = Vector3(-90.0, 0.0, 0.0) # cylinder +Y -> -Z
	arrow.position = Vector3(0.0, 0.0, -0.8)
	root.add_child(arrow)

	var text := Label3D.new()
	text.text = String(marker.name)
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	text.no_depth_test = true
	text.fixed_size = true
	text.pixel_size = 0.0006
	text.modulate = color
	text.position = Vector3(0.0, 0.6, 0.0)
	root.add_child(text)

	marker.add_child(root)
	return root


func _refresh_hud() -> void:
	var problems: PackedStringArray = _ship.validate()
	var config: ShipConfig = _ship.config
	var lines: PackedStringArray = PackedStringArray()
	lines.append("VOID HORIZON - Phase 02 ship inspection")
	if config != null:
		lines.append("%s  (id %s)  balance values are PLACEHOLDERS: %s" % [
			config.display_name, config.ship_id, config.is_placeholder_balance])
	lines.append("view: %s   thrust: %.2f" % [_view_name, THRUST_STEPS[_thrust_index]])
	lines.append("ship validation: %s" % ("OK" if problems.is_empty() else "; ".join(problems)))
	lines.append("[1] front [2] side [3] rear [4] top [5] hero  [C] collision [M] points [E] engines [H] HUD")
	lines.append("right mouse drag: orbit   wheel: zoom")
	_label.text = "\n".join(lines)
