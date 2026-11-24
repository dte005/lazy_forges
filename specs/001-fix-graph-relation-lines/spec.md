# Feature Specification: Fix relationship lines crossing tables in the graph

**Feature Branch**: `001-fix-graph-relation-lines`

**Created**: 2026-10-08

**Status**: Planned

**Source issue**: #2

**Input**: User description: "Source: issue #2 of repository dte005/lazy_forges, '[bug] Relationship lines are crossing through tables' (label bug, milestone 'release v1.0.1'). When modeling a schema with at least 4 tables and relationships (FK) between them, the graph in the editor draws relationship lines over other tables. The arrow that indicates the relationship destination also appears poorly positioned. When several relationships follow the same path, the lines stack on top of each other and it is impossible to tell which connects what."

## Clarifications

### Session 2026-10-08

- Q: In very dense layouts, where a geometrically free corridor between source and target may not exist, must the graph ALWAYS guarantee zero crossings (even if that requires reserving more space/"lanes" between tables), or is a residual crossing acceptable in rare extreme cases as a last resort? → A: Strong guarantee — never cross tables; if the current spacing between tables is not enough to detour a line, the fix MUST increase spacing/reserve additional lanes between tables as needed to keep that guarantee.
- Q: When two or more relations truly share the same corridor segment, must the fix visually separate the strokes into distinct parallel "lanes" (each line at a different point on screen), or is it enough to ensure each relation always keeps its own visible color (without one color replacing another at the same point)? → A: Parallel lanes — each relation that shares a corridor MUST receive its own position (offset), visible side by side, not merely a preserved color on a single shared stroke.
- Q: Is a relationship where the source and target table are the same (a foreign key that references its own table) in scope for this fix? → A: Yes, in scope — self-relationship (source = target) MUST follow the same guarantees of this fix (do not cross other tables, arrow in the correct place).

## Confirmed Root Cause in Code _(mandatory)_

Graph drawing happens in
`lib/src/components/editor/components/table/table_component.dart`; table
distribution into rows/columns happens in
`.../table/graph_layout.dart`. The three hypotheses raised in the issue were
verified directly in the code and **all three are confirmed**:

1. **Routing blind to other tables' positions.** The `midX` calculation and the
   drawing of each relation's horizontal/vertical segments never consult the
   coordinates (x/y, width/height) of other already positioned tables. The only
   defense against overlap is the character-merge logic in `drawAt` (which
   combines `-`/`|` into `+` when a line already exists at the same point). That
   defense does not distinguish "empty screen space" from "whitespace inside a
   table" (column inner padding uses `padRight`, which writes literal space
   characters identical to the screen background) — so a relation line freely
   crosses a table interior whenever a horizontal or vertical segment crosses
   its area. When the line hits a table border exactly (character `-`, `|`, or
   `+`), the merge turns that border point into `+`, making the border look
   "broken" by the line.
2. **Side decision based only on horizontal center.** `sourceToRight` is
   computed by comparing only `target.centerX >= source.centerX`, without
   considering vertical position (row/level) of the tables. When source and
   target fall in the same column (same `centerX`, different graph rows/levels),
   the code still picks a side (right) and exits/enters through the table
   sides, producing a path that unnecessarily detours sideways and can cross
   neighboring tables on the same source or target row; the arrow ends on the
   lateral side of the target table, not on the side where the line actually
   arrives.
3. **`midX` and corridor duplicated across distinct relations.** `midX` is
   computed independently per relation, without recording which vertical
   columns are already used by other relations. When two or more relations
   compute the same `midX` (or pass through the same horizontal row), `drawAt`
   overlays the strokes: when it finds the same character (`-` or `|`) already
   drawn, it only replaces the previous color with the color of the relation
   drawn last, merging two or more relations into a single stroke with one
   color — making it impossible to tell which relation is which.

## User Scenarios & Testing _(mandatory)_

### User Story 1 - See the graph without lines crossing tables (Priority: P1)

As a user modeling a schema with several related tables, when I
create or change relationships (`add fk`), I want the graph in the editor to
draw relationship lines around tables, so I can read the schema without visual
confusion, even with 4 or more tables.

**Why this priority**: it is the bug reported in the issue and what most
compromises the purpose of the graph (showing the schema clearly after each
command). Without this, the graph is the central part of the editor and becomes
unusable on non-trivial schemas.

**Independent Test**: create a schema with 4+ tables and relationships whose
shortest path between source and target would cross an intermediate table;
visually verify that no line crosses the interior or border of any table.

**Acceptance Scenarios**:

1. **Given** a schema with 4 or more tables and relationships whose most
   direct path would cross other tables, **When** the editor renders the graph,
   **Then** no relationship line passes through the interior, border, or text
   of any table that is not the source or target of that relation.
2. **Given** a small schema with no routing conflict (for example, 2
   tables side by side with one relation between them), **When** the graph is
   rendered, **Then** the result is visually identical to what is produced
   today (no regression).

---

### User Story 2 - See the relationship arrow in the right place (Priority: P1)

As a user, when two related tables sit in the same column of the graph
(one above the other) or in positions where the exit/entry side is not obvious,
I want the relationship arrow to always appear next to the side of the target
table where the line actually arrives, so I can correctly identify the
relationship direction.

**Why this priority**: the poorly positioned arrow is cited in the issue as part
of the same readability problem and has the same priority impact as
User Story 1; both stem from the same geometric routing failure.

**Independent Test**: create two tables positioned in the same graph column
(one on each level/row) and relate them; verify that the arrow appears
exactly where the line meets the target table, and not on a lateral side
disconnected from the stroke.

**Acceptance Scenarios**:

1. **Given** a relationship between tables that sit in the same graph
   column (different rows/levels), **When** the graph is rendered, **Then**
   the arrow appears adjacent to the correct side of the target table, at the
   exact arrival point of the line.
2. **Given** a relationship between tables on different rows and different
   columns, **When** the graph is rendered, **Then** the arrow appears
   adjacent to the side of the target table where the stroke arrives, pointing
   into it.

---

### User Story 3 - Distinguish relationships that share the same corridor (Priority: P2)

As a user, when two or more relationships pass near each other
(same vertical or horizontal corridor), I want to visually distinguish
each one, so I do not confuse which relation links which tables.

**Why this priority**: it is a direct consequence of the same reported bug
("lines stack on top of each other"), but has impact one step below
User Stories 1 and 2 because it only shows up when there are multiple nearby
relationships — less frequent than a single line crossing a table.

**Independent Test**: create a schema where two different relations would
naturally compute the same routing column (for example, two FKs leaving
neighboring tables toward the same target); verify that the two lines are
drawn in distinct parallel lanes, each with its color, without occupying the
same point on screen.

**Acceptance Scenarios**:

1. **Given** two or more relationships whose computed routing would
   coincide in the same corridor, **When** the graph is rendered, **Then**
   each relationship is drawn in its own lane within the corridor,
   side by side, with its color preserved, without one relation overlaying or
   visually replacing the other.

---

### Edge Cases

- What happens when the source and target tables are on the same graph row
  (level), side by side, with no table between them? (Already works
  today — must keep working without regression.)
- What happens when the source and target tables are in the same
  column (one directly above/below the other), with no table beside them?
- What happens when there are multiple FKs between the same pair of tables?
- What happens when a table has an FK that references itself
  (self-relationship, source and target are the same table)? It is in
  scope for this fix and MUST follow the same guarantees (without crossing other
  tables, arrow on the correct side).
- What happens with a relationship that, to avoid crossing tables, needs
  to go around an entire row of tables (wide schema)?
- What happens on a schema with dozens of tables (performance and
  readability remain acceptable)?
- What happens when opening a project saved before this fix, whose
  JSON file has no layout information (layout is always recalculated)?

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: The graph MUST draw each relationship line without passing
  through the interior, border, or text of any table that is not the
  source or target of that specific relation, even on schemas with 4 or
  more tables and crossed relationships. That guarantee MUST always hold,
  with no exception: when the current spacing between tables is not enough
  to detour a line, the fix MUST increase spacing (reserve additional
  lanes/corridors) as much as needed to keep zero crossings — a residual
  crossing is never acceptable as a final solution.
- **FR-002**: The graph MUST position each relationship arrow always
  adjacent to the side of the target table where the line actually arrives,
  pointing at that table, regardless of whether source and target are
  on the same row, same column, diagonal positions in the graph, or are the
  same table (self-relationship).
- **FR-003**: When two or more relationships occupy the same corridor
  (same routing column or row), the graph MUST assign each
  relation its own position (lane/offset) within that corridor, so
  the strokes are visible side by side, each with its color, instead of
  occupying exactly the same point on screen.
- **FR-004**: The graph MUST continue to be recalculated and redrawn on every
  command that changes tables, columns, or relationships, exactly as
  it does today.
- **FR-005**: The graph MUST continue to respond in a perceptibly
  instantaneous way on large schemas (dozens of tables), without introducing
  delays noticeable relative to current behavior. Validation reference: graph
  redraw after a command MUST stay under ~100ms (human threshold for
  instantaneous response), even on schemas with dozens of
  tables.
- **FR-006**: For schemas with no routing conflict (for example, two
  tables side by side with a single relation between them), the graph MUST
  continue to be drawn exactly as it is today (no visual regression).
- **FR-007**: The fix MUST preserve loading of projects saved
  (`lazyforge_projects/`) before this change; the graph is recalculated from
  the project schema, without depending on any persisted layout
  information.
- **FR-008**: The fix MUST be limited to routing and drawing of relationship
  lines and arrows; it MUST NOT change table layout/ordering in
  rows, the color palette, commands, parsing, DDL export, or
  persistence, unless the confirmed root cause requires a pointed change
  at those points.

### Key Entities _(include if feature involves data)_

- **Relationship (FK) on the graph**: visual representation of a foreign
  key between two already modeled tables; has a source table/column,
  a target table/column, a path of lines on the text canvas, and an
  arrow indicating the target.
- **Table positioned on the graph**: text rectangle with position (x, y),
  width and height, computed from the schema and distribution into
  rows/columns; it is the obstacle that relationship lines must not
  cross.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: On a schema with 4 or more tables and crossed relationships,
  no relationship line visually overlays the interior, border, or
  text of a table that is neither source nor target of that relation.
- **SC-002**: On any relationship, the arrow always appears adjacent to the
  side of the target table where the line arrives, never disconnected from the
  stroke or on a side that does not match the drawn path.
- **SC-003**: When two or more relationships share the same
  routing corridor, each is drawn in its own lane, side by
  side, allowing a user to visually identify without ambiguity
  which line belongs to which relationship.
- **SC-004**: Schemas that were already drawn correctly before the fix
  (no routing conflict) continue to be drawn exactly as
  before.
- **SC-005**: A project saved before this fix opens normally and has its
  graph displayed without errors.

## Assumptions

- Table layout in rows/columns (who sits on which row, in what
  order) is considered correct today and is not the target of this fix; only
  relationship-line routing and arrow placement are
  fixed, unless the confirmed root cause requires a pointed adjustment. Spacing
  between tables (horizontal and vertical gaps) is treated differently from
  ordering: it MAY be increased when needed to ensure there is always enough
  free corridor to detour a line without crossing tables (see Clarifications,
  Session 2026-10-08); that does not count as a "layout/ordering" change for
  Out of Scope purposes.
- "Going around tables" means the line may use additional horizontal and
  vertical segments (detouring through free corridors between
  tables) instead of the shortest path, whenever the shortest path
  would cross a table.
- The existing per-relationship color palette remains the
  primary visual distinction mechanism between relations; this fix may
  reinforce it (for example, preventing one color from replacing another at the
  same point) but does not introduce a new color mechanism.
- This fix does not introduce user interaction with the graph (no
  zoom, scrolling, or dragging tables); the graph remains read-only,
  recalculated on every command.

## How to Validate Manually

1. Run `dart --enable-vm-service bin/lazy_forge.dart` and create a project.
2. Create 4 or more tables with PK and columns, and relate them with `add fk` so
   that: (a) some relation needs to cross an intermediate row of
   tables, and (b) another relation joins tables in the same graph column.
3. Visually confirm that no line crosses the interior, border, or
   text of any table; that arrows appear on the correct side of the
   target table; and that nearby relations remain distinguishable (different
   colors, strokes not merged).
4. Create a simple 2-table side-by-side schema with one relation and
   confirm the drawing stays the same as current behavior (no
   regression).
5. Reopen a project saved before this fix (existing JSON file in
   `lazyforge_projects/`) and confirm it loads normally and the
   graph is displayed.

## Task Execution

- Every activity/task for this spec (technical planning and implementation)
  MUST rely on the Dart skills already available in the project under
  `.github/skills/` (e.g. `dart-fix-runtime-errors`, `dart-run-static-analysis`,
  `dart-use-pattern-matching`, `dart-add-unit-test`, among others), consulting
  the skill relevant to the kind of work being done, instead of deciding the
  approach only on one's own when an equivalent skill already exists.
- At the end of executing all tasks for this spec, the
  `test-manager-executer` subagent (defined in `.github/agents/test-manager-executer.md`)
  MUST be run, so that the test verification/management planned by
  that subagent runs over the fix result before considering it
  complete.

## Out of Scope

- Changing table layout/ordering in rows, the relation color
  palette, commands, parsing, DDL export, or persistence, except
  if the confirmed root cause requires it.
- Any refactoring not necessary to fix this bug.
- New graph features (zoom, scrolling, dragging tables).
- Creating folders or files that fall outside the project's existing
  folder architecture.

## Constraints

- Do not change existing behavior outside this bug (constitution stability
  principle — `.specify/memory/constitution.md`).
- Keep loading of JSON projects already saved in `lazyforge_projects/`.
- Respect the existing folder organization under `lib/src/`.
- Do not add new dependencies to `pubspec.yaml`.
- User-facing messages (when any) in Portuguese, clear and without stack
  trace.
- Task execution (see "Task Execution") MUST rely on the
  Dart skills under `.github/skills/` when relevant, and MUST finish with
  running the `test-manager-executer` subagent (`.github/agents/`).
- The subagent is an on-demand exception, non-blocking
- The routing technique (specific algorithm to go around tables) is not
  decided in this spec; `/speckit-plan` is responsible for describing the
  resulting correct behavior, not the implementation.
