# Phase 03 — Temporary WRAITH flight HUD

**Status:** Basic placeholder
**Updated:** 2026-11-25

The former panoramic 3D HUD, Cosmic Violet visual system, presentation scenes and web mockup have been removed so the interface can be redesigned later. The game now uses a small, flat 2D overlay built in `scripts/flight/flight_hud.gd`.

The placeholder shows only the VH-01 label, speed, heading/pitch, thrust, boost, current navigation destination/distance/bearing, and selected planet approach state/altitude. It reads `NavigationTelemetry`, navigation targets/waypoints and `PlanetaryApproachSnapshot`; it does not modify flight or navigation state. The fixed reticle remains centered.

`scenes/flight/flight_test.tscn` still loads this HUD for F5. Phase 03 and Phase 04 checks cover the minimal layout and live values. This is a functional placeholder, not an approved final interface design.
