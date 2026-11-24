# Phase 03 — VH-01 WRAITH Flight HUD

## Design intent

The HUD follows **ABYSSAL RETROFUTURISM** with open instrument groups, a clear typographic hierarchy, fine curved perimeter rails and an unobstructed center. It uses aged ivory, graphite, copper, amber, muted turquoise, steel and stone. No opaque cards cover the flight view.

The visual target was made first as an editable SVG composition at [wraith_flight_hud_concept.svg](art/wraith_flight_hud_concept.svg), then re-created with native Godot controls and custom drawing. The concept includes a representative spacecraft silhouette; in game, the existing rendered ship and environment provide that imagery, while the HUD only draws instrumentation. Example values in the concept are illustrative; the game HUD uses live flight state or explicitly says when a feed is unavailable.

## In-game composition

- Upper left: ship identification `VH-01 / WRAITH` and flight system status.
- Upper center: current compass heading, a tick ribbon, pitch and roll.
- Left edge: large readable speed, units and relative velocity bar.
- Right edge: throttle, boost reserve/state and flight-assist status.
- Lower right: target lock placeholder, explicitly marked unavailable until a targeting feed exists.
- Lower left: alert feed marked no data until a warning system exists.
- Center: small geometric nose reticle projected from the ship's forward direction.

Reference layout is authored around 1920×1080. The entire overlay scales uniformly to fit the viewport's smaller dimension, caps at 1.35×, and remains centered. It supports 1280×720, 1600×900, 1920×1080, and 2560×1440 while retaining a clear center region.

Peripheral linework follows a shallow inward curve. Readouts remain unboxed so the live game stays visible behind them. Camera-relative parallax is configurable with `parallax_strength` (default 4 px); the central reticle is excluded from parallax.

## Data sources

`FlightHud` reads the existing `Spaceship`, `FlightController`, `FlightBoost`, `FlightConfig`, `ShipNetworkState.thrust`, ship transform and `FlightCamera`. It displays actual speed, heading, pitch, roll, engine output, boost reserve/activity and assist state. It does not write to the controller or input intent.

The project has no target-lock or warning-feed system yet. The HUD says `NAV FEED / UNAVAILABLE` and `ALERT FEED / NO DATA` rather than inventing a production state. No multiplayer coupling was added.

## Visual state preview

Open `scenes/flight/flight_hud_preview.tscn` to see a visual-only state prototype over the flight scene. Its banner marks the values as mock data. Keys `1`–`5` switch normal flight, boost, target-selected, warning and critical-warning examples. `H` toggles the input help. This preview does not feed mock values into the gameplay flight controller.

## Godot files

- `scripts/flight/flight_hud.gd` — responsive UI, live readouts, reticle, compass, parallax and isolated visual states.
- `scripts/flight/flight_hud_preview.gd`, `scenes/flight/flight_hud_preview.tscn` — labeled mock presentation harness.
- `scenes/flight/flight_test.tscn` already instances `FlightHud`; no duplicate production HUD scene was added.
- `tests/unit/phase03_hud_check.gd` — layout, live data and preview checks.

## Validation and known limits

The prior HUD implementation passed the Phase 03 HUD, Phase 03 flight and Phase 02 ship headless checks on Godot 4.7.2. This redesigned HUD has not yet been run: the Godot executable is not currently available in the attached workspace, and there is no open Godot window to inspect. Run `tests/unit/phase03_hud_check.gd`, `tests/unit/phase03_flight_check.gd` and `tests/unit/phase02_ship_check.gd` before merging.



