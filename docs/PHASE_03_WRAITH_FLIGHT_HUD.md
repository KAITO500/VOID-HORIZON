# Phase 03 — VH-01 WRAITH Flight HUD

## Design intent

The HUD translates the supplied design brief into an editable, native Godot `Control` composition. It follows **ABYSSAL RETROFUTURISM**, a hybrid industrial and elegant instrument style with low information density. The layout keeps the center open and uses aged ivory, graphite, copper, amber, muted turquoise, steel and stone. It uses Godot's built-in font fallback so no external font asset is required.

The companion editable Figma design is [VOID HORIZON — WRAITH Flight HUD](https://www.figma.com/design/57sH4Zv7fkGF1cF8Te9CRs). It contains foundations/tokens, reusable component states and the 1920×1080 HUD with prototype navigation. The account's Starter plan limits the file to three pages, so the six requested content areas are grouped into those three pages.

## In-game composition

- Upper left: ship identification `VH-01 / WRAITH` and flight system status.
- Upper center: current compass heading, a tick ribbon, pitch and roll.
- Left edge: large readable speed, units and relative velocity bar.
- Right edge: throttle, boost reserve/state and flight-assist status.
- Lower right: target lock placeholder, explicitly marked unavailable until a targeting feed exists.
- Lower left: alert feed marked no data until a warning system exists.
- Center: small geometric nose reticle projected from the ship's forward direction.

Reference layout is authored around 1920×1080. The entire overlay scales with viewport height, clamped from 0.78× to 1.35×, and remains centered. The same rule supports 1600×900, 1920×1080, and 2560×1440 while retaining a clear center region.

Peripheral linework and slight panel rotations suggest a shallow inward curve without distorting text. Panels use a subdued graphite fill, fine copper edge and shallow shadow. Camera-relative parallax is configurable with `parallax_strength` (default 4 px); the central reticle is excluded from parallax.

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

Validated with Godot 4.7.2 headless on 2026-11-24: HUD data/layout check, existing Phase 03 flight check and Phase 02 ship regression check pass; the main flight scene and preview scene start without HUD script errors. Viewport scale was checked at 1280×720, 1920×1080 and 2560×1440 in the HUD test.

Interactive visual review in a rendered window has not been performed. The test environment reports inability to write `user://logs/godot.log`; this is an environment logging warning, not a reported HUD script error.
