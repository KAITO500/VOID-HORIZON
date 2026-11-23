# 02 TECHNICAL ARCHITECTURE

Status: **Proposed.** Nothing here has been tested in Godot or validated by the user.
Decisions D-006 to D-010 in Notion are still "Proposed".

## 1. Entry point
`res://scenes/main/main.tscn` (root `Main`, Node3D) with `res://scripts/core/main.gd`.
Phase 00: prints a boot line only. Later phases load universe/ship scenes from Main.

## 2. Scene organization
One scene per concept, grouped by folder: `scenes/main`, `universe`, `ships`, `planets`, `environment`, `ui`.
Scenes compose by instancing; no scene reaches into the internals of another.

## 3. Script responsibilities
- `scripts/core`: bootstrapping, shared base types, utilities.
- `scripts/flight`: ship movement and input-to-motion.
- `scripts/multiplayer`: session and replication glue.
- `scripts/planets`, `combat`, `ai`: respective gameplay logic.
- `systems/*`: larger self-contained subsystems (world generation, navigation, networking, streaming).
One script, one responsibility. Scripts live next to their domain, not next to their scene.

## 4. Resource organization
Data as custom `Resource` files under `resources/` (ships, planets, weapons, settings). Tunables live in resources, not in code constants.

## 5. Naming conventions (D-007)
- Files and folders: `snake_case`. Classes: `PascalCase` via `class_name`.
- Variables/functions: `snake_case`. Constants: `UPPER_SNAKE`. Private members: leading `_`.
- Signals: past-tense `snake_case` (`shield_depleted`). Static typing everywhere.

## 6. Signal conventions
Signals go up, calls go down. Children emit; parents connect. No signals across unrelated subtrees without a documented mediator.

## 7. Dependency management
No autoloads in Phase 00 (D-008). Add one only with a documented need. Dependencies are passed in explicitly (exported node/resource references).

## 8. Input management (D-009)
Player, AI and network input are translated into an **intent object** (throttle, pitch/yaw/roll, boost, fire). Ships consume intents only. Godot InputMap actions are defined when Phase 03 starts.

## 9. Rendering strategy
Forward+ renderer, PC first. Stylized look; details deferred to Phase 01. Hardware target unknown (Q-002).

## 10. Physics strategy
Arcade flight: custom velocity/rotation control rather than full rigid-body realism. Whether to use `CharacterBody3D` or `RigidBody3D` is decided in Phase 03.

## 11. Multiplayer considerations
Godot high-level multiplayer is the starting candidate. Server-authoritative simulation for ships is assumed but undecided. Because input is an intent object, it can be sent over the network unchanged. Decided in Phase 08; Phase 00 only keeps the door open.

## 12. Large-world precision
Single-precision floats lose accuracy far from the origin. Options: floating origin / world rebasing, or Godot double-precision build. Decision deferred to Phase 01/04; do not hard-code absolute large coordinates meanwhile.

## 13. Terrain streaming (future)
Needs chunked, level-of-detail terrain loaded on a background thread with seamless space-to-surface transition. Placeholder folder: `systems/streaming`. Not implemented.

## 13b. Phase 01 environment architecture (Implemented, not tested in Godot)
Full reference: `docs/PHASE_01_SPACE_ENVIRONMENT.md`.
- `scenes/environment/space_environment.tscn`: SpaceEnvironment root with StarLight, StarField, NebulaLayer x2, CelestialBackdrop > CelestialBody (gas giant).
- Independent modules: `SkyAnchor` (base, follows camera), `StarField`, `NebulaLayer`, `CelestialBackdrop`, `CelestialBody`, `StarLightingController`, `SpaceEnvironment`, `SkyMath`.
- Visuals are procedural shaders in `assets/materials/space/` (no textures, no Blender).
- Folder adaptation: `scripts/environment/` added (D-014). Dev-only `scripts/core/debug_free_camera.gd`.
- Camera far plane must be >= `SpaceEnvironment.get_required_far_plane()` (~385000 with defaults).

## 14. Unresolved questions
| ID | Question |
|----|----------|
| Q-001 | Exact Godot 4.x version in use (project.godot assumes 4.3). |
| Q-002 | Hardware target and minimum specs. |
| Q-008 | Asset strategy without Blender (D-002), decided in Phase 02. |
| New | Float precision approach (floating origin vs double build). |
| New | Physics body type for ships. |
| New | Multiplayer topology and authority model. |
| New | Player count per session. |
| New | Gameplay camera near/far planes and ship scale (Phase 02). Phase 01 assumes ship ~20 units. |

Note: the earlier Phase 00 account listed Q-001 to Q-009 in an unreadable Drive document. Only Q-001, Q-002 and Q-008 are known to this author; the rest are marked "New" and may duplicate unseen IDs. Renumber after reconciling with Drive.
