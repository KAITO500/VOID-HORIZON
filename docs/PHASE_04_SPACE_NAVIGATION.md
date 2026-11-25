# Phase 04 — Space Navigation

**Status: IMPLEMENTED.** Headless functional checks pass in Godot 4.7.2. Interactive visual and hardware performance review remain open, so this phase is not marked VERIFIED.

## Scope

Adds scene-local navigation services to the Phase 03 flight test without replacing or changing flight physics, camera behavior, or existing flight controls. The current F5 scene includes three visible navigation beacons as testbed POIs; these are fixtures, not procedural universe content.

## Architecture

```text
SpaceNavigation
├── Coordinates       SpaceCoordinateSystem
├── Registry          NavigationTargetRegistry
├── Telemetry         NavigationTelemetry ──reads──> Spaceship
├── TargetManager     NavigationTargetManager ──uses──> Registry
├── WaypointManager   NavigationWaypointManager ──uses──> Registry + Coordinates
└── NavigationInput   navigation-only InputMap actions

FlightHud reads telemetry, target and waypoint services.
NavigationHudOverlay reads POIs and projects markers through FlightCamera.
```

### Coordinates

`SpatialPosition` stores a `Vector3` plus a named frame ID. `SpaceCoordinateSystem` maintains a scene-local tree of named reference frames and `Transform3D` transforms to their parents. It converts positions between frames and provides distance and direction helpers. The root frame is `universe`; scene `global_position` values use that frame.

This is a lightweight frame-conversion layer, not a precision upgrade. It retains Godot `Vector3` precision and does not rebase the world. No floating origin or double-precision build is introduced. Keep current navigation distances local; revisit precision before placing objects at interstellar distances.

### Live telemetry

`NavigationTelemetry` samples the actual `Spaceship` in physics updates and emits `telemetry_updated`. Its `NavigationTelemetrySnapshot` contains world position, velocity, speed magnitude, movement direction, signed forward speed, ship forward/right/up axes, quaternion orientation, heading, pitch, roll and a `heading_valid` flag. When the nose points vertically, compass heading is reported invalid rather than inventing a horizontal bearing.

Facing and travel direction are separate values. This allows the HUD and future systems to show drift without changing the Phase 03 controller.

### POIs and targets

`NavigationTarget` is presentation-independent data: unique ID, display name, category, position, discovery state and navigation visibility. It can hold a static framed position or bind to a live `Node3D` through a weak reference. The registry rejects duplicate IDs and filters by category, discovery and visibility. The target manager selects, cycles, cancels and clears a destination when it becomes hidden, unavailable, or its source node disappears.

The testbed beacons demonstrate node-backed registration. Later planetary/system generation can register its own targets through the same API without changing the HUD.

### Waypoints

`NavigationWaypointManager` stores an ordered route of waypoint resources. A waypoint can hold a framed coordinate or refer to a live registered target. It supports set, replace, clear, query and advancing to the next route point. It does not steer the ship or implement autopilot.

Default navigation bindings are registered only if the actions do not already exist:

| Input | Action |
|---|---|
| Tab | Select next visible/discovered POI |
| Shift+Tab | Select previous POI |
| Backspace | Clear target selection |
| Enter | Set waypoint to selected target |
| Delete | Clear waypoint route |

### HUD

The temporary Flight HUD reads speed, heading and attitude from telemetry, and displays the selected target or active waypoint with live distance and relative bearing. A small screen-space overlay refreshes at 30 Hz and draws POI and waypoint markers only when they are in front of the camera and within the viewport. Off-screen targets remain readable through the bearing readout. The HUD does not write to flight state.

## Files

**Created:**

- `scripts/navigation/spatial_position.gd`
- `scripts/navigation/space_coordinate_system.gd`
- `scripts/navigation/navigation_telemetry_snapshot.gd`
- `scripts/navigation/navigation_telemetry.gd`
- `scripts/navigation/navigation_target.gd`
- `scripts/navigation/navigation_target_registry.gd`
- `scripts/navigation/navigation_target_manager.gd`
- `scripts/navigation/navigation_waypoint.gd`
- `scripts/navigation/navigation_waypoint_manager.gd`
- `scripts/navigation/navigation_input.gd`
- `scripts/navigation/navigation_hud_overlay.gd`
- `scripts/navigation/navigation_poi_beacon.gd`
- `scenes/navigation/space_navigation.tscn`
- `tests/unit/phase04_navigation_check.gd`

**Modified:**

- `scenes/flight/flight_test.tscn` — adds navigation services, test beacons and marker overlay.
- `scripts/flight/flight_hud.gd` — consumes telemetry and navigation services.
- `tests/unit/phase03_hud_check.gd` — refreshes the live telemetry sample after changing test velocity.
- `docs/PHASE_03_WRAITH_FLIGHT_HUD.md` — records the navigation data source.
- `docs/shared_context/03_DECISIONS_LOG.md`, `04_DEVELOPMENT_ROADMAP.md`, `05_CURRENT_PROJECT_STATE.md`, `06_HANDOFF_REPORT.md`, `07_KNOWN_ISSUES.md`.

## Validation

Godot `4.7.2.stable.official`:

- `phase01_math_check.gd` — PASS.
- `phase02_ship_check.gd` — PASS.
- `phase03_flight_check.gd` — PASS.
- `phase03_hud_check.gd` — PASS.
- `phase04_navigation_check.gd` — PASS. Covers nested frame conversion, invalid frames, live velocity and orientation, vertical heading singularity, POI category/visibility/uniqueness, target selection/cycling/cancellation/removal, waypoint replacement/routes, HUD telemetry and marker movement.
- F5 main-scene headless startup for five frames — exit 0, no console errors.

Not performed: rendered-window visual review, user flight test, hardware FPS/GPU profiling, planet generation integration, or network validation.

## Known limits / Phase 05 dependencies

- Coordinates still use single-precision vectors. Phase 05 should keep planetary approach transforms close to a local frame and decide when rebasing becomes necessary.
- The registry is in-memory and scene-local; save/load, universe streaming and server authority are later work.
- The three beacons are F5 fixtures. No real planets or stations are registered yet.
- The overlay intentionally omits edge arrows for off-screen targets; the target panel still reports bearing and elevation.
- Coordinate conversion uses rigid transforms and does not model orbital mechanics or gravity.
- Visual legibility and performance need review in the Godot window on the user's display/GPU.
