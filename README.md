# VOID HORIZON

*Beyond the stars. Beyond the horizon.*

Space exploration, spacecraft combat and online cooperative adventure for PC.
Arcade flight, third-person camera, stylized sci-fi.

## Engine and language

- Godot 4.x (exact version: open question Q-001, see `docs/shared_context/02_TECHNICAL_ARCHITECTURE.md`)
- Typed GDScript
- Renderer: Forward+ (PC first)

## Status

Phase 00 (Project Foundation) is implemented but **not validated**. Phase 01 (Space Environment)
is implemented on `feature/phase01-space-environment`. Nothing has been opened or tested in Godot yet.
To see Phase 01: open `scenes/environment/space_environment_test.tscn` and press F6 (details in `docs/PHASE_01_SPACE_ENVIRONMENT.md`). See `docs/shared_context/05_CURRENT_PROJECT_STATE.md`.

## Project structure

```
scenes/      main/ universe/ ships/ planets/ environment/ ui/
scripts/     core/ environment/ flight/ multiplayer/ planets/ combat/ ai/
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
- No Blender (decision D-002). Asset strategy is open (Q-008).

## Open the project in Godot

1. Clone the repository and check out `develop`.
2. Start Godot, choose **Import**, select `project.godot`.
3. Open the project. If Godot offers to upgrade the project file, accept and note the version.
4. Press **F5**. The output panel should print `VOID HORIZON booted. Phase 00 - Project Foundation.`
5. Report the result and Godot version (Notion Task 9).

## Branching and workflow

- `main`: stable state only. Updated from `develop` after user validation.
- `develop`: integrated development.
- `feature/<phase>-<short-name>`: one branch per task, one account per branch.

Every Claude account must follow `docs/shared_context/00_MASTER_CONTEXT.md` section 6:
read context, inspect the repo, review tasks, present a context report, implement only
the assigned scope, update the documents, write a handoff report.
