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
| D-013 | `project.godot` assumes Godot 4.3 / Forward+ until Q-001 is answered. | Proposed |
