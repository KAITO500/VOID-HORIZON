# Phase 01: Space Environment (reference)

Status: **Implemented, NOT executed or tested in Godot.** Written without access to a Godot binary.
Treat every visual value (colors, intensities, sizes) as a first guess to tune in the editor.

## A. Scene hierarchy

`res://scenes/environment/space_environment.tscn`
```
SpaceEnvironment            (Node3D)  space_environment.gd   owns WorldEnvironment + wiring
|- WorldEnvironment         sky, ambient, tonemap, glow (Environment built in code)
|- StarLight                (DirectionalLight3D) star_lighting_controller.gd
|- StarField                (Node3D)  star_field.gd          MultiMesh child "Stars" built at runtime
|- NebulaFar                (Node3D)  nebula_layer.gd        sphere child "Nebula" built at runtime
|- NebulaNear               (Node3D)  nebula_layer.gd
`- CelestialBackdrop        (Node3D)  celestial_backdrop.gd
   `- GasGiant              (Node3D)  celestial_body.gd      old apparent-size placeholder (removed from shared scene in Phase 05)
```
`res://scenes/environment/space_environment_test.tscn` instances the above plus a `DebugFreeCamera`
and builds a HUD label in code.

Class relationships: `StarField`, `NebulaLayer`, `CelestialBackdrop` extend `SkyAnchor` (keeps the layer on the camera).
`SkyMath` holds shared static math. `CelestialBody` is independent of `SkyAnchor`.

## B/D. Files

| Path | Purpose |
|------|---------|
| `scripts/environment/sky_math.gd` | Direction/band math (yaw 0 = -Z, +yaw = +X) |
| `scripts/environment/sky_anchor.gd` | Base: follow camera, `follow_factor` |
| `scripts/environment/star_field.gd` | Seeded MultiMesh star sprites, 1 draw call |
| `scripts/environment/nebula_layer.gd` | Inside-out sphere + procedural nebula shader |
| `scripts/environment/celestial_body.gd` | Body placed by apparent size, gas giant + rings, other kinds as placeholders |
| `scripts/environment/celestial_backdrop.gd` | Container for bodies |
| `scripts/environment/star_lighting_controller.gd` | One key light + sun in sky shader |
| `scripts/environment/space_environment.gd` | Root: Environment/Sky/glow, wiring, far-plane check |
| `scripts/environment/space_environment_test.gd` | Test scene HUD and toggles |
| `scripts/core/debug_free_camera.gd` | Dev free camera (not gameplay) |
| `assets/materials/space/*.gdshader(inc)` | space_sky, star_field, nebula_layer, gas_giant, planet_ring, space_noise |
| `tests/unit/phase01_math_check.gd` | Headless math check |

## E. Inspector settings (defaults already set in scripts; change per node)

- **SpaceEnvironment**: Sky colors, `ambient_energy` 1.0, `tonemap_exposure` 1.0, `glow_enabled` true, `glow_intensity` 0.8.
- **StarLight**: `star_yaw_deg` 55, `star_pitch_deg` 18 (where the star is in the sky), `star_color` warm, `star_energy` 1.8, sun disc/halo sizes.
- **StarField**: `star_count` 4000, `seed_value` 1337, `radius` 300000, size 0.07 to 0.30 deg, `brightness_skew` 3, band settings, color ratios.
- **NebulaLayer** (x2): `radius` 350000 / 340000, `seed_offset`, `noise_scale`, `density_threshold` (higher = sparser), `intensity` 0.35 / 0.22, colors, `band_tilt_deg` (match StarField).
- **GasGiant (CelestialBody)**: see section 5 below; its original camera-following instance was replaced in the flight testbed by the reachable profile-driven Nexus gas giant in Phase 05. The celestial-body visual script remains available for other distant backdrops.
- After changing StarField/NebulaLayer exports at runtime call `rebuild()` / `apply_settings()`. In the editor, change values then run the scene (scripts are not `@tool`).

## F. Rendering configuration

- Renderer: Forward+ (project.godot), debanding on (avoids banding in dark gradients).
- Camera: `near` 1.0, `far` >= 385000 (`SpaceEnvironment.get_required_far_plane()`; the test camera uses 500000). A warning is pushed if the camera far plane is too small. Final gameplay camera values are decided in Phase 02.
- Environment: Sky background with `space_sky.gdshader`, ambient from sky, Filmic tonemap, glow threshold 1.0 (only the sun and brightest stars bloom).
- Layer order (transparent pass, by `render_priority`): nebula -20/-19, stars -10, rings 0. Planet is opaque. Stars and nebulae sit on shells (300000 to 350000) beyond the planet (80000), so depth testing hides them behind the planet.

## 5. Planet scale reference

`CelestialBody` is placed by apparent size, so scale is controlled by numbers, not by eyeballing:

- `radius = distance * tan(angular_diameter / 2)`
- Defaults: angular diameter 28 deg, distance 80000 -> radius ~19,946 units, diameter ~39,892 units.
- A 20-unit ship is therefore ~2000x smaller than the planet's diameter (assumption: ship length 20 units; ship size is not decided yet, Q-new).
- Direction: `yaw_deg` (-30) and `pitch_deg` (6). Rings span 1.35x to 2.3x the planet radius, tilted by `axial_tilt_deg` 35.
- To make it look bigger or smaller change `angular_diameter_deg`. Changing only `distance` moves it without changing apparent size (while the backdrop follows the camera).
- Because the backdrop follows the camera, the planet cannot be approached. Approachable planets are Phase 04/05.

## G. Testing instructions (user)

1. Open the project in Godot 4.7.2 (Phase 00 steps in README), let it import.
2. Open `res://scenes/environment/space_environment_test.tscn` and press **F6** (Run Current Scene).
3. Look around (right mouse + move, or arrow keys). Check:
   - Dark navy sky, many small stars, a denser band, a few brighter warm and cyan stars.
   - Subtle violet/blue/cyan nebulae, not washing out the stars.
   - A huge banded planet with rings on the left (yaw -30), lit from the right; a warm sun to the right behind you when you turn right (yaw 55).
   - Press **1/2/3/4** to toggle stars, nebulae, planet, glow and judge each layer.
   - Move with WASD: the backdrop must stay put (infinite distance), no popping, no visible shell edges.
4. Open the Output panel: look for shader compile errors or warnings (especially the far-plane warning).
5. Optional math check: `godot --headless --path . --import`, then `godot --headless --path . -s res://tests/unit/phase01_math_check.gd` (exit 0 = pass).

## H. Performance considerations

Expected (by design, NOT measured):
- Draw calls: stars 1, nebulae 2, planet 1, rings 1, sky 1, light none. Roughly 5 to 7 plus glow passes.
- Stars: 4000 quads = 8000 triangles. Negligible.
- Nebulae: the main GPU cost. Each layer runs a 4-octave 3D noise (32 hash lookups) for every pixel, full screen. Two layers at 4K can matter on weak GPUs. Levers: `octaves` 3, fewer layers, lower `noise_scale`.
- Sky shader: cheap; the sun is skipped in the radiance cubemap pass.
- Glow: modest cost; toggle with key 4 or `glow_enabled`.
- No per-star real-time lights; one DirectionalLight3D with shadows off.
- How to measure: HUD (FPS, frame ms, draw calls, objects, primitives), press V to disable vsync and see GPU headroom, toggle layers 1-4 one at a time and compare frame time, Godot Debugger > Monitors, and the Visual Profiler (GPU times). Report numbers and your GPU in Notion.
- Rejected alternatives: texture cubemap sky (needs art assets, no Blender), GPUParticles for stars (more cost, no benefit for static stars), one real light per star (explicitly avoided).

## Known limits

- Backdrop never parallaxes unless `follow_factor` < 1; planets cannot be approached.
- Nebula shader may band or look noisy at some seeds; tune thresholds. Rim/atmosphere is a simple fresnel.
- Floating-origin and double precision are still open (see 02, section 12). Shells are re-centered on the camera, so Phase 01 does not hit precision limits.
