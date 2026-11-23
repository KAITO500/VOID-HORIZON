extends Node3D
## Inspection scene for the Phase 01 space environment. Development tool only.
##
## Keys:  1 stars   2 nebulae   3 planet/backdrop   4 glow   V vsync   H hide HUD   R reset camera
## Camera: hold right mouse + move to look, WASD/QE to move, Shift faster, arrows also look.

const HUD_REFRESH_SECONDS: float = 0.25

@onready var _environment: SpaceEnvironment = $SpaceEnvironment
@onready var _camera: DebugFreeCamera = $Camera3D

var _label: Label
var _hud_timer: float = 0.0
var _vsync_on: bool = true


func _ready() -> void:
	_camera.far = maxf(_camera.far, _environment.get_required_far_plane())
	var layer := CanvasLayer.new()
	_label = Label.new()
	_label.position = Vector2(12.0, 8.0)
	_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	_label.add_theme_constant_override("outline_size", 4)
	layer.add_child(_label)
	add_child(layer)
	_refresh_hud()


func _process(delta: float) -> void:
	_hud_timer += delta
	if _hud_timer >= HUD_REFRESH_SECONDS:
		_hud_timer = 0.0
		_refresh_hud()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1:
			if _environment.star_field != null:
				_environment.star_field.visible = not _environment.star_field.visible
		KEY_2:
			for layer in _environment.nebula_layers:
				layer.visible = not layer.visible
		KEY_3:
			if _environment.backdrop != null:
				_environment.backdrop.visible = not _environment.backdrop.visible
		KEY_4:
			_environment.set_glow_enabled(not _environment.glow_enabled)
		KEY_V:
			_vsync_on = not _vsync_on
			DisplayServer.window_set_vsync_mode(
				DisplayServer.VSYNC_ENABLED if _vsync_on else DisplayServer.VSYNC_DISABLED)
		KEY_H:
			_label.visible = not _label.visible
		KEY_R:
			_camera.reset_view()


func _refresh_hud() -> void:
	var fps: float = Engine.get_frames_per_second()
	var frame_ms: float = 1000.0 / maxf(fps, 1.0)
	var draw_calls: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var objects: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	var primitives: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	_label.text = (
		"VOID HORIZON - Phase 01 environment test\n"
		+ "FPS %d   frame %.2f ms   vsync %s\n" % [int(fps), frame_ms, "on" if _vsync_on else "off"]
		+ "draw calls %d   objects %d   primitives %d\n" % [draw_calls, objects, primitives]
		+ "stars %s  nebulae %s  planet %s  glow %s\n" % [
			_on_off(_environment.star_field), _on_off_first_nebula(),
			_on_off(_environment.backdrop), "on" if _environment.glow_enabled else "off"]
		+ "[1] stars [2] nebulae [3] planet [4] glow [V] vsync [H] HUD [R] reset\n"
		+ "RMB+mouse look, WASD/QE move, Shift fast"
	)


func _on_off(node: Node3D) -> String:
	return "on" if node != null and node.visible else "off"


func _on_off_first_nebula() -> String:
	if _environment.nebula_layers.is_empty():
		return "none"
	return _on_off(_environment.nebula_layers[0])
