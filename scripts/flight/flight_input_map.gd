class_name FlightInputMap
extends RefCounted
## Registers the flight InputMap actions at runtime if they do not exist yet.
## A project-level InputMap entry with the same name wins (players/devs can rebind in Project Settings).

const ACTIONS: Dictionary = {
	&"flight_throttle_up": [KEY_W],
	&"flight_throttle_down": [KEY_S],
	&"flight_yaw_left": [KEY_A, KEY_LEFT],
	&"flight_yaw_right": [KEY_D, KEY_RIGHT],
	&"flight_pitch_up": [KEY_UP],
	&"flight_pitch_down": [KEY_DOWN],
	&"flight_roll_left": [KEY_Q],
	&"flight_roll_right": [KEY_E],
	&"flight_boost": [KEY_SHIFT],
	&"flight_brake": [KEY_X],
	&"flight_toggle_assist": [KEY_F],
	&"flight_toggle_hud_help": [KEY_H],
	&"flight_release_mouse": [KEY_ESCAPE],
}


static func ensure_actions() -> void:
	for action: StringName in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
			for keycode: int in ACTIONS[action]:
				var event := InputEventKey.new()
				event.physical_keycode = keycode as Key
				InputMap.action_add_event(action, event)
