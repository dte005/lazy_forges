# Data Model: Fix relationship lines crossing tables in the graph

**Feature**: [spec.md](./spec.md) | **Research**: [research.md](./research.md)

This document describes the conceptual entities involved in graph
routing. They are internal rendering structures (not persisted, recalculated
on every draw from the existing `SchemaState`) — they do not change the
format of projects saved in `lazyforge_projects/` (FR-007).

## TableObstacle

Represents the rectangle occupied by an already positioned table, used to
prevent any relation segment from crossing it.

| Field | Type | Description |
|---|---|---|
| `tableKey` | String | Table name in lowercase (identity key) |
| `x`, `y` | int | Top-left corner on the text canvas |
| `width`, `height` | int | Rectangle dimensions (same as already computed today in `_TableNodeLayout`) |

**Validation rule**: no segment of a relation whose `sourceTable` and
`targetTable` differ from this `tableKey` may occupy a cell inside
this rectangle (including the border). For the relation's own source/target,
only the exit/entry point (on the border) is allowed.

## RoutingCorridor (Lane/Corridor)

Represents the free space between two tables (or two table rows)
through which relations may pass.

| Field | Type | Description |
|---|---|---|
| `orientation` | enum: `horizontal` \| `vertical` | Whether the corridor runs between columns (`colGap`) or between rows (`rowGap`) |
| `position` | int | Fixed coordinate of the corridor (e.g. the Y line of `rowGap`, or the X band of `colGap`) |
| `availableSpan` | int | Width/height available today (`colGap = 8` or `rowGap = 3`, may grow per Decision 4) |
| `allocatedLanes` | List\<RoutingLaneAssignment\> | Lanes already assigned within this corridor, in allocation order |

**Validation rule**: `allocatedLanes.length` never exceeds the number of
lanes that fit in `availableSpan` with readable spacing between them; if it
would exceed, `availableSpan` is increased before allocating the new lane (never the
reverse).

## RoutingLaneAssignment

Associates a specific relation with a position (offset) inside a
`RoutingCorridor`.

| Field | Type | Description |
|---|---|---|
| `edgeIndex` | int | Relation index in `GraphLayoutResult.edges`, used as stable identity |
| `offset` | int | Displacement within the corridor (0 = center/default position, 1, 2, ... for additional lanes) |

**Validation rule**: within the same `RoutingCorridor`, each `edgeIndex`
has a unique `offset`; allocation order follows `edgeIndex` order
(deterministic across identical redraws of the same schema).

## RoutedEdge

Final routing result for an existing `GraphRelationEdge` (from
`graph_model.dart`), ready to be drawn by `table_component.dart`.

| Field | Type | Description |
|---|---|---|
| `edge` | GraphRelationEdge | Reference to the original relation (source/target/columns) |
| `segments` | List\<RoutedSegment\> | Ordered list of horizontal/vertical segments forming the full path, already free of obstacle collision |
| `arrowPoint` | (x: int, y: int, direction: enum `up`\|`down`\|`left`\|`right`) | Point where the arrow is drawn, always adjacent to the side of the target table where the last segment arrives |
| `color` | Color | Color already assigned today per relation (existing palette, unchanged) |

### RoutedSegment

| Field | Type | Description |
|---|---|---|
| `orientation` | enum: `horizontal` \| `vertical` | Segment direction |
| `start`, `end` | (x: int, y: int) | Segment endpoints on the canvas |

**Validation rule**: the concatenation of `segments`, in list order,
MUST form a continuous path (the end of one segment coincides with the start of the
next) from the exit point of the source table to the `arrowPoint` on the
target table, with no intermediate point inside a `TableObstacle` that
is not the source or target.

## Relation to existing entities

- `TableDef`, `ColumnDef`, `ForeignKeyDef` (`schema_model.dart`): are not
  changed; they remain the schema source of truth.
- `GraphRelationEdge`, `GraphLayoutResult` (`graph_model.dart`): continue
  representing, respectively, a relation to draw and the result of
  distribution into rows/columns; `GraphLayoutResult` may, if needed,
  gain spacing (`colGap`/`rowGap`) adjusted by Decision 4 as an additional
  field, without removing any existing field.
- `_TableNodeLayout` (internal to `table_component.dart`): continues
  representing each table's final position on the canvas; it is the source of
  `TableObstacle`s consumed by the new routing module.

## Special cases covered by the model

- **Self-relationship** (source = target): represented as a
  `RoutedEdge` whose first and last segment exit/enter the same table,
  on different sides, without any other table's `TableObstacle`
  necessarily involved — but still validated against all other
  tables, in case the loop needs to go around nearby neighbors.
- **Multiple FKs between the same pair of tables**: each FK yields a
  `GraphRelationEdge` and therefore an independent `RoutedEdge`; if the
  computed paths coincide in the same corridor, lane allocation
  (Decision 3) guarantees distinct offsets.
