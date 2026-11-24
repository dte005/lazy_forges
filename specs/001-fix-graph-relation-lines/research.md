# Research: Fix relationship lines crossing tables in the graph

**Feature**: [spec.md](./spec.md) | **Date**: 2026-10-08

There are no pending `NEEDS CLARIFICATION` items in the Technical Context of
`plan.md` — the stack (Dart + `nocterm`, no new dependencies, no automated
tests) is already known and fixed by the project. This research covers the
technical approach decisions needed to meet the behavior
defined in the spec (confirmed root cause + clarifications).

## Decision 1 — How to detect and avoid crossing tables

**Decision**: Before drawing lines, build a list of
**obstacles** (rectangles `x, y, width, height` of each table already
positioned by `GraphLayoutEngine`). Routing of each relation is then
done over that obstacle map: any candidate horizontal or
vertical segment is validated against the rectangles of all tables
except the source and target of that relation. If a segment would cross an
obstacle, routing detours through the nearest free corridor (above/below
the table row, or left/right of the column), instead of only tracing
the geometric midpoint as today.

**Rationale**: it is the minimal way to fix root cause #1 (routing blind
to other tables' positions) without rewriting `GraphLayoutEngine` or changing
table ordering (out of scope). Solving via explicit geometry
(rectangles) is simpler and more predictable on a text grid than porting a
generic pathfinding algorithm.

**Alternatives considered**:
- *A\* / cell-by-cell path search over the whole canvas*: would solve the
  problem, but is disproportionate complexity for a known grid layout
  (tables in fixed rows/columns) and would risk performance
  regression on large schemas (Principle V). Rejected for violating
  Deliberate Simplicity without proven need.
- *Ignore the problem and only truncate/hide lines that would cross tables*:
  rejected because it would hide real relationships from the user, violating the
  purpose of the graph (Principle I).

## Decision 2 — How to decide exit/entry side (replaces `sourceToRight`)

**Decision**: The side decision now considers both column (horizontal
position) and row/level (vertical position) relative between source and
target:
- Same row (level), different columns → exit on the horizontal side closest
  to the target (current behavior, preserved — FR-006).
- Same column (overlapping horizontal band), different rows → exit/enter
  vertically (top/bottom), using the vertical corridor (`rowGap`) between
  rows, never laterally.
- Different rows and columns (diagonal) → combine: exit laterally until
  aligned with the target column, then use the vertical corridor to change
  row, entering the target laterally.
- Source equals target (self-relationship) → treat as a loop: exit one
  side of the same table and re-enter an adjacent side (e.g. right then
  bottom), using only space outside the table's own rectangle,
  without depending on any other table as a side reference.

**Rationale**: fixes root cause #2 (decision based only on horizontal
center) covering exactly the cases cited in the spec (User Story 2,
Edge Cases) with simple deterministic rules, without introducing generic
distance heuristics.

**Alternatives considered**:
- *Always exit on the side closest in a straight line (angle)*: more "natural"
  visually, but would require diagonals, which do not exist in the current text
  canvas character set (`-`, `|`, `+`, arrows). Rejected for
  incompatibility with the existing orthogonal drawing.

## Decision 3 — How to distinguish relations that share the same corridor

**Decision**: Each corridor (a specific `rowGap` or `colGap` between two
adjacent tables/rows) gets a set of numbered **lanes**
(integer positions within the corridor width/height). When routing a
relation that needs to cross a corridor already used by another relation, routing
allocates the next free lane of that corridor to that relation's
segment, shifting the stroke by 1 or more columns/rows relative to what
other relations use in the same corridor. Allocation order follows
relation order in the schema (stable and deterministic, so lanes do not
"flicker" differently across identical redraws).

**Rationale**: implements the spec clarification directly ("parallel
lanes: each relation that shares a corridor receives its own
position"). Also correctly fixes, as a side effect, root cause #3
(same `midX` reused across relations).

**Alternatives considered**:
- *Keep a single stroke per corridor and only preserve the dominant color*:
  explicitly rejected in the clarification (Session 2026-10-08, question 2).

## Decision 4 — How to guarantee zero crossing even in dense layouts

**Decision**: If the number of lanes needed in a corridor exceeds the
width/height available today (`colGap = 8`, `rowGap = 3`), the affected
corridor is increased specifically as much as needed to fit
all lanes with readable spacing between them, and tables positioned
after that corridor are shifted accordingly (same cumulative
positioning logic `table_component.dart` already uses when summing
widths/heights + gaps). Table ordering in rows/columns
(`GraphLayoutEngine`) does not change — only spacing between them, when
needed.

**Rationale**: meets the strong-guarantee clarification (Session 2026-10-08,
question 1) without requiring a fully new layout engine; it is a pointed
extension of the existing spacing calculation.

**Alternatives considered**:
- *Accept residual crossing in extreme cases*: explicitly rejected
  by the clarification.
- *Always increase all graph corridors uniformly*: simpler
  to implement, but wastes space on small screens and drifts from
  Principle VII (Deliberate Simplicity / no change beyond what is
  needed); rejected in favor of pointed per-corridor adjustment.

## Decision 5 — Where the code should live

**Decision**: Create `lib/src/components/editor/components/table/graph_routing.dart`
as a pure module (no state, no `nocterm` widgets), responsible for:
receiving `GraphLayoutResult` + already computed table positions, and returning,
for each `GraphRelationEdge`, the final path (list of segments) and the arrow
point. `table_component.dart` starts calling this module instead of computing
`midX`/`sourceToRight` inline.

**Rationale**: keeps the existing separation between "distribution into
rows" (`graph_layout.dart`) and "drawing" (`table_component.dart`), without creating
new folders, and makes routing manually testable in isolation
(layout + obstacles in, path out).

**Alternatives considered**:
- *Put the logic inside `graph_layout.dart`*: would mix the
  responsibility of "distribute tables into levels" with "route lines
  between concrete positions", which are different concerns; rejected for
  clarity of responsibility.
- *Put everything inline in `table_component.dart`*: is the current state that
  caused the bug (routing logic mixed with drawing); rejected for
  being exactly the pattern that produced root causes #1–#3.

## Decision summary

| # | Decision | Resolves root cause / clarification |
|---|---|---|
| 1 | Obstacle-aware routing (table rectangles) | Root cause #1 |
| 2 | Exit/entry side by relative row AND column (+ loop for self-FK) | Root cause #2, self-relationship Edge Case |
| 3 | Numbered lanes per corridor | Root cause #3, Clarification 2 |
| 4 | Pointed corridor increase when lanes do not fit | Clarification 1 |
| 5 | New `graph_routing.dart` module | Structure/Simplicity |

All decisions are ready for Phase 1 (data-model and quickstart); no
remaining `NEEDS CLARIFICATION`.
