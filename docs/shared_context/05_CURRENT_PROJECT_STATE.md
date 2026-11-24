# 05 CURRENT PROJECT STATE

Last updated: 2026-11-24

**Phase:** 03 - Flight System, merged into `main` via PR #5. The author never ran it in Godot (see `docs/PHASE_03_FLIGHT_SYSTEM.md`). On 2026-11-24 the user reported "todo funciona bien" without saying which scene or checks were run, so item-by-item validation is still open. Previous: 02 - Light Fighter: the GLB root orientation was corrected on main by PR #4 (GLB re-export) and verified with Godot 4.7.2 headless import, ship checks and main-scene startup by another agent; interactive visual review of appearance and collision fit is still pending.
**User test 2026-11-23 21:23:** the user opened the earlier Phase 02 build in Godot 4.7.2, pressed F5 and reported "funciona perfecto". That report predates the GLB model and is not a visual review of the current asset.
Phase 00 has not been validated. The user's earlier F5 test showed the Phase 02 inspection scene with its Phase 01 environment; it was a general smoke test, not a formal phase checklist. Each new phase was started on the user's phase prompt (D-018, D-023).
**Godot version:** 4.7.2 (confirmed by the user). Hardware target (Q-002) unknown.

**HUD update 2026-11-24:** the Phase 03 flight HUD has been restyled to the supplied ABYSSAL RETROFUTURISM brief and integrated with the live `FlightController`. Speed, heading, attitude, throttle, boost and assist are live; target and alert feeds explicitly show unavailable/no data. See `docs/PHASE_03_WRAITH_FLIGHT_HUD.md`. Headless HUD, Phase 03 and Phase 02 checks pass; interactive visual review remains open.

## Branches (GitHub KAITO500/VOID-HORIZON)
| Branch | State |
|--------|-------|
| main | Phase 00 + Phase 01: the user merged PR #1 (phase 01) at 13:44, merge commit 0ea9c3a. Whether the user ran it in Godot before merging is unknown. |
| develop | Phase 00 scaffold only (0de06b8); not updated by the PR |
| feature/phase01-space-environment | Phase 01, pushed (16660f5), already merged into main |
| feature/phase03-flight-system | Phase 03; merged into main via PR #5 (main HEAD e1586b1 at the time of the 2026-11-24 review). |
| fix/review-phase03-findings | Review fixes: phase03 test, Blender import setting, HUD reticle interpolation, docs 05/06/07. |
| feature/phase03-wraith-flight-hud | Panoramic HUD visual pass and preview harness; headless checks pass, interactive review pending. |
| feature/phase02-light-fighter, fix/phase02-light-fighter-orientation | Phase 02, merged into main (PR #3, PR #4). |

## Status per item
| Item | State |
|------|-------|
| Phase 00 scaffold | Implemented, not tested in Godot |
| Phase 01 environment (stars, nebulae, gas giant, lighting, test scene) | Implemented, never compiled or run |
| Light Fighter scene, imported custom GLB, procedural fallback, collision boxes, markers, config, state classes | Earlier build reported working; new GLB wiring not yet run in Godot |
| Ship inspection scene and headless checks | Inspection scene was run by the user before GLB replacement; headless checks remain unrun |
| Blender/glTF ship model | Custom GLB and editable source integrated; new import appearance/orientation and collision fit unvalidated |
| Flight controller, input, boost, chase camera, HUD, speed dust, flight test scene | Implemented, not run in Godot; math simulated in Python |
| WRAITH panoramic HUD visual pass | Implemented in main flight scene; headless data and scaling checks pass; interactive review pending |
| Weapons, networking | Not implemented (later phases) |
| Statically checked | Indentation, brackets, `res://` paths, Python simulation of hull triangle winding and sizes |

## Remaining work
1. Open the updated `scenes/ships/ship_inspection.tscn` in Godot 4.7.2 and check the imported GLB orientation, materials, silhouette and collision fit; the earlier F5 report predates this model replacement.
2. Fix first-run errors (likely in shaders and procedural mesh code) on the feature branches.
3. Approve phases in order, merge branches into `develop`.
4. Reconcile Drive docs with repo docs (KI-002).
5. Run `scenes/flight/flight_test.tscn` (F5): check ship orientation, then flight feel, camera, HUD, dust; report errors.
6. Phase 04 only after Phase 03 is validated and approved.

