# 00 MASTER CONTEXT

## 1. Identity
VOID HORIZON: space exploration, spacecraft combat and online cooperative adventure.
Godot 4.x, typed GDScript, PC first. Arcade flight, third-person camera, stylized sci-fi.
Tagline: "Beyond the stars. Beyond the horizon."

## 2. Source of truth
1. Google Drive `VOID_HORIZON_SHARED_CONTEXT`: official design and technical documentation.
2. GitHub `KAITO500/VOID-HORIZON`: source code and history. Copies of documents 00-07 live in `docs/shared_context/`.
3. Notion workspace "VOID HORIZON - Project Overview": tasks, phases, bugs, decisions, development log.

**Copy conflict warning:** a Drive folder with documents 00-07 was reported by an earlier account, but it was
not readable from the account that rebuilt Phase 00. The repo copies were written from the Phase 00 prompt
and Notion records, not from the Drive originals. Reconcile before treating either as final.

## 3. Status vocabulary
Planned, Designed, Implemented, Reviewed, Executed, Tested in Godot, Validated by the user.
Never claim a later state than what was verified.

## 4. Rules
- Do not rename, replace or duplicate existing systems without a documented reason.
- Inspect files and dependencies before changing code.
- If repo and documents disagree, report the conflict before structural changes.
- Never invent project history.

## 5. Phases
00 Foundation, 01 Space Environment, 02 First Spacecraft, 03 Flight System, 04 Star Systems,
05 Planetary Systems, 06 Atmospheres and Landing, 07 Space Combat, 08 Cooperative Multiplayer,
09 Artificial Intelligence, 10 Exploration and Progression, 11 Polish and Optimization.
Do not start the next phase without user approval.

## 6. Mandatory account handoff
Every Claude account must:
1. Read the shared context (documents 00-07).
2. Inspect the relevant GitHub files and branches.
3. Review task status in Notion.
4. Present a PROJECT CONTEXT REPORT (identity, phase, architecture, implemented systems, last task, current task, issues, next task, conflicts).
5. Implement only the assigned scope.
6. Update documents 03, 05, 06, 07 and Notion.
7. Finish with the handoff report format in `06_HANDOFF_REPORT.md`.

Never rely on conversation memory. One account edits a given set of files at a time; parallel work goes on `feature/*` branches. Never overwrite another account's unintegrated work. Push only when the user authorizes it.

## 7. Bootstrap prompt for a new conversation
"You are joining VOID HORIZON, an existing Godot 4.x project. Do not start anything new. Read Drive folder
VOID_HORIZON_SHARED_CONTEXT (or `docs/shared_context/` in the GitHub repo KAITO500/VOID-HORIZON if Drive is
unavailable), inspect the repo and the Notion workspace, present the PROJECT CONTEXT REPORT, then wait for the assigned task."
