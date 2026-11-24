/// Relationship graph routing: computes final table positions
/// (with spacing expanded when needed) and the path of each
/// relationship line, aware of obstacles (other tables) and of
/// parallel lanes for relations that share the same corridor.
///
/// Pure module (no `nocterm` dependency): takes the output of
/// [GraphLayoutEngine] and returns a [GraphRoutingPlan] ready to be
/// drawn by `table_component.dart`.
library;

import '../../models/graph_model.dart';
import '../../models/schema_model.dart';

/// Rectangle occupied by a table already placed on the text canvas of the
/// graph; obstacles that relationship lines must not cross.
class TableObstacle {
  const TableObstacle({
    required this.tableKey,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final String tableKey;
  final int x;
  final int y;
  final int width;
  final int height;

  int get right => x + width;
  int get bottom => y + height;
  int get centerX => x + (width ~/ 2);
  int get centerY => y + (height ~/ 2);
}

/// Orientation of a line segment or routing corridor.
enum RouteOrientation { horizontal, vertical }

/// Direction of the final arrow of a routed relationship.
enum ArrowDirection { up, down, left, right }

/// Associates a relation (`edgeIndex`) with a position (offset) inside a
/// [RoutingCorridor].
class RoutingLaneAssignment {
  const RoutingLaneAssignment({required this.edgeIndex, required this.offset});

  final int edgeIndex;
  final int offset;
}

/// Routing lane/corridor: space (a `colGap` or `rowGap`, or the
/// canvas side margin) where one or more relations may need
/// distinct positions so they do not visually overlap.
class RoutingCorridor {
  RoutingCorridor({required this.id, required this.orientation})
    : allocatedLanes = <RoutingLaneAssignment>[];

  final String id;
  final RouteOrientation orientation;
  final List<RoutingLaneAssignment> allocatedLanes;

  int get laneCount => allocatedLanes.length;

  /// Returns the offset already assigned to [edgeIndex] in this corridor, allocating a
  /// new one (sequential, arrival order) if none exists yet.
  int allocateLane(int edgeIndex) {
    for (final lane in allocatedLanes) {
      if (lane.edgeIndex == edgeIndex) return lane.offset;
    }
    final offset = allocatedLanes.length;
    allocatedLanes.add(
      RoutingLaneAssignment(edgeIndex: edgeIndex, offset: offset),
    );
    return offset;
  }
}

/// Horizontal or vertical segment of an already routed relationship line.
class RoutedSegment {
  const RoutedSegment({
    required this.orientation,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  final RouteOrientation orientation;
  final int x1;
  final int y1;
  final int x2;
  final int y2;
}

/// Point where a relationship arrow is drawn, with the direction it
/// points to.
class ArrowPoint {
  const ArrowPoint({required this.x, required this.y, required this.direction});

  final int x;
  final int y;
  final ArrowDirection direction;
}

/// Routing result for a [GraphRelationEdge]: the full path
/// (segments) and arrow point/direction, ready to draw.
class RoutedEdge {
  const RoutedEdge({
    required this.edge,
    required this.edgeIndex,
    required this.segments,
    required this.arrowPoint,
  });

  final GraphRelationEdge edge;
  final int edgeIndex;
  final List<RoutedSegment> segments;
  final ArrowPoint arrowPoint;
}

/// Full routing result: final position of each table (after any
/// required corridor expansion) and the routed path of each
/// relationship, in the same order as `layout.edges`.
class GraphRoutingPlan {
  const GraphRoutingPlan({
    required this.tablePositions,
    required this.routedEdges,
  });

  final Map<String, TableObstacle> tablePositions;
  final List<RoutedEdge> routedEdges;
}

enum _EdgeKind {
  selfLoop,
  sameRowAdjacent,
  sameRowBypass,
  rowAdjacentCross,
  rowSkipBypass,
}

class _EdgeClassification {
  _EdgeClassification({
    required this.kind,
    this.gapIndex,
    this.boundary,
    this.sourceToRight,
    this.targetBelow,
  });

  final _EdgeKind kind;
  final int? gapIndex;
  final int? boundary;
  final bool? sourceToRight;
  final bool? targetBelow;
}

/// Computes final graph routing: table positions (with
/// spacing expanded when needed) and the path of each relation,
/// without crossing tables and with distinct lanes for relations that share
/// the same corridor. See `research.md` (Decisions 1-5) and `data-model.md`.
class GraphRoutingEngine {
  const GraphRoutingEngine();

  GraphRoutingPlan plan({
    required GraphLayoutResult layout,
    required Map<String, ({int width, int height})> tableSizes,
    int baseColGap = 8,
    int baseRowGap = 3,
    int marginX = 2,
    int marginY = 1,
  }) {
    if (layout.rows.isEmpty) {
      return const GraphRoutingPlan(tablePositions: {}, routedEdges: []);
    }

    final tableDefByKey = <String, TableDef>{};
    final rowIndexOf = <String, int>{};
    final colIndexInRowOf = <String, int>{};
    for (var r = 0; r < layout.rows.length; r++) {
      final row = layout.rows[r];
      for (var i = 0; i < row.length; i++) {
        final key = row[i].name.toLowerCase();
        tableDefByKey[key] = row[i];
        rowIndexOf[key] = r;
        colIndexInRowOf[key] = i;
      }
    }

    // 1) Classify each relation (pure topology: relative row/column).
    final classifications = <_EdgeClassification>[];
    for (final edge in layout.edges) {
      final sourceKey = edge.sourceTable.toLowerCase();
      final targetKey = edge.targetTable.toLowerCase();
      if (sourceKey == targetKey) {
        classifications.add(_EdgeClassification(kind: _EdgeKind.selfLoop));
        continue;
      }

      final sR = rowIndexOf[sourceKey];
      final tR = rowIndexOf[targetKey];
      if (sR == null || tR == null) {
        // Referenced table not found in the current layout; skip.
        classifications.add(_EdgeClassification(kind: _EdgeKind.sameRowBypass));
        continue;
      }

      if (sR == tR) {
        final sC = colIndexInRowOf[sourceKey]!;
        final tC = colIndexInRowOf[targetKey]!;
        if ((sC - tC).abs() == 1) {
          classifications.add(
            _EdgeClassification(
              kind: _EdgeKind.sameRowAdjacent,
              gapIndex: sC < tC ? sC : tC,
              sourceToRight: tC > sC,
            ),
          );
        } else {
          classifications.add(
            _EdgeClassification(kind: _EdgeKind.sameRowBypass),
          );
        }
      } else {
        if ((sR - tR).abs() == 1) {
          classifications.add(
            _EdgeClassification(
              kind: _EdgeKind.rowAdjacentCross,
              boundary: sR < tR ? sR : tR,
              targetBelow: tR > sR,
            ),
          );
        } else {
          classifications.add(
            _EdgeClassification(kind: _EdgeKind.rowSkipBypass),
          );
        }
      }
    }

    // 2) Register corridors that affect spacing (colGap/rowGap) and
    //    allocate lanes in edgeIndex order (deterministic).
    final corridors = <String, RoutingCorridor>{};
    RoutingCorridor corridorFor(String id, RouteOrientation orientation) {
      return corridors.putIfAbsent(
        id,
        () => RoutingCorridor(id: id, orientation: orientation),
      );
    }

    final laneOffsetByEdgeIndex = <int, int>{};
    for (var i = 0; i < classifications.length; i++) {
      final c = classifications[i];
      switch (c.kind) {
        case _EdgeKind.sameRowAdjacent:
          final corridor = corridorFor(
            'row:${rowIndexOf[layout.edges[i].sourceTable.toLowerCase()]}:gap:${c.gapIndex}',
            RouteOrientation.vertical,
          );
          laneOffsetByEdgeIndex[i] = corridor.allocateLane(i);
          break;
        case _EdgeKind.rowAdjacentCross:
          final corridor = corridorFor(
            'rb:${c.boundary}',
            RouteOrientation.horizontal,
          );
          laneOffsetByEdgeIndex[i] = corridor.allocateLane(i);
          break;
        case _EdgeKind.selfLoop:
          final key = layout.edges[i].sourceTable.toLowerCase();
          final corridor = corridorFor('self:$key', RouteOrientation.vertical);
          laneOffsetByEdgeIndex[i] = corridor.allocateLane(i);
          break;
        case _EdgeKind.sameRowBypass:
        case _EdgeKind.rowSkipBypass:
          // Contour (margin) lanes are resolved later, once final table
          // positions are known (they do not affect colGap/rowGap).
          break;
      }
    }

    // 3) Required spacing per corridor: grow just enough
    //    to fit all allocated lanes, never accepting residual crossings
    //    (Clarification 1 / FR-001), without inflating corridors that
    //    do not need it (Principle VII — Deliberate Simplicity).
    int requiredSpanFor(int laneCount, int base) {
      if (laneCount <= 1) return base;
      final needed = 2 * (laneCount - 1) + 1;
      return needed > base ? needed : base;
    }

    final colGapByRow = <List<int>>[];
    for (var r = 0; r < layout.rows.length; r++) {
      final row = layout.rows[r];
      final gaps = List<int>.filled(
        row.length > 1 ? row.length - 1 : 0,
        baseColGap,
      );
      for (var i = 0; i < gaps.length; i++) {
        final corridor = corridors['row:$r:gap:$i'];
        if (corridor != null) {
          gaps[i] = requiredSpanFor(corridor.laneCount, baseColGap);
        }
      }
      colGapByRow.add(gaps);
    }

    final rowGapAfterRow = List<int>.filled(
      layout.rows.length > 1 ? layout.rows.length - 1 : 0,
      baseRowGap,
    );
    for (var b = 0; b < rowGapAfterRow.length; b++) {
      final corridor = corridors['rb:$b'];
      if (corridor != null) {
        rowGapAfterRow[b] = requiredSpanFor(corridor.laneCount, baseRowGap);
      }
    }

    // Self-relationship loops on tables that are not on the first
    // row climb through the row corridor just above; ensure space
    // enough for the largest loop height needed in that corridor.
    for (var i = 0; i < classifications.length; i++) {
      if (classifications[i].kind != _EdgeKind.selfLoop) continue;
      final key = layout.edges[i].sourceTable.toLowerCase();
      final row = rowIndexOf[key];
      if (row == null || row == 0) continue;
      final corridor = corridors['self:$key']!;
      final offset = laneOffsetByEdgeIndex[i]!;
      final neededHeight = 1 + offset + 1;
      if (row - 1 < rowGapAfterRow.length &&
          neededHeight > rowGapAfterRow[row - 1]) {
        rowGapAfterRow[row - 1] = neededHeight;
      }
      // Prevent the loop from spilling outside the computed corridor.
      corridor.allocateLane(i);
    }

    // 4) Final table positions using the spacings (possibly
    //    expanded) computed above. Same formula as today when no
    //    corridor needed to grow (preserves FR-006 — no regression).
    final rowWidths = <int>[];
    final rowHeights = <int>[];
    for (var r = 0; r < layout.rows.length; r++) {
      final row = layout.rows[r];
      var width = 0;
      var rowHeight = 0;
      for (var i = 0; i < row.length; i++) {
        final size = tableSizes[row[i].name.toLowerCase()]!;
        width += size.width;
        if (i > 0) width += colGapByRow[r][i - 1];
        if (size.height > rowHeight) rowHeight = size.height;
      }
      rowWidths.add(width);
      rowHeights.add(rowHeight);
    }

    var maxRowWidth = 0;
    for (final width in rowWidths) {
      if (width > maxRowWidth) maxRowWidth = width;
    }

    final tablePositions = <String, TableObstacle>{};
    var cursorY = marginY;
    for (var r = 0; r < layout.rows.length; r++) {
      final row = layout.rows[r];
      final rowWidth = rowWidths[r];
      var cursorX = marginX + ((maxRowWidth - rowWidth) ~/ 2);

      for (var i = 0; i < row.length; i++) {
        final table = row[i];
        final key = table.name.toLowerCase();
        final size = tableSizes[key]!;
        tablePositions[key] = TableObstacle(
          tableKey: key,
          x: cursorX,
          y: cursorY,
          width: size.width,
          height: size.height,
        );
        cursorX += size.width;
        if (i < row.length - 1) cursorX += colGapByRow[r][i];
      }

      cursorY += rowHeights[r];
      if (r < rowGapAfterRow.length) cursorY += rowGapAfterRow[r];
    }

    // 5) Routing final de each relation, usando the positions definitivas.
    var globalMinX = 0;
    var globalMaxX = 0;
    for (final node in tablePositions.values) {
      if (node.x < globalMinX) globalMinX = node.x;
      if (node.right > globalMaxX) globalMaxX = node.right;
    }

    final marginCorridors = <String, RoutingCorridor>{
      'L': RoutingCorridor(
        id: 'margin:L',
        orientation: RouteOrientation.vertical,
      ),
      'R': RoutingCorridor(
        id: 'margin:R',
        orientation: RouteOrientation.vertical,
      ),
    };

    int columnAnchorY(TableDef table, TableObstacle node, String columnName) {
      final idx = table.columns.indexWhere(
        (c) => c.name.toLowerCase() == columnName.toLowerCase(),
      );
      if (idx < 0) return node.y + 1;
      return node.y + 3 + idx;
    }

    final routedEdges = <RoutedEdge>[];
    for (var i = 0; i < layout.edges.length; i++) {
      final edge = layout.edges[i];
      final sourceKey = edge.sourceTable.toLowerCase();
      final targetKey = edge.targetTable.toLowerCase();
      final source = tablePositions[sourceKey];
      final target = tablePositions[targetKey];
      if (source == null || target == null) continue;
      final sourceTable = tableDefByKey[sourceKey]!;
      final targetTable = tableDefByKey[targetKey]!;
      final classification = classifications[i];

      List<RoutedSegment> segments;
      ArrowPoint arrowPoint;

      switch (classification.kind) {
        case _EdgeKind.selfLoop:
          final offset = laneOffsetByEdgeIndex[i] ?? 0;
          final loopHeight = source.y - (1 + offset);
          final exitX = source.x + 1;
          final enterX = source.x + source.width - 2;
          segments = [
            RoutedSegment(
              orientation: RouteOrientation.vertical,
              x1: exitX,
              y1: source.y,
              x2: exitX,
              y2: loopHeight,
            ),
            RoutedSegment(
              orientation: RouteOrientation.horizontal,
              x1: exitX,
              y1: loopHeight,
              x2: enterX,
              y2: loopHeight,
            ),
            RoutedSegment(
              orientation: RouteOrientation.vertical,
              x1: enterX,
              y1: loopHeight,
              x2: enterX,
              y2: source.y,
            ),
          ];
          arrowPoint = ArrowPoint(
            x: enterX,
            y: source.y,
            direction: ArrowDirection.down,
          );
          break;

        case _EdgeKind.sameRowAdjacent:
          final sourceToRight = classification.sourceToRight!;
          final sourceY = columnAnchorY(sourceTable, source, edge.sourceColumn);
          final targetY = columnAnchorY(targetTable, target, edge.targetColumn);
          final sourceOutX = sourceToRight ? source.right : source.x - 1;
          final targetInX = sourceToRight ? target.x - 1 : target.right;
          final corridor =
              corridors['row:${rowIndexOf[sourceKey]}:gap:${classification.gapIndex}']!;
          final delta = _centeredDelta(
            laneOffsetByEdgeIndex[i] ?? 0,
            corridor.laneCount,
          );
          var midX = ((sourceOutX + targetInX) ~/ 2) + delta;
          if (sourceToRight && midX <= sourceOutX) midX = sourceOutX + 1;
          if (!sourceToRight && midX >= sourceOutX) midX = sourceOutX - 1;
          segments = [
            RoutedSegment(
              orientation: RouteOrientation.horizontal,
              x1: sourceOutX,
              y1: sourceY,
              x2: midX,
              y2: sourceY,
            ),
            RoutedSegment(
              orientation: RouteOrientation.vertical,
              x1: midX,
              y1: sourceY,
              x2: midX,
              y2: targetY,
            ),
            RoutedSegment(
              orientation: RouteOrientation.horizontal,
              x1: midX,
              y1: targetY,
              x2: targetInX,
              y2: targetY,
            ),
          ];
          arrowPoint = ArrowPoint(
            x: targetInX,
            y: targetY,
            direction: sourceToRight
                ? ArrowDirection.right
                : ArrowDirection.left,
          );
          break;

        case _EdgeKind.rowAdjacentCross:
          final targetBelow = classification.targetBelow!;
          final sourceX = source.centerX;
          final targetX = target.centerX;
          final sourceOutY = targetBelow ? source.bottom : source.y - 1;
          final targetInY = targetBelow ? target.y - 1 : target.bottom;
          final corridor = corridors['rb:${classification.boundary}']!;
          final delta = _centeredDelta(
            laneOffsetByEdgeIndex[i] ?? 0,
            corridor.laneCount,
          );
          var bendY = ((sourceOutY + targetInY) ~/ 2) + delta;
          if (targetBelow && bendY <= sourceOutY) bendY = sourceOutY + 1;
          if (!targetBelow && bendY >= sourceOutY) bendY = sourceOutY - 1;
          segments = [
            RoutedSegment(
              orientation: RouteOrientation.vertical,
              x1: sourceX,
              y1: sourceOutY,
              x2: sourceX,
              y2: bendY,
            ),
            RoutedSegment(
              orientation: RouteOrientation.horizontal,
              x1: sourceX,
              y1: bendY,
              x2: targetX,
              y2: bendY,
            ),
            RoutedSegment(
              orientation: RouteOrientation.vertical,
              x1: targetX,
              y1: bendY,
              x2: targetX,
              y2: targetInY,
            ),
          ];
          arrowPoint = ArrowPoint(
            x: targetX,
            y: targetInY,
            direction: targetBelow ? ArrowDirection.down : ArrowDirection.up,
          );
          break;

        case _EdgeKind.sameRowBypass:
        case _EdgeKind.rowSkipBypass:
          // Never exit sideways at the table's own row height: when a
          // source (or target) table is not on the edge of its row,
          // a direct side segment would cross any neighboring table
          // on the path (violates FR-001). Instead always escape above
          // the table — the band immediately above any row
          // (including the top margin, for row 0) never contains
          // tables — then go around the outer margin (outside all
          // columns) and drop back above the target table.
          final sourceX = source.centerX;
          final targetX = target.centerX;
          final sourceExitY = source.y - 1;
          final targetExitY = target.y - 1;
          final useLeft =
              (source.centerX + target.centerX) < (globalMinX + globalMaxX);
          final corridor = marginCorridors[useLeft ? 'L' : 'R']!;
          final offset = corridor.allocateLane(i);
          final marginXPos = useLeft
              ? (globalMinX - 2 - (2 * offset))
              : (globalMaxX + 2 + (2 * offset));
          segments = [
            RoutedSegment(
              orientation: RouteOrientation.vertical,
              x1: sourceX,
              y1: source.y,
              x2: sourceX,
              y2: sourceExitY,
            ),
            RoutedSegment(
              orientation: RouteOrientation.horizontal,
              x1: sourceX,
              y1: sourceExitY,
              x2: marginXPos,
              y2: sourceExitY,
            ),
            RoutedSegment(
              orientation: RouteOrientation.vertical,
              x1: marginXPos,
              y1: sourceExitY,
              x2: marginXPos,
              y2: targetExitY,
            ),
            RoutedSegment(
              orientation: RouteOrientation.horizontal,
              x1: marginXPos,
              y1: targetExitY,
              x2: targetX,
              y2: targetExitY,
            ),
            RoutedSegment(
              orientation: RouteOrientation.vertical,
              x1: targetX,
              y1: targetExitY,
              x2: targetX,
              y2: target.y,
            ),
          ];
          arrowPoint = ArrowPoint(
            x: targetX,
            y: target.y,
            direction: ArrowDirection.down,
          );
          break;
      }

      routedEdges.add(
        RoutedEdge(
          edge: edge,
          edgeIndex: i,
          segments: segments,
          arrowPoint: arrowPoint,
        ),
      );
    }

    return GraphRoutingPlan(
      tablePositions: tablePositions,
      routedEdges: routedEdges,
    );
  }

  int _centeredDelta(int offset, int laneCount) {
    if (laneCount <= 1) return 0;
    return (2 * offset) - (laneCount - 1);
  }
}
