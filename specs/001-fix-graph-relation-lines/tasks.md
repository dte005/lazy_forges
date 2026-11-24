---

description: "Task list for fixing graph relationship line crossing (issue #2)"
---

# Tasks: Fix relationship lines crossing tables in the graph

**Input**: Design documents from `specs/001-fix-graph-relation-lines/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Not required as an acceptance criterion for this fix
(constitution `.specify/memory/constitution.md`, Principle VIII and
`.github/copilot-instructions.md`); primary validation is manual via `quickstart.md`. The spec
("Task Execution" section) also requires that the final task (T025)
run the `test-manager-executer` subagent, whose result is informative and
does not block delivery of this fix.

**Organization**: Tasks grouped by User Stories from `spec.md` (US1 and
US2 are P1; US3 is P2). Per the "Task Execution" section of `spec.md`,
every implementation task MUST rely on the relevant Dart skill under
`.github/skills/` when an equivalent exists; each task below indicates the
applicable skill in brackets `(skill: ...)` when relevant.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on incomplete task)
- **[Story]**: User story the task belongs to (US1, US2, US3)
- Exact file paths are included in each description

## Path Conventions

Single Dart project. All work happens in:
- `lib/src/components/editor/components/table/graph_routing.dart` (NEW)
- `lib/src/components/editor/components/table/table_component.dart` (existing)
- `lib/src/components/editor/components/table/graph_layout.dart` (existing, not changed in its public API — only touched by T009/T018, and only if dynamic corridor expansion requires exposing `rowGap`/`colGap` as parameters)
- `lib/src/components/editor/models/graph_model.dart` (existing, may gain helper fields without breaking the persisted `SchemaState` format)

---

## Phase 1: Setup

**Purpose**: Create the skeleton of the new routing module before any logic.

- [X] T001 Create `lib/src/components/editor/components/table/graph_routing.dart` with the module header (imports of `graph_model.dart` and `schema_model.dart`) and the empty classes `TableObstacle`, `RoutingCorridor`, `RoutingLaneAssignment`, `RoutedEdge`, `RoutedSegment` described in `data-model.md` (fields only, no logic yet) (skills: `../../.github/skills/dart-use-primary-constructors` for those class constructors; `../../.github/skills/dart-write-documentation` to document the public module)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Routing infrastructure that ALL user stories (US1, US2, US3) need before any visible fix.

**⚠️ CRITICAL**: No user story can be implemented before this phase.

- [X] T002 [P] Implement a function that builds the list of `TableObstacle` (one per table: `tableKey`, `x`, `y`, `width`, `height`) from the already computed `nodesByName` map (`_TableNodeLayout`), in `lib/src/components/editor/components/table/graph_routing.dart` (skill: `../../.github/skills/dart-use-primary-constructors`)
- [X] T003 [P] Implement `RoutingCorridor`/`RoutingLaneAssignment` as internal structures (no allocation logic yet, constructors only) in `lib/src/components/editor/components/table/graph_routing.dart`, ensuring `allocatedLanes` starts empty and `availableSpan` starts with the current `colGap`/`rowGap` (8 and 3, respectively) (skill: `../../.github/skills/dart-use-primary-constructors`)
- [X] T004 Implement the new side/orientation decision function (replaces `sourceToRight`), considering relative row (level) AND column between source and target — same row → lateral; same column → vertical; diagonal → lateral+vertical combination — in `lib/src/components/editor/components/table/graph_routing.dart` (depends on T002) (skill: `../../.github/skills/dart-use-pattern-matching` for the orientation decision `switch`/pattern matching)
- [X] T005 Implement the self-relationship case (source = target) as a loop that exits one side of the same table and re-enters an adjacent side, validated against `TableObstacle`s of other tables, in `lib/src/components/editor/components/table/graph_routing.dart` (depends on T004) (skill: `../../.github/skills/dart-use-pattern-matching`)
- [X] T006 Replace, in `lib/src/components/editor/components/table/table_component.dart`, the inline `sourceToRight`/`midX` calculation (in both loops over `layout.edges`, including the canvas bounds calculation) with calls to the new routing function from `graph_routing.dart`, keeping the rest of the drawing flow (`drawAt`, `drawText`, colors) intact (depends on T004, T005)

**Checkpoint**: From here, `table_component.dart` already draws using the new routing module (still without avoiding obstacles or lanes); user stories then add behavior guarantees on top of this base.

---

## Phase 3: User Story 1 - See the graph without lines crossing tables (Priority: P1) 🎯 MVP

**Goal**: No relationship line passes through the interior, border, or text of a table that is not the source/target of that relation (FR-001, SC-001).

**Independent Test**: Create a schema with 4+ tables and relationships whose shortest path would cross an intermediate table; visually verify that no line crosses the interior or border of any table (quickstart.md Scenario 1).

### Implementation for User Story 1

- [X] T007 [US1] Implement collision check of a candidate segment (horizontal or vertical) against the `TableObstacle` list, excluding the source and target tables of the relation itself, in `lib/src/components/editor/components/table/graph_routing.dart` (depends on T002)
- [X] T008 [US1] Implement path construction (`segments`) that detours through free corridors (`colGap`/`rowGap`) whenever the direct segment would collide with an obstacle, reusing the side decision from T004, in `lib/src/components/editor/components/table/graph_routing.dart` (depends on T004, T007) (skill: `../../.github/skills/dart-use-pattern-matching`)
- [X] T009 [US1] Implement pointed corridor expansion (increase `availableSpan` and recompute positions of tables placed after it) when current space is not enough to detour a line without crossing tables — never accept residual crossing, per FR-001 ("when the current spacing between tables is not enough to detour a line, the fix MUST increase spacing... as much as needed to keep zero crossings") — in `lib/src/components/editor/components/table/graph_routing.dart` and `lib/src/components/editor/components/table/table_component.dart` (depends on T008)
- [X] T010 [US1] Replace, in `lib/src/components/editor/components/table/table_component.dart`, direct calls to `drawHorizontal`/`drawVertical` with fixed `midX` by drawing the `segments` returned by routing (T008/T009), preserving each relation's color (depends on T008, T009)
- [X] T011 [US1] Manually validate Scenario 1 of `quickstart.md` (schema with 4+ tables, relation crossing intermediate table), Scenario 5 (2-table schema with no conflict, confirming no regression per FR-006), and Scenario 8 (detour around an entire row of tables) (depends on T010) (support skill if a runtime error appears during validation: `../../.github/skills/dart-fix-runtime-errors`)

**Checkpoint**: User Story 1 complete and independently testable — no line crosses tables, and simple schemas remain the same as today.

---

## Phase 4: User Story 2 - See the relationship arrow in the right place (Priority: P1)

**Goal**: Each relationship arrow always appears adjacent to the side of the target table where the line actually arrives (FR-002, SC-002).

**Independent Test**: Create two tables in the same graph column (different levels) and relate them; verify the arrow appears exactly where the line meets the target table (quickstart.md Scenario 2).

### Implementation for User Story 2

- [X] T012 [US2] Implement `arrowPoint` calculation (x/y position and `up`/`down`/`left`/`right` direction) from the orientation and end point of the last segment of the routed path (T008), covering same-row, same-column, and diagonal cases, in `lib/src/components/editor/components/table/graph_routing.dart` (depends on T008) (skill: `../../.github/skills/dart-use-pattern-matching`)
- [X] T013 [US2] Update arrow drawing in `lib/src/components/editor/components/table/table_component.dart` to use `arrowPoint` (character `>`/`<`/`^`/`v` per direction) instead of the fixed pair `targetInX`/`sourceToRight ? '>' : '<'`, ensuring the arrow is always adjacent to the correct side of the target table (depends on T012)
- [X] T014 [US2] Validate that the self-relationship loop (T005) also produces a correct `arrowPoint`, pointing back at the same table, in `lib/src/components/editor/components/table/graph_routing.dart` (depends on T005, T012)
- [X] T015 [US2] Manually validate Scenario 2 (tables in the same column) and Scenario 4 (self-relationship) of `quickstart.md` (depends on T013, T014) (support skill: `../../.github/skills/dart-fix-runtime-errors`)

**Checkpoint**: User Stories 1 and 2 complete and independently testable — lines do not cross tables and arrows are always on the correct side, including same column and self-relationship.

---

## Phase 5: User Story 3 - Distinguish relationships that share the same corridor (Priority: P2)

**Goal**: Relationships that share the same routing corridor receive their own lanes (offsets), visible side by side, without merging into a single stroke (FR-003, SC-003).

**Independent Test**: Create a schema where two different relations would compute the same routing column/row; verify both lines appear in distinct parallel lanes, each with its color (quickstart.md Scenario 3).

### Implementation for User Story 3

- [X] T016 [US3] Implement lane allocation per corridor: when routing a relation that would cross a `RoutingCorridor` already used by another, assign the next free `offset`, with "each `edgeIndex` having a unique `offset`" within the same corridor and allocation order following `edgeIndex` order (deterministic across redraws), in `lib/src/components/editor/components/table/graph_routing.dart` (depends on T008) (skill: `../../.github/skills/dart-use-pattern-matching`)
- [X] T017 [US3] Apply the allocated `offset` (T016) by shifting the corresponding segment of the routed path so relations in the same corridor sit on distinct columns/rows within the corridor, in `lib/src/components/editor/components/table/graph_routing.dart` (depends on T016)
- [X] T018 [US3] Extend corridor expansion (T009) to consider the number of lanes needed in that corridor (not only passage of a single line), increasing `availableSpan` enough to fit all lanes with readable spacing, in `lib/src/components/editor/components/table/graph_routing.dart` (depends on T009, T016)
- [X] T019 [US3] Manually validate Scenario 3 of `quickstart.md` (two relations in the same corridor, parallel lanes and distinct colors) and Scenario 3b (multiple FKs between the same pair of tables) (depends on T017, T018) (support skill: `../../.github/skills/dart-fix-runtime-errors`)

**Checkpoint**: All user stories complete and independently testable.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation covering performance, compatibility, and cleanup, per FR-004, FR-005, FR-007 and Constraints in the spec.

- [X] T020 [P] Manually validate Scenario 6 of `quickstart.md` (open a project saved in `lazyforge_projects/` before this fix and confirm it loads normally and the graph is displayed, SC-005)
- [X] T021 [P] Manually validate Scenario 7 of `quickstart.md` (schema with dozens of tables and crossed relationships; confirm graph redraw remains perceptibly instantaneous after each command, FR-005)
- [X] T022 Remove any remaining `sourceToRight`/`midX` calculation and dead code in `lib/src/components/editor/components/table/table_component.dart` after full migration to `graph_routing.dart`
- [X] T023 Review `lib/src/components/editor/components/table/graph_routing.dart` and `table_component.dart` to confirm no command, parsing, DDL export, or persistence format was changed (FR-008), and that the graph continues to be recalculated on every command with no persisted layout information (FR-004, FR-007)
- [X] T024 Run static analysis and formatting on the changed files (`graph_routing.dart`, `table_component.dart`), supported by skill `../../.github/skills/dart-run-static-analysis`, and fix any findings before considering the fix ready (depends on T022, T023)
- [X] T025 Run the `test-manager-executer` subagent (`.github/agents/test-manager-executer.md`), as required by the "Task Execution" section of `spec.md`, after all other tasks are done; the result (tests created under `tests/` and coverage report) is informative and does NOT block delivery of this fix — consistent with the policy already stated in the subagent itself ("tests are not an acceptance criterion") (depends on T001-T024)

**Note on T025**: the spec (`spec.md`, "Task Execution" and "Constraints" sections) contains a tension between "do not create or expand automated tests" and the requirement to run a subagent whose purpose is precisely to create automated tests (see `/speckit-analyze`, finding F1). This task assumes the least invasive reading possible: T025 runs last, does not block completion of the other tasks, and any test it creates stays isolated under `tests/` (outside `lib/`, `bin/`, and `pubspec.yaml`). That contradiction in the spec has not yet been resolved by the maintainer and should be clarified before implementation.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories.
- **User Story 1 (Phase 3)**: Depends only on Foundational.
- **User Story 2 (Phase 4)**: Depends on Foundational; reuses path routing from T008 (US1), so it should follow US1 or be developed in parallel with careful merge on the same file.
- **User Story 3 (Phase 5)**: Depends on Foundational and T008/T009 (US1).
- **Polish (Phase 6)**: Depends on all desired user stories being complete. Within Polish, T024 (static analysis) depends on T022/T023; T025 (`test-manager-executer` subagent) depends on T001-T024 and must be the last task executed.

### User Story Dependencies

- **US1 (P1)**: No dependency on another story; it is the MVP.
- **US2 (P1)**: Technically depends on the routed path produced in US1 (T008) to compute `arrowPoint`, but is independently testable and deliverable (the arrow can be fixed even if US1 dynamic corridor expansion is not yet complete).
- **US3 (P2)**: Depends on the routed path from US1 (T008) and corridor expansion (T009) to allocate lanes correctly.

### Within Each User Story

- Routing logic before integration with drawing (`table_component.dart`).
- Implementation before manual validation (quickstart).
- Story complete before moving to the next priority.

### Parallel Opportunities

- T002 and T003 (Foundational) can run in parallel (independent data structures).
- T020 and T021 (Polish) can run in parallel (independent validation scenarios).
- Within the same phase, tasks with no declared dependency on each other and on different files can be parallelized; in this fix most code concentrates in `graph_routing.dart`, so real parallelism is limited — most tasks are sequential because they touch the same file.

---

## Parallel Example: Foundational Phase

```bash
# Launch the independent Phase 2 data structures together:
Task: "Implement TableObstacle and obstacle list construction in graph_routing.dart"
Task: "Implement RoutingCorridor/RoutingLaneAssignment in graph_routing.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: test User Story 1 independently (quickstart Scenarios 1 and 5)
5. This is already the MVP that fixes the most severe symptom of issue #2 (lines crossing tables)

### Incremental Delivery

1. Setup + Foundational → routing base ready
2. US1 → validate independently → already fixes the main issue symptom
3. US2 → validate independently → fixes the poorly positioned arrow
4. US3 → validate independently → resolves relation overlap in the same corridor
5. Polish → validates compatibility with old projects and performance on large schemas, runs static analysis (T024) and, last, the `test-manager-executer` subagent (T025)

---

## Notes

- [P] = different files/structures, no pending dependency
- [Story] identifies each task's user story for traceability with `spec.md`
- No automated test tasks created by this fix; the only exception is T025, which delegates to the `test-manager-executer` subagent in an informative, non-blocking way, per the "Task Execution" section of `spec.md`
- Every implementation task with an equivalent Dart skill under `.github/skills/` indicates the skill in parentheses; consult the corresponding `SKILL.md` before implementing
- Validate each story manually (quickstart.md) before moving to the next
- No new folder is created; all work stays under `lib/src/components/editor/components/table/` and `lib/src/components/editor/models/graph_model.dart`, per Constraints in the spec
- **Attention**: the tension between "do not create automated tests" (Constraints) and the T025 requirement (see note after T025) is an unresolved contradiction in `spec.md` (finding F1 from `/speckit-analyze`); recommend resolving it before starting `/speckit-implement`
