/// Roteamento do grafo de relacionamentos: calcula as posições finais das
/// tabelas (com espaçamento ajustado quando necessário) e o caminho de cada
/// linha de relacionamento, consciente de obstáculos (outras tabelas) e de
/// pistas paralelas para relações que compartilham o mesmo corredor.
///
/// Módulo puro (sem dependência do `nocterm`): recebe o resultado do
/// [GraphLayoutEngine] e devolve um [GraphRoutingPlan] pronto para ser
/// desenhado por `table_component.dart`.
library;

import '../../models/graph_model.dart';
import '../../models/schema_model.dart';

/// Retângulo ocupado por uma tabela já posicionada no canvas de texto do
/// grafo; é o obstáculo que as linhas de relacionamento não podem atravessar.
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

/// Orientação de um trecho de linha ou de um corredor de roteamento.
enum RouteOrientation { horizontal, vertical }

/// Direção da seta final de um relacionamento roteado.
enum ArrowDirection { up, down, left, right }

/// Associa uma relação (`edgeIndex`) a uma posição (offset) dentro de um
/// [RoutingCorridor].
class RoutingLaneAssignment {
  const RoutingLaneAssignment({required this.edgeIndex, required this.offset});

  final int edgeIndex;
  final int offset;
}

/// Pista/corredor de roteamento: espaço (um `colGap` ou `rowGap`, ou a
/// margem lateral do canvas) onde uma ou mais relações podem precisar de
/// posições distintas para não se sobrepor visualmente.
class RoutingCorridor {
  RoutingCorridor({required this.id, required this.orientation})
    : allocatedLanes = <RoutingLaneAssignment>[];

  final String id;
  final RouteOrientation orientation;
  final List<RoutingLaneAssignment> allocatedLanes;

  int get laneCount => allocatedLanes.length;

  /// Devolve o offset já atribuído a [edgeIndex] neste corredor, alocando um
  /// novo (sequencial, em ordem de chegada) se ainda não existir.
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

/// Trecho horizontal ou vertical de uma linha de relacionamento já roteada.
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

/// Ponto onde a seta de um relacionamento é desenhada, com a direção para a
/// qual ela aponta.
class ArrowPoint {
  const ArrowPoint({required this.x, required this.y, required this.direction});

  final int x;
  final int y;
  final ArrowDirection direction;
}

/// Resultado do roteamento de uma [GraphRelationEdge]: o caminho completo
/// (segments) e o ponto/direção da seta, prontos para desenho.
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

/// Resultado completo do roteamento: posição final de cada tabela (depois de
/// qualquer expansão de corredor necessária) e o caminho roteado de cada
/// relacionamento, na mesma ordem de `layout.edges`.
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

/// Calcula o roteamento final do grafo: posições das tabelas (com
/// espaçamento expandido quando necessário) e o caminho de cada relação,
/// sem cruzar tabelas e com pistas distintas para relações que dividem o
/// mesmo corredor. Ver `research.md` (Decisões 1-5) e `data-model.md`.
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

    // 1) Classificar cada relação (topologia pura: linha/coluna relativas).
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
        // Tabela referenciada não encontrada no layout atual; ignora.
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

    // 2) Registrar corredores que afetam o espaçamento (colGap/rowGap) e
    //    alocar pistas em ordem de edgeIndex (determinístico).
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
          // Pistas de contorno (margem) são resolvidas depois, já com as
          // posições finais das tabelas (não afetam colGap/rowGap).
          break;
      }
    }

    // 3) Espaçamento necessário por corredor: cresce apenas o suficiente
    //    para comportar todas as pistas alocadas, nunca aceitando cruzamento
    //    residual (Clarification 1 / FR-001), mas sem inflar corredores que
    //    não precisam (Princípio VII — Simplicidade Deliberada).
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

    // Laços de auto-relacionamento em tabelas que não estão na primeira
    // linha sobem pelo corredor de linha logo acima; garante espaço
    // suficiente para a maior altura de laço necessária naquele corredor.
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
      // Evita que o laço "vaze" para fora do corredor calculado.
      corridor.allocateLane(i);
    }

    // 4) Posições finais das tabelas, usando os espaçamentos (possivelmente
    //    expandidos) calculados acima. Mesma fórmula de hoje quando nenhum
    //    corredor precisou crescer (preserva FR-006 — sem regressão).
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

    // 5) Roteamento final de cada relação, usando as posições definitivas.
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
          // Nunca sai lateralmente na altura da própria linha: quando a
          // tabela de origem (ou destino) não está na borda da sua linha,
          // um segmento lateral direto atravessaria qualquer tabela vizinha
          // no caminho (viola FR-001). Em vez disso, escapa sempre por cima
          // da tabela — a faixa imediatamente acima de qualquer linha
          // (inclusive a margem superior, para a linha 0) nunca contém
          // tabelas — depois contorna pela margem externa (fora de todas as
          // colunas) e desce de volta por cima da tabela de destino.
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
