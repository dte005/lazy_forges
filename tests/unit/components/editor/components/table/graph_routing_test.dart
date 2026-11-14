// Testes unitários do motor de roteamento de linhas do grafo
// (`GraphRoutingEngine`), introduzido para corrigir a issue #2 (linhas de
// relacionamento cruzando tabelas). Cobre o cálculo de posições, o
// contorno de obstáculos (bypass) e a alocação de pistas paralelas.
import 'package:lazy_forge/src/components/editor/components/table/graph_routing.dart';
import 'package:lazy_forge/src/components/editor/models/graph_model.dart';
import 'package:lazy_forge/src/components/editor/models/schema_model.dart';
import 'package:test/test.dart';

TableDef _table(String name, {List<String> columns = const <String>[]}) {
  return TableDef(
    name: name,
    columns: columns
        .map((c) => ColumnDef(name: c, type: 'text'))
        .toList(growable: true),
  );
}

GraphRelationEdge _edge(String sourceTable, String targetTable) {
  return GraphRelationEdge(
    sourceTable: sourceTable,
    sourceColumn: 'ref_id',
    targetTable: targetTable,
    targetColumn: 'id',
  );
}

/// Verdadeiro se o segmento [seg] (horizontal ou vertical) atravessa o
/// interior do retângulo de [obstacle]. Toca a borda não conta como
/// atravessar (as linhas nascem/terminam encostadas nas bordas das tabelas
/// vizinhas por design).
bool _segmentCrossesObstacle(RoutedSegment seg, TableObstacle obstacle) {
  if (seg.orientation == RouteOrientation.horizontal) {
    final y = seg.y1;
    if (y <= obstacle.y || y >= obstacle.bottom) return false;
    final minX = seg.x1 < seg.x2 ? seg.x1 : seg.x2;
    final maxX = seg.x1 < seg.x2 ? seg.x2 : seg.x1;
    return maxX > obstacle.x && minX < obstacle.right;
  } else {
    final x = seg.x1;
    if (x <= obstacle.x || x >= obstacle.right) return false;
    final minY = seg.y1 < seg.y2 ? seg.y1 : seg.y2;
    final maxY = seg.y1 < seg.y2 ? seg.y2 : seg.y1;
    return maxY > obstacle.y && minY < obstacle.bottom;
  }
}

void main() {
  const engine = GraphRoutingEngine();
  const size = (width: 10, height: 5);

  group('GraphRoutingEngine.plan — casos base', () {
    test('layout vazio produz plano vazio', () {
      final plan = engine.plan(
        layout: const GraphLayoutResult(rows: [], maxColumns: 1, edges: []),
        tableSizes: const <String, ({int width, int height})>{},
      );

      expect(plan.tablePositions, isEmpty);
      expect(plan.routedEdges, isEmpty);
    });

    test('posiciona cada tabela com o tamanho informado em tableSizes', () {
      final a = _table('a');
      final b = _table('b');
      final plan = engine.plan(
        layout: GraphLayoutResult(
          rows: [
            [a, b],
          ],
          maxColumns: 2,
          edges: const [],
        ),
        tableSizes: {'a': size, 'b': size},
      );

      expect(plan.tablePositions['a']!.width, size.width);
      expect(plan.tablePositions['b']!.height, size.height);
      // 'b' fica à direita de 'a' (mesma linha, ordem alfabética do layout).
      expect(
        plan.tablePositions['b']!.x,
        greaterThan(plan.tablePositions['a']!.right),
      );
    });
  });

  group('GraphRoutingEngine.plan — auto-relacionamento (self loop)', () {
    test(
      'gera 3 segmentos (sobe, atravessa, desce) e seta aponta para baixo',
      () {
        final t = _table('t', columns: ['id', 'parent_id']);
        final plan = engine.plan(
          layout: GraphLayoutResult(
            rows: [
              [t],
            ],
            maxColumns: 2,
            edges: [_edge('t', 't')],
          ),
          tableSizes: {'t': size},
        );

        final routed = plan.routedEdges.single;
        expect(routed.segments, hasLength(3));
        expect(routed.arrowPoint.direction, ArrowDirection.down);
      },
    );
  });

  group(
    'GraphRoutingEngine.plan — regressão da issue #2 (não cruzar tabelas)',
    () {
      test(
        'FK entre colunas não-adjacentes da mesma linha contorna pela margem, '
        'sem atravessar a tabela do meio',
        () {
          final a = _table('a');
          final b = _table('b');
          final c = _table('c');
          final plan = engine.plan(
            layout: GraphLayoutResult(
              rows: [
                [a, b, c],
              ],
              maxColumns: 3,
              edges: [_edge('a', 'c')],
            ),
            tableSizes: {'a': size, 'b': size, 'c': size},
          );

          final middle = plan.tablePositions['b']!;
          final routed = plan.routedEdges.single;
          for (final seg in routed.segments) {
            expect(
              _segmentCrossesObstacle(seg, middle),
              isFalse,
              reason:
                  'segmento ${seg.x1},${seg.y1} -> ${seg.x2},${seg.y2} '
                  'não deveria atravessar a tabela do meio',
            );
          }
        },
      );

      test(
        'FK entre linhas não-adjacentes contorna pela margem, sem atravessar '
        'a linha intermediária',
        () {
          final top = _table('top');
          final middleRow = _table('middle');
          final bottom = _table('bottom');
          final plan = engine.plan(
            layout: GraphLayoutResult(
              rows: [
                [top],
                [middleRow],
                [bottom],
              ],
              maxColumns: 1,
              edges: [_edge('bottom', 'top')],
            ),
            tableSizes: {'top': size, 'middle': size, 'bottom': size},
          );

          final obstacle = plan.tablePositions['middle']!;
          final routed = plan.routedEdges.single;
          for (final seg in routed.segments) {
            expect(_segmentCrossesObstacle(seg, obstacle), isFalse);
          }
        },
      );

      test('nenhum segmento roteado atravessa uma tabela que não é origem nem '
          'destino, num grafo com múltiplas tabelas e relações', () {
        final a = _table('a');
        final b = _table('b');
        final c = _table('c');
        final d = _table('d');
        final plan = engine.plan(
          layout: GraphLayoutResult(
            rows: [
              [a, b, c, d],
            ],
            maxColumns: 4,
            edges: [_edge('a', 'd'), _edge('a', 'c'), _edge('b', 'd')],
          ),
          tableSizes: {'a': size, 'b': size, 'c': size, 'd': size},
        );

        for (final routed in plan.routedEdges) {
          final sourceKey = routed.edge.sourceTable.toLowerCase();
          final targetKey = routed.edge.targetTable.toLowerCase();
          for (final entry in plan.tablePositions.entries) {
            if (entry.key == sourceKey || entry.key == targetKey) continue;
            for (final seg in routed.segments) {
              expect(
                _segmentCrossesObstacle(seg, entry.value),
                isFalse,
                reason:
                    'relação ${routed.edge.sourceTable}->${routed.edge.targetTable} '
                    'não deveria atravessar "${entry.key}"',
              );
            }
          }
        }
      });
    },
  );

  group('GraphRoutingEngine.plan — pistas paralelas (lanes)', () {
    test('duas FKs saindo da mesma coluna/linha expandem o espaçamento para '
        'não sobrepor as linhas', () {
      final a = _table('a');
      final b = _table('b');
      final planSingle = engine.plan(
        layout: GraphLayoutResult(
          rows: [
            [a, b],
          ],
          maxColumns: 2,
          edges: [_edge('a', 'b')],
        ),
        tableSizes: {'a': size, 'b': size},
        baseColGap: 2,
      );
      final planDouble = engine.plan(
        layout: GraphLayoutResult(
          rows: [
            [a, b],
          ],
          maxColumns: 2,
          edges: [_edge('a', 'b'), _edge('b', 'a')],
        ),
        tableSizes: {'a': size, 'b': size},
        baseColGap: 2,
      );

      final gapSingle =
          planSingle.tablePositions['b']!.x -
          planSingle.tablePositions['a']!.right;
      final gapDouble =
          planDouble.tablePositions['b']!.x -
          planDouble.tablePositions['a']!.right;

      expect(gapDouble, greaterThan(gapSingle));
    });
  });

  group('GraphRoutingEngine.plan — tabela referenciada ausente do layout', () {
    test('ignora edge cuja tabela de origem ou destino não está no layout', () {
      final a = _table('a');
      final plan = engine.plan(
        layout: GraphLayoutResult(
          rows: [
            [a],
          ],
          maxColumns: 1,
          edges: [_edge('a', 'ghost')],
        ),
        tableSizes: {'a': size},
      );

      expect(plan.routedEdges, isEmpty);
    });
  });
}
