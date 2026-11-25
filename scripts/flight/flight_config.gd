class_name FlightConfig
extends Resource
## All tunable flight parameters for one ship type (Phase 03). Pure data, no logic.
##
## Units: meters, seconds, degrees per second (converted to radians in FlightMath).
## Values are a FIRST PASS chosen for an arcade feel on a ~19 m ship. They were never flown
## by a human yet (see docs/PHASE_03_FLIGHT_SYSTEM.md); expect to tune them.

@export_group("Speed")
## Forward speed reached at full throttle without boost (m/s).
@export_range(10.0, 2000.0, 1.0) var max_speed: float = 220.0
## Reverse top speed as a fraction of max_speed.
@export_range(0.0, 1.0, 0.01) var reverse_speed_fraction: float = 0.3
## Absolute safety cap, applied after everything else (m/s).
@export_range(100.0, 10000.0, 1.0) var hard_speed_cap: float = 5000.0

@export_group("Acceleration and inertia")
## Forward acceleration at full throttle (m/s^2).
@export_range(1.0, 1000.0, 1.0) var acceleration: float = 90.0
## Deceleration when the throttle is lowered or reversed (m/s^2).
@export_range(1.0, 1000.0, 1.0) var deceleration: float = 110.0
## Deceleration while over the speed limit, e.g. right after a boost ends (m/s^2).
@export_range(1.0, 1000.0, 1.0) var overspeed_deceleration: float = 60.0
## Coasting drag with zero throttle (1/s). 0 = pure Newtonian inertia.
@export_range(0.0, 5.0, 0.01) var idle_drag: float = 0.12
## Sideways velocity removal while flight assist is ON (1/s). 0 = pure drift, high = on rails.
@export_range(0.0, 20.0, 0.05) var lateral_damping: float = 1.6
## Brake key: linear deceleration of the whole velocity (m/s^2).
@export_range(1.0, 2000.0, 1.0) var brake_deceleration: float = 160.0
## Fraction of max_speed over which thrust tapers off when approaching the target speed.
@export_range(0.01, 1.0, 0.01) var approach_band: float = 0.12
## Lowest taper multiplier (keeps the target speed reachable).
@export_range(0.01, 1.0, 0.01) var min_taper: float = 0.1
## How fast the throttle follows the input (1/s). Lower = softer acceleration.
@export_range(0.5, 30.0, 0.1) var throttle_response: float = 4.0

@export_group("Rotation")
@export_range(1.0, 360.0, 1.0) var pitch_rate_deg: float = 100.0
@export_range(1.0, 360.0, 1.0) var yaw_rate_deg: float = 80.0
@export_range(1.0, 720.0, 1.0) var roll_rate_deg: float = 160.0
## How quickly angular velocity follows the requested rate (1/s). Higher = snappier.
@export_range(0.5, 40.0, 0.1) var rotation_response: float = 8.0
## At max speed turn rates are multiplied by (1 - this). Keeps high speed stable.
@export_range(0.0, 0.9, 0.01) var speed_turn_penalty: float = 0.25

@export_group("Input feel")
## Mouse pixels to virtual stick deflection (1.0 = full rate). 0.004 -> 250 px for full deflection.
@export_range(0.0001, 0.05, 0.0001) var mouse_sensitivity: float = 0.004
## Virtual stick return to center (1/s). 0 = the stick stays where the mouse left it.
@export_range(0.0, 20.0, 0.1) var mouse_recenter_rate: float = 3.0
## Keyboard rotation axes ramp (units/s) so taps are gentle and holds are full.
@export_range(1.0, 50.0, 0.5) var key_axis_ramp: float = 7.0
@export var invert_pitch: bool = false

@export_group("Boost")
@export_range(1.0, 30.0, 0.05) var boost_speed_multiplier: float = 20.0
@export_range(1.0, 12.0, 0.05) var boost_acceleration_multiplier: float = 5.0
## Overdrive strength ramp up / down (1/s). Shift sustains it until released.
@export_range(0.5, 30.0, 0.1) var boost_ramp_up: float = 5.0
@export_range(0.5, 30.0, 0.1) var boost_ramp_down: float = 2.5
