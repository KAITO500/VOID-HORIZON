# Phase 03 — VH-01 WRAITH Flight HUD

## Design intent

The flight display is a concave, wraparound instrument surface for the **ABYSSAL RETROFUTURISM** art direction: aged ivory, graphite, weathered steel, oxidized copper, restrained amber and muted turquoise. The central flight instruments face the pilot; side instruments turn away across the cockpit arc. Their labels stay flat on each panel rather than bending with a decorative curve.

The two review boards are [front view](art/wraith_flight_hud_front_view.svg) and [three-quarter perspective](art/wraith_flight_hud_three_quarter_view.svg). The front view documents the full 1920×1080 layout. The three-quarter view makes the separate panel planes, rotation and depth layering easy to inspect. These are design presentations; the runnable scenes below render the actual HUD implementation.

## Spatial composition and rendering

`FlightHud` keeps its interface controls in a transparent 1920×1080 `SubViewport`. It crops each instrument group as a separate texture and maps those textures to independent `MeshInstance3D` planes inside a second 3D viewport. A curved, subtle glass backing completes the panoramic display. The whole 3D result is composited over the flight scene through a `TextureRect`.

Each panel sits tangent to a horizontal concave arc and has a world-space position and orientation of its own. The central heading, speed and reticle sit closest to the pilot, near the frontal direction. Propulsion and navigation-target groups occupy a recessed middle layer, while ship identity, sector context and the system feed sit farther around the sides. Their greater side angle makes them visibly narrower in projection. The reticle remains centered and stable on its own frontal plane.

- Upper center: compass heading, heading ticks, pitch and roll.
- Center: steady flight reticle.
- Lower center: speed and relative velocity bar.
- Lower left: propulsion, throttle, boost reserve and flight assist.
- Upper right: target-lock status.
- Outer regions: ship identity, sector context and system feed.

The source artwork keeps text and numerals planar and readable within each panel. Perspective comes from panel placement, rotation, physical dimensions and depth, not text deformation or drawn curved borders.

## Data sources

`FlightHud` reads the existing `Spaceship`, `FlightController`, `FlightBoost`, `FlightConfig`, `ShipNetworkState.thrust` and ship transform. It displays live speed, heading, pitch, roll, engine output, boost reserve/activity and flight-assist state. It does not write to flight input or controller state.

The project does not yet provide target-lock or warning-feed data. The gameplay HUD identifies these as unavailable or empty. Only the visual preview scenes use mock target and alert states, with a visible preview banner.

## Review scenes

- `scenes/flight/flight_hud_front_view.tscn` opens the flight HUD from the pilot-facing camera.
- `scenes/flight/flight_hud_three_quarter_view.tscn` moves the HUD presentation camera off-axis to expose the concave surface and panel orientations.
- `scenes/flight/flight_hud_preview.tscn` remains the interactive mock-state preview. Keys `1`–`5` switch example states and `H` toggles help.

The normal `scenes/flight/flight_test.tscn` continues to instance the production HUD; no mock state is injected into gameplay.

## Godot files

- `scripts/flight/flight_hud.gd` — 2D source artwork, live readouts and the spatial display construction.
- `scripts/flight/flight_hud_preview.gd` — labelled visual-review harness and camera selection.
- `tests/unit/phase03_hud_check.gd` — checks independent spatial surfaces, depth radii, viewport sizing, live values and preview controls.
- `docs/art/wraith_flight_hud_front_view.svg` and `docs/art/wraith_flight_hud_three_quarter_view.svg` — editable concept and presentation views.

## Validation and known limits

The earlier flat HUD passed the Phase 03 HUD, Phase 03 flight and Phase 02 ship checks on Godot 4.7.2. This spatial redesign has not yet been executed in Godot: the executable is unavailable in the attached workspace, and no Godot window is open. Run `tests/unit/phase03_hud_check.gd`, `tests/unit/phase03_flight_check.gd` and `tests/unit/phase02_ship_check.gd` in Godot 4.7.2, then inspect both review scenes in the renderer before merging. The three-quarter SVG is a design presentation of the intended geometry, while the Godot scene is the runtime version to validate.

