# Phase 05 — Planetary Approach

**Status:** IMPLEMENTED — headless logic and scene startup checks pass; rendered review and hardware performance review remain open.
**Updated:** 2026-11-25
**Engine:** Godot 4.7.2, Forward+

## Scope

Adds physical-scale planetary approach, atmosphere-state telemetry, a low-cost configurable atmospheric limb and reversible sky tint. The system observes existing WRAITH telemetry and does not write ship movement, orientation, boost, input or camera state. The Phase 01 apparent-size `CelestialBackdrop` stays a distant visual backdrop and is not reused as an approachable body. No procedural terrain, gravity, aerodynamic drag, landing or streaming is included.

## Architecture

- `PlanetProfile` (`resources/planets/planet_profile.gd`) contains an ID, name, availability, radius, atmosphere height, approach/orbital radius ratios, hysteresis, transition progress thresholds, surface appearance and atmosphere settings. Tune a `.tres` resource instead of changing gameplay code.
- `PlanetaryBody` (`scripts/planetary/planetary_body.gd`) builds a lit sphere and transparent atmosphere shell from the profile. It registers a live `NavigationTarget.Category.PLANET` in the existing Phase 04 registry and unregisters on exit.
- `PlanetaryApproachController` samples `NavigationTelemetry`, prefers a selected planet destination and otherwise tracks the nearest available planet. It publishes `PlanetaryApproachSnapshot` with center distance, theoretical altitude, atmosphere-boundary distance, direction, approach/atmosphere progress and state.
- State IDs are `SPACE`, `PLANET_APPROACH`, `ORBITAL_REGION`, `ATMOSPHERE_ENTRY`, `ATMOSPHERE_TRANSITION` and `ATMOSPHERE_ACTIVE`. Per-profile thresholds use radius and atmosphere height. Boundary hysteresis uses the configured metres. Segment/sphere intersections enumerate intermediate bands, including a fast pass that begins and ends in `SPACE`.
- `SpaceEnvironment.set_atmosphere_transition()` subtly blends the existing sky gradient and ambient color, then restores their base settings on egress. The planet shell supplies the visible limb. It does not replace the existing world environment or camera.
- The temporary basic HUD shows planet/state, atmosphere progress and theoretical altitude. Existing navigation target data continues to provide destination name, distance and bearing.

## Test setup

`scenes/flight/flight_test.tscn` includes Khepri, a fixture at `(0, 0, -230000)` with 24 km radius and 6.2 km atmosphere. It is both the normal F5 flight test and the integration fixture. `scenes/planetary/planetary_approach_test.tscn` is a named scene entry point that instances that test setup. The three existing POIs remain present; the planet is an additional navigable target.

With the default forward (-Z) heading, Khepri is ahead. Use the existing navigation target cycle to select it; approach is classified relative to the configured 192 km approach boundary, 60 km orbital boundary, and 30.2 km atmosphere boundary. Atmosphere progress reaches 1 at the theoretical surface. No collision mesh or surface interaction is implied.

## Validation

`tests/unit/phase05_planetary_approach_check.gd` checks resource scale, target registration/selection, distance, altitude, all inward states, progress, shell/sky blend, boundary hysteresis, outward states, fast traversal and preservation of ship position, velocity, assist control, orientation and camera. `tests/unit/phase05_planetary_scene_check.gd` checks that the dedicated entry scene wires the WRAITH, camera, HUD and navigation telemetry. Repeated runs timed 300 headless telemetry samples at 0.013–0.016 ms/sample average in this sandbox. That excludes GPU rendering, scene-wide cost and target-PC profiling.

The F5 integration scene starts headlessly under Godot 4.7.2. Existing phase checks for Phases 01–03 passed. Phase 04's target-count assertion was updated to include the new planet category. Rendered visual review, actual player-controlled flight through the shell, audio/VFX tuning and hardware profiling have not been performed. Therefore Phase 05 is **IMPLEMENTED**, not **VERIFIED**.

## Precision and performance

The current world uses single-precision Godot `Vector3` positions in metres. This fixture spans hundreds of kilometres, within the current camera/test scale, and no Large World Coordinates setting or floating origin was enabled. A complete planet-scale surface plus interstellar coordinates will need a precision and rebasing design before Phase 06/08. Approach geometry uses five analytic segment/sphere boundary tests per sample; controller sampling is throttled to 30 Hz. The atmosphere is one sphere shell and does not use screen-space scattering or particle fields.

## Files

- Added: `resources/planets/planet_profile.gd`, `resources/planets/wraith_test_world.tres`, `scripts/planetary/planetary_approach_snapshot.gd`, `scripts/planetary/planetary_approach_controller.gd`, `scripts/planetary/planetary_body.gd`, `scripts/planetary/planetary_atmosphere.gdshader`, `scenes/planetary/planetary_approach_test.tscn`, `tests/unit/phase05_planetary_approach_check.gd`.
- Modified: `scripts/environment/space_environment.gd`, `scripts/flight/flight_hud.gd`, `scenes/flight/flight_test.tscn`, `tests/unit/phase04_navigation_check.gd`, shared architecture/roadmap/current state/handoff/known issues.

## Phase 06 and 07 contracts

Phase 06 should supply visual/surface data through `PlanetProfile` or a deliberate compatible extension; `PlanetaryBody` currently owns only a basic sphere and shell. Terrain and atmosphere meshes must share the profile's radius and world center with the approach controller.

Phase 07 may add arcade gravity, drag, descent and landing as separate flight/environment components. Keep the existing ship root, `FlightController`, `FlightCamera`, `NavigationTelemetry`, and approach snapshot contracts stable. Any large-world rebasing must update planet nodes and navigation coordinates consistently.
