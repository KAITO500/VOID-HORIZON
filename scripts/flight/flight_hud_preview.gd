extends Node3D
## Visual-only HUD state selector. Preview values are explicitly labeled as mock data.


func _ready() -> void:
	var hud := get_node_or_null("FlightTest/FlightHud") as FlightHud
	if hud != null:
		hud.set_visual_preview(true)

