import 'package:lazy_forge/src/components/editor/models/schema_model.dart';

class GraphRelationEdge {
  const GraphRelationEdge({
    required this.sourceTable,
    required this.sourceColumn,
    required this.targetTable,
    required this.targetColumn,
  });

  final String sourceTable;
  final String sourceColumn;
  final String targetTable;
  final String targetColumn;
}

class GraphLayoutResult {
  const GraphLayoutResult({
    required this.rows,
    required this.maxColumns,
    required this.edges,
  });

  final List<List<TableDef>> rows;
  final int maxColumns;
  final List<GraphRelationEdge> edges;
}
