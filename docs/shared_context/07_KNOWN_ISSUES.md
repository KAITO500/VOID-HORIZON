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
| KI-020 | HUD layout (anchors/min sizes) and the reticle are unverified; `SpaceDust` shader (POSITION override, never culled) never compiled. | Medium | Open |
| KI-021 | No collision response beyond `move_and_slide()`: no damage, bounce or stop. Nothing solid exists in the test scene. | Low | Open |
| KI-022 | Gamepad not supported; mouse/keyboard only. Flight assist is a simple lateral damper, not a full flight-assist model. | Low | Open |
