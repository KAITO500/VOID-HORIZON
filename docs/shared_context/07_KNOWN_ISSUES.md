# 07 KNOWN ISSUES

| ID | Issue | Severity | Status |
|----|-------|----------|--------|
| KI-001 | Project never opened or run in Godot; `project.godot` hand-written for 4.7.2 (confirmed). May trigger an upgrade prompt. | Medium | Open |
| KI-002 | Repo docs were rebuilt without access to the Drive originals and the earlier scaffold zip; possible divergence. | High | Open |
| KI-003 | Question IDs other than Q-001, Q-002, Q-008 are unknown to this author; new ones may collide. | Low | Open |
| KI-004 | Branch protection on `main` not configured. | Low | Open (user) |
| KI-005 | Notion tasks and overview still describe the repo as not created / scaffold as zip. | Low | Open |
| KI-006 | Phase 01 never compiled or run in Godot; GDScript/shader errors are likely until the first run. | High | Open |
| KI-007 | `star_field.gdshader` billboard `MODELVIEW_MATRIX` code and per-instance `COLOR` use are from memory, not verified in a run. If stars are invisible or black, check this first. | Medium | Open |
| KI-008 | Nebula shader runs 32 noise lookups per pixel per layer; may be costly on weak GPUs/4K. Not measured. | Medium | Open |
| KI-009 | Backdrop follows the camera, so the planet cannot be approached or occluded by anything but near objects. Intended for Phase 01 only. | Low | By design |
| KI-010 | Colors, intensities and the 20-unit ship scale assumption are untuned guesses. Headless math check needs the project imported first (global class cache). | Low | Open |
| KI-011 | User reported the earlier Phase 02 build works in Godot 4.7.2, but the new GLB replacement has not been imported or run; its scene/model behavior may contain errors. | High | Validation open |
| KI-012 | Procedural hull winding/normals verified only by Python simulation; if parts render inside-out or missing, check `_add_tri()` in `ship_hull_builder.gd`. | Medium | Open |
| KI-013 | Custom GLB replaces the procedural visual, but its Godot import, appearance and fit against the collision boxes have not been checked. | Medium | Validation open |
| KI-014 | Collision is four boxes (over-approximates nose and wing tips); body type CharacterBody3D is provisional. | Low | Open |
| KI-015 | `@tool` scripts (`ShipHullBuilder`, `LightFighterModel`) run in the editor; an error there appears in the editor Output when opening the ship scene. | Low | Open |
| KI-016 | Phase 03 was never run in Godot. Scripts, scenes, shader and HUD may contain errors. Only the flight math was checked (Python re-implementation). | High | Open |
| KI-017 | GLB orientation was fixed by PR #4 (headless-verified, not seen interactively). Model root is named "VH-02 Vesper" while the prompt says VH-01 WRAITH; naming needs a decision. | High | Open |
| KI-018 | Collision boxes and weapon points were sized for the old procedural model; they do not match the GLB (wings span 15.2 m, 3 engines). | Medium | Open |
| KI-019 | All flight numbers (speeds, rates, boost, camera) are untuned first guesses; mouse feel and camera lag need human flying. | Medium | Open |
| KI-020 | HUD layout (anchors/min sizes) and reticle are unverified; the new speed-streak shader has not had rendered visual or GPU performance review. | Medium | Open |
| KI-021 | No collision response beyond `move_and_slide()`: no damage, bounce or stop. Nothing solid exists in the test scene. | Low | Open |
| KI-022 | Gamepad not supported; mouse/keyboard only. Flight assist is a simple lateral damper, not a full flight-assist model. | Low | Open |
| KI-023 | `ShipConfig.visual_scene` is declared (comment says "empty = built-in placeholder") but nothing reads it. `LightFighterModel` and `ShipHullBuilder` are unused by any scene (only the phase02 test uses `ShipHullBuilder`). Decide: wire it up or remove. | Low | Open |
| KI-024 | No `.uid` files committed (Godot 4.4+ creates them next to scripts/resources). Scenes reference by path so nothing breaks; committing them keeps UIDs stable across clones. | Low | Open |
| KI-025 | 2026-11-24 static review (no Godot available): phase03 test engine-point check, `.blend` import setting and HUD reticle interpolation fixed on `fix/review-phase03-findings`; not run in Godot. | Low | Fixed in branch, unverified |
| KI-026 | Combat target-lock and alert-severity sources do not exist yet. Phase 04 now provides navigation POI selection, but this is not a combat lock system. | Low | By design until combat feeds are added |
| KI-027 | WRAITH HUD has passed headless data, viewport scaling and scene-start checks but has not received interactive visual review in a rendered window. | Medium | Open |
| KI-028 | Phase 04 coordinates use Godot `Vector3`/`Transform3D` precision and do not rebase the world. Suitable for current local navigation; precision strategy must be revisited before planetary/interstellar-scale coordinates. | Medium | Deferred by design |
| KI-029 | The visible navigation beacons in `flight_test.tscn` are test fixtures. Generated planets/stations are not yet registered as production POIs. | Low | Open until universe content is integrated |
| KI-030 | Phase 04 navigation and HUD checks pass headless, but rendered marker legibility, camera occlusion/turn behavior and hardware performance have not been reviewed. | Medium | Open |
| KI-031 | The extracted `D:\Angel\VOID-HORIZON-main` copy has no `.git` metadata and did not receive the Phase 04 branch; the environment granted read access but denied write access. | Medium | Open — synchronize when writable |
| KI-032 | Phase 05's planetary shell and sky tint compile and the integration checks pass headless, but their appearance through the rendered flight camera and actual ingress/egress have not been reviewed interactively. | Medium | Open — rendered review |
| KI-033 | The observed 0.013–0.016 ms/sample Phase 05 range measures only headless controller sampling in this sandbox; it is not a GPU or target-PC performance result. | Medium | Open — profile target hardware |
| KI-034 | Planet approach still uses single-precision world `Vector3` coordinates. This test scale succeeds, but close-surface fidelity combined with system/interstellar distances needs a rebasing or other precision strategy before those scopes. | Medium | Open — architecture decision for later scale |
| KI-035 | Shift now provides sustained high-speed overdrive and the Khepri fixture is reachable at 85 km, but there is no discrete hyperspace jump or interstellar travel mechanic yet; those remain Phase 08. | Medium | Deferred by roadmap |

