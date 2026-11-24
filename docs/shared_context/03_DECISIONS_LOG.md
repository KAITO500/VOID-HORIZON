# 03 DECISIONS LOG

Mirrors the Notion "Technical Decisions" database (as read on 2026-11-23).

| ID | Decision | Status | By |
|----|----------|--------|----|
| D-001 | Godot 4.x, typed GDScript, PC first | Decided | Kaito |
| D-002 | Blender excluded from the toolchain (asset strategy: Q-008) | Decided | Kaito |
| D-003 | VOID HORIZON is a new project | Decided | Kaito |
| D-004 | Source of truth: Drive > GitHub > Notion | Decided | Kaito |
| D-005 | Branching: main, develop, feature/* | Decided | Kaito |
| D-006 | Godot folder structure (scenes, scripts, assets, resources, systems, tests) | Proposed | Claude |
| D-007 | Naming, signal, input and dependency conventions | Proposed | Claude |
| D-008 | No autoloads in Phase 00 | Proposed | Claude |
| D-009 | Input translated into an intent object consumed by ships | Proposed | Claude |
| D-010 | Phase 00 ships only a minimal bootable main scene | Proposed | Claude |
| D-011 | Earlier scaffold delivered as zip because GitHub connector was unavailable | Decided | Claude |

## New in this rebuild
| ID | Decision | Status |
|----|----------|--------|
| D-012 | Phase 00 was rebuilt directly in the GitHub repo at the user's request, because the earlier zip and Drive docs were not available to this account. Documents are stored in `docs/shared_context/` in addition to Drive. | Decided (user) |
| D-013 | `project.godot` targets Godot 4.7.2 / Forward+ (version confirmed by the user; was assumed 4.3 before). | Decided (user) |
| D-014 | Add `scripts/environment/` and `assets/materials/space/` (adapts D-006; documented reason: environment code and shaders had no home) | Proposed |
| D-015 | Sky layers are procedural (MultiMesh stars, noise-shader nebulae, sky shader); no texture assets | Proposed |
| D-016 | One DirectionalLight3D (`StarLightingController`) for the primary star; no per-star lights | Proposed |
| D-017 | Distant bodies are placed by apparent size (radius = distance * tan(angular/2)) and follow the camera | Proposed |
| D-018 | Phase 01 work done on `feature/phase01-space-environment`; user prompt for Phase 01 treated as approval to start although Phase 00 was never validated in Godot | Decided (see 06) |
| D-024 | `run/main_scene` now points to `scenes/ships/ship_inspection.tscn` so F5 shows the ship in the environment (the Phase 00 `main.tscn` is an empty scene and shows only a grey screen). Revisit when a real game entry point exists. | Decided (user problem report) |
| D-019 | Ship root is a CharacterBody3D with floating motion mode, provisionally; only the root type changes if Phase 03 picks RigidBody3D | Proposed |
| D-020 | Add `scripts/ships/` for ship code (adapts D-006) | Proposed |
| D-021 | Keep ship visuals replaceable in `ShipModel`. Current Light Fighter visual is a custom Blender-authored GLB; the procedural GDScript model remains as fallback. The exported GLB adds no Blender runtime/build dependency and D-002 still applies to the toolchain. Godot import/appearance remains unvalidated. | Proposed |
| D-022 | Ship coordinate convention: 1 unit = 1 m, forward -Z, up +Y, right +X, engines +Z, Marker3D -Z = emission direction | Proposed |
| D-023 | Phase 02 started on the user's Phase 02 prompt although Phase 01 and Phase 00 were never run in Godot; branch `feature/phase02-light-fighter` is based on `feature/phase01-space-environment` | Decided (see 06) |
| D-025 | Fix the imported GLB orientation on the ship scene (`ShipModel` rotation (x,y,z)->(-x,z,y)); the GLB is authored length-on-Y, height-on-Z. Computed from glTF data, not seen in Godot. `Spaceship.validate()` warns if wrong. | Proposed (unverified) |
| D-026 | Flight uses the existing CharacterBody3D root (floating mode) with velocity set by `FlightMath`; arcade model with assist (lateral damping), no RigidBody3D. Resolves D-019 for Phase 03; revisit if physical collisions/knockback are needed. | Proposed |
| D-027 | Flight InputMap actions are registered at runtime (`FlightInputMap`) instead of hand-written in project.godot; Project Settings entries override. | Proposed |
| D-028 | Physics interpolation enabled (`physics/common/physics_interpolation`); camera and dust use `get_global_transform_interpolated()` in `_process`. | Proposed |
| D-029 | `run/main_scene` is now `scenes/flight/flight_test.tscn` (supersedes D-024). Phase 03 started on the user's Phase 03 prompt although Phases 00-02 are not formally validated. | Decided (user prompt) |
