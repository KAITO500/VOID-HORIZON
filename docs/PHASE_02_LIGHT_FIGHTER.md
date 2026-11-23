# Phase 02: Light Fighter (reference)

Status: **Implemented, NOT executed or tested in Godot.** No Godot binary, Blender or modeling tool was available
to the author. Phase 01 (the environment it is shown in) is also untested. Treat all geometry as a first guess.

## Asset strategy (what was and was not created)

- Tools available: none for 3D modeling (no Blender, and Blender is excluded by decision D-002; no Godot binary).
- **No Blender file, no .glb, no .obj exists.** The ship is generated at runtime by GDScript (`ShipHullBuilder`):
  flat-shaded lofted and extruded convex parts. It looks like a fighter (swept wings, canards, canted fins, wing-mounted
  engine nacelles, canopy), not like cubes, but it is a procedural placeholder.
- Replacement strategy for the final model (user or artist, any tool that exports glTF):
  1. Model in ship space (convention below) and export `light_fighter_model.glb`, one mesh per material slot.
  2. Import into `assets/models/ships/` (Godot imports it as a scene; default import settings are fine; do not bake scale).
  3. In `scenes/ships/light_fighter.tscn`, replace the node `VisualRoot/ShipModel` with the imported scene (keep the name
     `ShipModel`) or assign `visual_scene` in `resources/ships/light_fighter.tres`.
  4. Do NOT touch `EnginePoints`, `WeaponPoints`, `CameraTarget` or the collision shapes unless the new model's proportions
     require it; they live on the ship root on purpose.

## Coordinate convention (ALL future ships)

| Item | Value |
|------|-------|
| Units | 1 unit = 1 meter |
| Origin | Ship center (approximate center of the hull volume) |
| Forward | -Z (nose points to -Z, Godot's default forward) |
| Up | +Y |
| Right | +X (right wing at +X) |
| Rear | +Z (engines at +Z) |
| Attachment markers | A Marker3D's -Z axis is its emission/firing direction. Engine markers are rotated 180 deg about Y, so their -Z points to the ship's rear (+Z). Weapon markers keep -Z = forward. |
| Light Fighter size | Length about 19 m (nose z=-10, nozzles z=+8.8), wingspan about 15.2 m, height about 3.5 m (to fin tips) |

## Scene hierarchy: `res://scenes/ships/light_fighter.tscn`

```
LightFighter              CharacterBody3D   spaceship.gd (Spaceship), config = light_fighter.tres
|- VisualRoot             Node3D            presentation only
|  |- ShipModel           Node3D            light_fighter_model.gd (@tool): builds 7 MeshInstance3D parts
|  `- EngineVisuals       Node3D            ship_engine_visuals.gd: nozzle glow + flame cone per engine marker
|- CollisionFuselage      CollisionShape3D  BoxShape3D 3.2 x 1.9 x 17.0
|- CollisionWings         CollisionShape3D  BoxShape3D 15.2 x 0.7 x 7.7
|- CollisionNacelleLeft   CollisionShape3D  BoxShape3D 1.4 x 1.4 x 8.0
|- CollisionNacelleRight  CollisionShape3D  BoxShape3D 1.4 x 1.4 x 8.0
|- CameraTarget           Marker3D          (0, 1.2, 1.0)
|- EnginePoints
|  |- EngineLeft          Marker3D          (-2.9, -0.3, 8.8), faces +Z (exhaust)
|  `- EngineRight         Marker3D          ( 2.9, -0.3, 8.8)
|- WeaponPoints
|  |- WeaponLeft          Marker3D          (-4.6, -0.6, 0.6), faces -Z
|  `- WeaponRight         Marker3D          ( 4.6, -0.6, 0.6)
`- MultiplayerSyncRoot    Node              ship_network_state.gd (ShipNetworkState)
```

Deviations from the suggested hierarchy (documented reasons):
- No `CollisionRoot` node: CollisionShape3D must be a direct child of a CollisionObject3D (the root body).
- The model parts are visuals only; `ShipModel` is a single replaceable node.
- Materials per part (all `StandardMaterial3D`, set in `light_fighter_model.gd`):
  Fuselage and Fins = dark navy metal; Wings and Canards = graphite metal; Nacelles = dark engine housing;
  Canopy = dark glass with faint cyan emission; Accents = orange (controlled accent, emissive); engine glow = cyan.

## Scripts and resources

| Path | Role |
|------|------|
| `scripts/ships/spaceship.gd` | Generic ship entity (root). Config, attachment lookups, `validate()`. No flight logic. |
| `scripts/ships/ship_config.gd` + `resources/ships/light_fighter.tres` | ShipConfig resource. All `_ref` values are PLACEHOLDERS (`is_placeholder_balance = true`). |
| `scripts/ships/ship_hull_builder.gd` | Procedural geometry (@tool, static functions). |
| `scripts/ships/light_fighter_model.gd` | Assembles the parts and materials (@tool). |
| `scripts/ships/ship_engine_visuals.gd` | Engine glow; `set_thrust(0..1)`. Presentation only. |
| `scripts/ships/ship_intent.gd` | ShipIntent data object (D-009). Defined, not consumed yet. |
| `scripts/ships/ship_network_state.gd` | Ownership and replicated-state placeholder. No networking. |
| `scripts/ships/ship_inspection*.gd`, `scenes/ships/ship_inspection.tscn` | Inspection scene (dev tool). |
| `tests/unit/phase02_ship_check.gd` | Headless check (mesh sizes, scene validates, counts). |

ShipConfig fields: `ship_id`, `display_name`, `ship_class`, `visual_scene`, `mass_ref`, `max_speed_ref`, `acceleration_ref`,
`rotation_responsiveness_ref`, `engine_point_names`, `weapon_point_names`, plus camera references
(`camera_distance_ref` 28, `camera_height_ref` 6, `camera_base_fov_ref` 70; placeholders).

## Third-person camera preparation

- `CameraTarget` (Marker3D at 0, 1.2, 1.0) is the stable follow point; `Spaceship.get_camera_target_transform()` returns it.
- The camera itself is NOT built. Requirements for Phase 03: smooth follow (damped, not rigidly parented), keep the ship visible,
  handle high speed, avoid motion sickness (limit camera rotation lag/shake), and dynamic FOV around `camera_base_fov_ref`.
- The inspection camera is a separate dev orbit camera and must not be reused as gameplay code.
- Camera planes: environment needs far >= ~385000; inspection scene uses near 0.3. Gameplay values: decide in Phase 03.

## Multiplayer preparation (researched in Godot docs via Context7)

Facts used: server peer id is 1; `multiplayer.get_unique_id()` works offline and returns 1; `Node.set_multiplayer_authority(id)` assigns
authority; `MultiplayerSynchronizer` replicates the properties listed in its `replication_config`.

Separation of responsibilities:
| Concern | Where it lives | Replicated later? |
|---------|----------------|-------------------|
| Transform state | Ship root transform and `velocity` | Yes (via `capture_state()` or a synchronizer) |
| Gameplay state | `ShipNetworkState` variables (thrust now; health, shields later) | Yes |
| Visual state | `ShipEngineVisuals` (derived from thrust) | No, recomputed locally |
| Ownership | `ShipNetworkState.owner_peer_id`; `assign_owner()` sets authority | Set by the server on spawn |
| Pilot input | `ShipIntent` object | Owner sends intents; server applies |

Single-player is simply "owner peer 1". Nothing in the ship assumes a single player. Authority model and topology are still undecided (Q-new).

## Integration with the environment and testing

`res://scenes/ships/ship_inspection.tscn` instances the Phase 01 `SpaceEnvironment`, the `LightFighter` at the origin (static, no flight)
and an orbit camera. The "hero" view puts the ship in front of the gas giant.

Steps (Godot 4.7.2):
1. Open the project, let it import. Check the Output panel for script or shader errors first.
2. Open `scenes/ships/ship_inspection.tscn` and press **F6**.
3. Keys: **1** front, **2** right side, **3** rear, **4** top, **5** hero (against the planet), **C** collision shapes (green),
   **M** attachment points (cyan = engines, red = weapons, green = camera target; arrows show -Z), **E** engine thrust
   (idle, full, off), **H** hide HUD. Right mouse drag orbits, wheel zooms.
4. Check:
   - Front/side/rear silhouettes are clearly different and read as a fighter; nose forward (toward -Z, away from the engines).
   - Engines glow cyan at the rear, flames point backward and shrink/grow with E.
   - Collision boxes enclose the ship without huge gaps; markers sit on the engines, under the wing leading edges and above the cockpit.
   - HUD says "ship validation: OK".
   - Ship is lit by the sun; it stands out against the planet and the dark sky.
5. Also open `scenes/ships/light_fighter.tscn` alone: the model should appear in the editor viewport (the model script is @tool).
6. Optional: `godot --headless --path . --import`, then `godot --headless --path . -s res://tests/unit/phase02_ship_check.gd` (exit 0 = pass).

## Known limits

- Never run in Godot. Winding order/normals of the procedural parts were checked only by a Python simulation of the same math
  (84 fuselage triangles, 0 inconsistent). If a part looks inside-out or invisible, the winding in `_add_tri()` is the first suspect.
- Collision uses simple boxes (nose and wing tips are over-approximated). Convex shapes can replace them later.
- Provisional root type CharacterBody3D (D-019); physics body type is still open.
- Proportions, colors and glow strength are untuned.
