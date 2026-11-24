# 06 HANDOFF REPORT

PROJECT: VOID HORIZON

PHASE:
02 - First Spacecraft: Light Fighter

TASK:
Create the reusable Light Fighter scene with placeholder model, collision, camera target, attachment points, config, multiplayer-ready structure and an inspection scene in the Phase 01 environment.

STATUS:
Partially completed. A custom Blender-authored GLB is integrated as `VisualRoot/ShipModel`. Its root rotation was corrected so Godot sees the ship nose along -Z, up +Y, and engines toward +Z. Godot 4.7.2 headless import and ship checks pass; interactive visual review remains pending. The correction is on PR #4 (`fix/phase02-light-fighter-orientation`).

SUMMARY:
See `docs/PHASE_02_LIGHT_FIGHTER.md` (hierarchy, coordinate convention, replacement strategy, testing steps, multiplayer separation).
The ship scene instances `assets/models/ships/light_fighter_model.glb`; `ShipHullBuilder` and `light_fighter_model.gd` remain as procedural fallback/reference. Godot reports model bounds of about 15.2 m span, 3.5 m height and 19 m length, with the nose ahead of the engines along Z. Materials, silhouette, collision fit and Phase 01 visual behavior still need interactive review.

FILES CREATED:
- scenes/ships/light_fighter.tscn, scenes/ships/ship_inspection.tscn
- assets/models/ships/light_fighter_model.glb, assets/models/ships/light_fighter_source.blend
- resources/ships/light_fighter.tres
- scripts/ships/: spaceship.gd, ship_config.gd, ship_hull_builder.gd, light_fighter_model.gd, ship_engine_visuals.gd, ship_intent.gd, ship_network_state.gd, ship_inspection.gd, ship_inspection_camera.gd
- tests/unit/phase02_ship_check.gd
- docs/PHASE_02_LIGHT_FIGHTER.md

FILES MODIFIED:
README.md, docs/shared_context/02, 03, 04, 05, 06, 07. Removed placeholder `.gitkeep` in scenes/ships and resources/ships.

GIT STATE:
Phase 02 is merged into `main` by PR #3. The GLB orientation correction and regression check are on open PR #4 (`fix/phase02-light-fighter-orientation`); it has not been merged. `develop` remains at Phase 00.

TECHNICAL DECISIONS:
D-019 to D-023 (see 03_DECISIONS_LOG.md).

VALIDATION:
Performed on 2026-11-24 with Godot 4.7.2: headless editor import completed; `tests/unit/phase02_ship_check.gd` passed; the configured main inspection scene started headlessly with exit code 0. The geometry check now verifies bounds (15.2 x 3.5 x 19.0) and that the nose lies toward -Z relative to the engines.
NOT performed: interactive F5 visual review of materials, silhouette, or collision fit. The earlier user F5 report predates this GLB.

KNOWN ISSUES:
See 07_KNOWN_ISSUES.md (KI-011 to KI-015).

NEXT STEPS:
1. Open the inspection scene in Godot and visually review materials, silhouette and collision fit; orientation and headless startup are already checked.
2. Fix errors and tune proportions, colors and glow on the feature branch with minimal edits.
3. After approval of phases 00-02, merge branches into `develop` in order (00 is already there, then 01, then 02).
4. Phase 03 (Flight System): decide body type (CharacterBody3D vs RigidBody3D), implement `ShipIntent` consumption, gameplay camera on `CameraTarget`, drive `ShipNetworkState.thrust` and `set_visual_thrust()`. Do not start without approval.

INSTRUCTIONS FOR THE NEXT CLAUDE ACCOUNT:
Start from current `main`; review PR #4 before merging. Read `docs/PHASE_02_LIGHT_FIGHTER.md` first, then `docs/PHASE_01_SPACE_ENVIRONMENT.md`. The GLB axes and headless ship check are verified; interactive appearance and collision fit remain unreviewed.
Keep the ship coordinate convention (forward -Z, engines +Z, 1 unit = 1 m). Keep attachment points on the ship root, not inside the model. Do not put
flight, camera or networking logic into visuals. Placeholder `_ref` values in ShipConfig are not balance.

## Phase 02 validation checklist (user)
- [ ] Output panel shows no script/shader errors when opening the project and running `ship_inspection.tscn`.
- [ ] Front, side, rear and top silhouettes look like a distinct light fighter; nose points away from the engines.
- [ ] Engines glow cyan, flames point rearward, key E changes them.
- [ ] Collision boxes (key C) roughly fit; markers (key M) are in sensible places; HUD says validation OK.
- [ ] Ship is readable against the planet in the hero view (key 5).
- [ ] `light_fighter.tscn` opened alone shows the model in the editor.

## Earlier reports
Phase 01: environment on `feature/phase01-space-environment` (pushed, 16660f5), untested. Phase 00: scaffold on `main`/`develop` (0de06b8), untested.

