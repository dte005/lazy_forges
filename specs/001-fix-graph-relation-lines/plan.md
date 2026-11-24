# Implementation Plan: Fix relationship lines crossing tables in the graph

**Branch**: `001-fix-graph-relation-lines` | **Date**: 2026-10-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-fix-graph-relation-lines/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

The editor relationship graph (`table_component.dart` + `graph_layout.dart`)
routes each relationship line without geometric knowledge of other
already positioned tables, decides the exit/entry side looking only at the
horizontal center of tables, and does not reserve its own space for relations that
share the same corridor. That causes lines crossing tables, poorly
positioned arrows, and indistinguishable relations when nearby (issue #2).

The technical approach introduces an **obstacle- and lane-aware routing**
step, run after the current `GraphLayoutEngine` and
before drawing in `table_component.dart`:

1. Build, on every render, the list of rectangles occupied by each
   already positioned table (obstacles).
2. For each relation, choose the exit/entry strategy (lateral,
   vertical, or combined) based on the real relative position between source and
   target — row (level) and column — not only the horizontal center.
3. Allocate each relation segment to a **lane** within the corridor
   (`colGap`/`rowGap`) it crosses; relations that share the same corridor
   receive distinct positions (offsets) within it.
4. If the available space in a corridor cannot fit all required
   lanes, increase that corridor specifically (recomputing positions of
   affected tables) as much as needed — never accept a residual
   crossing.
5. Before drawing, validate that no segment of the final path crosses the
   rectangle of a table that is not the source or target of that relation
   (including self-relationship, treated as a loop that exits and
   re-enters the same table on different sides).

No new dependency is required; the change stays in the same folder
(`lib/src/components/editor/components/table/`), as a new helper routing
module consumed by `table_component.dart`.

## Technical Context

**Language/Version**: Dart (SDK ^3.11.4, per `pubspec.yaml`)

**Primary Dependencies**: `nocterm` (TUI already used by the project); no
new dependency is introduced by this fix.

**Storage**: N/A — the graph is recalculated in memory from `SchemaState`
on every render; there is no layout persistence (FR-007). Project files
in `lazyforge_projects/` continue to be read without format
change.

**Testing**: N/A — the project does not require an automated test suite
(constitution decision); validation by manual review per
`quickstart.md`.

**Target Platform**: Cross-platform terminal (Linux, WSL, macOS, Windows);
bug reported on Linux/WSL, but the fix must apply to any terminal
supported by `nocterm`.

**Project Type**: Single-project terminal application (TUI) in Dart.

**Performance Goals**: Graph redraw perceptibly instantaneous on every
command (reference: under ~100ms), keeping the standard already required by the
constitution (Principle V — Perceived Speed as a Requirement), including
on schemas with dozens of tables and multiple relationships.

**Constraints**: No new dependencies; do not create or expand automated
tests; do not change commands, parsing, DDL export, or persistence;
do not create folders outside the existing structure (`lib/src/components/editor/components/table/`);
schemas with no routing conflict must continue to be drawn
exactly as today (FR-006); zero-crossing guarantee must always hold,
even if that requires increasing spacing between tables (see Clarifications
in the spec).

**Scale/Scope**: Schemas with 4 or more tables and crossed relationships
(minimum reproduction case from the issue) up to dozens of tables with multiple
concurrent relationships in the same corridor, including self-relationship.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Assessment |
|---|---|
| I. Interface in Service of the Decision | PASS — the fix exists exactly so the graph again communicates the real schema state (correct lines and arrows); it introduces no new decorative element. |
| II. Commands that Speak SQL | N/A — no command is created, changed, or removed by this fix. |
| III. Portable Result, Never Locked In | N/A — does not change DDL export or project file format (FR-007, FR-008). |
| IV. Terminal End to End | PASS — the fix is purely visual inside the existing TUI; it introduces no mouse interaction and depends on no external tool. |
| V. Perceived Speed as a Requirement | PASS WITH ATTENTION — obstacle-aware routing adds work per relation (check obstacles, allocate lanes). Kept simple (linear scan over tables and corridors, no generic path search like A*) to preserve instantaneous response on dozens of tables, per FR-005. Must be revalidated manually with a large schema in the quickstart. |
| VI. Trust from the First Command | PASS — improves reliability of the graph's visual feedback, which is redrawn on every command; does not change the auto-save flow or support for the three engines. |
| VII. Deliberate Simplicity | PASS WITH JUSTIFICATION — lane allocation and pointed spacing increase are the most direct way to meet the zero-crossing guarantee required in the spec (Clarifications); this is not speculative complexity, it is an explicit user requirement. No extra abstraction (e.g. generic graph engine) is introduced beyond what is needed. |
| VIII. Stability of What Already Exists | PASS — FR-006 requires schemas with no routing conflict to remain exactly the same as today; the change is additive (new routing step), does not rewrite `GraphLayoutEngine` or the saved project format. |

No unjustified violations. No entry needed in
"Complexity Tracking".

**Post–Phase 1 re-evaluation**: `research.md` and `data-model.md` confirm that the
approach remains a linear scan over obstacles and corridors (no
generic pathfinding) and that no new entity is persisted — only
internal rendering structures. The PASS and PASS WITH
ATTENTION/JUSTIFICATION statuses above remain valid; no principle changes
assessment after detailed design.

## Project Structure

### Documentation (this feature)

```text
specs/001-fix-graph-relation-lines/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md         # Phase 1 output (/speckit-plan command)
├── quickstart.md         # Phase 1 output (/speckit-plan command)
└── tasks.md              # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

There is no `contracts/`: this fix exposes no new public interface
(API, command, or file format); it is an internal adjustment to graph
rendering in the editor.

### Source Code (repository root)

```text
lib/src/components/editor/
├── components/
│   └── table/
│       ├── graph_layout.dart      # already exists — table distribution into rows/columns (NOT changed in its public API)
│       ├── graph_routing.dart     # NEW — obstacles, side decision, lane allocation, and spacing adjustment
│       └── table_component.dart   # already exists — starts consuming graph_routing.dart to draw lines/arrows
└── models/
    └── graph_model.dart           # already exists — may gain helper fields (e.g. allocated lane) without breaking the persisted SchemaState format
```

**Structure Decision**: Single project (Dart TUI). The fix lives entirely
inside `lib/src/components/editor/components/table/`, the same folder where the
bug was located, adding a new helper module (`graph_routing.dart`)
instead of inflating `table_component.dart` or `graph_layout.dart` with
additional responsibilities. No new folder is created, per the
spec scope constraint.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No Constitution Check violation requires an entry in this table.
