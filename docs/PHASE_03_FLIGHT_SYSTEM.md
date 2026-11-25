# Phase 03: Flight System (reference)

Status: **Implemented, NOT run in Godot.** No Godot binary was available to the author. The flight math was checked
with a Python re-implementation of the same equations (see Validation). Everything that touches the engine
(scene loading, input, camera, HUD, speed-streak shader, import of the GLB) remains pending a rendered review.

Branch: `feature/phase03-flight-system` (based on `main` after PR #3). Not merged. Not pushed unless stated in 06.

## Phase 02 check (done before building)
- PR #3 replaced the procedural ship with a custom GLB (`assets/models/ships/light_fighter_model.glb`). Its internal
  root node is named "VH-02 Vesper"; the Phase 03 prompt calls the ship "VH-01 WRAITH". Names disagree: ask the user.
- Orientation: the GLB was authored length-on-Y (standing up). PR #4 on main re-exported it (nose -Z, up +Y, bounds 15.2 x 3.5 x 19.0; verified headless in Godot 4.7.2 by another agent). My earlier scene rotation was removed in the merge (D-025 superseded). `Spaceship.validate()` still warns if the length is not along Z.
- The GLB has three rear engines (x = -3.75, 0, +3.75; z = 9.8). `EnginePoints` now has EngineLeft/EngineCenter/EngineRight there.
- Weapon points and collision boxes were NOT changed (Phase 04 / later). Collision boxes were sized for the old model.

## Architecture
```
Spaceship (CharacterBody3D, scripts/ships/spaceship.gd)   holds `intent: ShipIntent`
|- FlightInput      (scripts/flight/flight_input.gd)        human input -> intent. Local player only.
|- FlightController (scripts/flight/flight_controller.gd)   intent -> rotation + velocity -> move_and_slide
|     uses FlightMath (static math), FlightBoost (held overdrive), FlightConfig (data)
`- VisualRoot/EngineVisuals                                 set_visual_thrust() / set_visual_boost() (presentation)
FlightCamera (Camera3D, separate node)   chase camera, reads the ship
FlightHud    (CanvasLayer)               reads the controller, never writes
SpeedStreaks (CanvasLayer/ColorRect)     radial screen-space streaks, gated by ship speed
```
- Input and physics only talk through `ShipIntent`. AI or network code can fill the same object (D-009).
- Only the peer that owns the ship simulates it (`ShipNetworkState.is_owned_locally()`); no networking was written.
- `FlightMath`, `FlightBoost` and `FlightConfig` have no node dependencies, so they can be unit-tested and later reused on a server.

## Files
Created: `scripts/flight/` (flight_config, flight_math, flight_boost, flight_controller, flight_input, flight_input_map,
flight_camera, flight_hud, speed_streak_effect, flight_test_scene), `assets/materials/space/space_speed_streaks.gdshader`,
`resources/flight/light_fighter_flight.tres`, `scenes/flight/flight_test.tscn`, `tests/unit/phase03_flight_check.gd`.
Modified: `project.godot` (main scene, physics interpolation), `scenes/ships/light_fighter.tscn` (model rotation, 3 engines,
FlightController), `resources/ships/light_fighter.tres`, `scripts/ships/` (spaceship, ship_config, ship_intent,
ship_engine_visuals), `tests/unit/phase02_ship_check.gd` (3 engine points).

## Input map (registered at runtime by `FlightInputMap`; a Project Settings action with the same name wins)
| Action | Default |
|--------|---------|
| flight_throttle_up / down | W / S (S reverses up to 30% of max speed) |
| flight_pitch_up / down | Up / Down arrows, mouse Y (up = nose up) |
| flight_yaw_left / right | A, Left / D, Right, mouse X |
| flight_roll_left / right | Q / E |
| flight_boost | Shift (hold) |
| flight_brake | X (hold) |
| flight_toggle_assist | F |
| flight_toggle_hud_help | H |
| flight_release_mouse | Esc (click recaptures). Extra: R resets the ship in the test scene. |

Mouse is a virtual stick: motion deflects it, it recenters at 3/s. Pitch inversion: `FlightConfig.invert_pitch`.

## Flight parameters (`FlightConfig`, defaults; all first-pass guesses)
Speed: max 220 m/s, reverse 30%, hard cap 1200. Acceleration 90, deceleration 110, overspeed decel 60 m/s^2,
idle drag 0.12/s, lateral damping 1.6/s (assist), brake 160 m/s^2, throttle response 4/s.
Rotation: pitch 100, yaw 80, roll 160 deg/s, response 8/s, turn penalty 25% at max speed.
Overdrive (Shift held): x20 speed limit (4,400 m/s), x5 acceleration multiplier, no timer or energy lock. Release ramps the
overdrive effect down; space inertia preserves existing velocity. Hard speed cap 5,000 m/s. Camera (on the node): distance 26,
height 6.5, look-ahead 45, orientation follow 5/s,
FOV 70 (+6 speed, +6 boost), pull-back +4 m.

## Behavior notes
- Velocity model: forward thrust toward a target speed (`max_speed * throttle`), tapering near the target. Sideways velocity
  is removed at `lateral_damping` while assist is ON; assist OFF gives Newtonian drift. Zero throttle coasts with `idle_drag`.
- Holding Shift forces full forward throttle and sustained overdrive until release. Rotation is ship-local angular velocity with exponential smoothing, applied as
  quaternion-safe basis rotation and re-orthonormalized every tick.
- Camera: orientation lags, position does not; no shake. Uses `get_global_transform_interpolated()` in `_process` with
  physics interpolation enabled (D-028).
- Speed streaks are off below 900 m/s and fade in toward 4,200 m/s. They are radial screen-space segments moving from the center toward the edges; the old always-visible dust point field is removed.
- Collisions: `move_and_slide()` slides along surfaces. There is nothing to hit in the test scene yet.

## Run it
Open the project in Godot 4.7.2 and press F5 (main scene is `scenes/flight/flight_test.tscn`, D-029). The mouse is captured.
Fly through the gates. `scenes/ships/ship_inspection.tscn` (F6) still shows the model views; check the ship orientation there first.
Headless check (after one `--import`): `godot --headless --path . -s res://tests/unit/phase03_flight_check.gd`.

## Validation performed
- Python re-implementation of `FlightMath.step_velocity` and `FlightBoost` (same equations, default parameters):
  0 -> 95% of normal max speed in 2.42 s; braking from 220 m/s in 1.38 s; speed at t=8 s differs <1% between
  30, 60 and 144 FPS steps (frame-rate independent); a 90 degree turn at full speed bleeds sideways velocity (45 m/s left after 0.5 s).
  These values predate the sustained-overdrive tuning and do not validate the current 4,400 m/s setting.
- Static review: tab indentation, bracket balance, all `res://` paths exist, GDScript reviewed by hand for known pitfalls
  (a member named `_input` was found and renamed).
- Orientation of the new GLB re-checked from its glTF nodes after the merge (extents 15.2 x 3.5 x 19.0, engines at x -3.75/0/3.75, z 9.15, bay above the hull).
## NOT performed
For the current sustained-overdrive tuning: Godot run, headless GDScript checks, rendered flight, HUD layout review, speed-streak shader compilation/visual feel, camera feel and FOV tuning, collision fit and performance.

### Travel tuning update (2026-11-25)

After the planetary fixture proved too distant to reach with the original four-second boost, Shift became a sustained overdrive control. The Khepri test fixture moved from 230 km to 85 km ahead. This makes the current approach test reachable with continuous high-speed flight; it does not implement a teleporting or interstellar hyperspace jump. A dedicated jump mechanic remains in Phase 08.

## Known limits
See `docs/shared_context/07_KNOWN_ISSUES.md` KI-016 to KI-022.
