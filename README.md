# VOID HORIZON

*Beyond the stars. Beyond the horizon.*

Space exploration, spacecraft combat and online cooperative adventure for PC.
Arcade flight, third-person camera, stylized sci-fi.

## Engine and language

- Godot 4.7.2 (confirmed by the user)
- Typed GDScript
- Renderer: Forward+ (PC first)

## Status

Phase 00 is not validated in Godot. The user opened the earlier Phase 02 build in Godot 4.7.2 and reported that F5 works; the current custom GLB replacement in `VisualRoot/ShipModel` still needs to be checked in Godot.
To see Phase 01: open `scenes/environment/space_environment_test.tscn` and press F6 (details in `docs/PHASE_01_SPACE_ENVIRONMENT.md`).
To see the ship: open `scenes/ships/ship_inspection.tscn` and press F6 (`docs/PHASE_02_LIGHT_FIGHTER.md`). See `docs/shared_context/05_CURRENT_PROJECT_STATE.md`.

## Project structure

```
scenes/      main/ universe/ ships/ planets/ environment/ ui/
scripts/     core/ environment/ ships/ flight/ multiplayer/ planets/ combat/ ai/
assets/      models/ materials/ textures/ audio/ vfx/
resources/   ships/ planets/ weapons/ settings/
systems/     world_generation/ navigation/ networking/ streaming/
tests/       unit/ integration/ performance/
docs/shared_context/   project memory (documents 00-07)
```

Empty folders contain a `.gitkeep` only so Git tracks them. Remove it when real files arrive.

## Development requirements

- Godot 4.x editor (standard build, GDScript; no .NET needed)
- Git
- Blender is not required to run or build the project; ship models are imported as GLB assets (D-002).

## Open the project in Godot

1. Clone the repository and check out `develop`.
2. Start Godot, choose **Import**, select `project.godot`.
3. Open the project. If Godot offers to upgrade the project file, accept and note the version.
4. Press **F5**. On the Phase 02 branch this runs `scenes/ships/ship_inspection.tscn` (the ship against the planet). The old Phase 00 `scenes/main/main.tscn` is an empty scene: it only shows a grey screen and prints `VOID HORIZON booted. Phase 00 - Project Foundation.` in the Output panel.
5. Report the result and Godot version (Notion Task 9).

## Branching and workflow

- `main`: stable state only. Updated from `develop` after user validation.
- `develop`: integrated development.
- `feature/<phase>-<short-name>`: one branch per task, one account per branch.

Every Claude account must follow `docs/shared_context/00_MASTER_CONTEXT.md` section 6:
read context, inspect the repo, review tasks, present a context report, implement only
the assigned scope, update the documents, write a handoff report.
