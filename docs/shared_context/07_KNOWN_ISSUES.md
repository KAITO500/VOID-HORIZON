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
