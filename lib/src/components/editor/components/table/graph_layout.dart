import '../../models/graph_model.dart';
import '../../models/schema_model.dart';

class GraphLayoutEngine {
  const GraphLayoutEngine();

  GraphLayoutResult build(List<TableDef> tables, {int maxColumns = 3}) {
    if (tables.isEmpty) {
      return const GraphLayoutResult(rows: [], maxColumns: 1, edges: []);
    }

    final normalizedMaxColumns = maxColumns < 2 ? 2 : maxColumns;
    final tableByName = <String, TableDef>{};
    for (final table in tables) {
      tableByName[table.name.toLowerCase()] = table;
    }

    final edges = <GraphRelationEdge>[];
    final dependenciesByTable = <String, Set<String>>{};
    for (final table in tables) {
      final key = table.name.toLowerCase();
      dependenciesByTable.putIfAbsent(key, () => <String>{});
      for (final fk in table.foreignKeys) {
        final dependency = fk.referenceTableName.toLowerCase();
        if (tableByName.containsKey(dependency)) {
          dependenciesByTable[key]!.add(dependency);
          edges.add(
            GraphRelationEdge(
              sourceTable: table.name,
              sourceColumn: fk.columnName,
              targetTable: fk.referenceTableName,
              targetColumn: fk.referenceColumnName,
            ),
          );
        }
      }
    }

    final levelByTable = <String, int>{};
    int resolveLevel(String tableName, Set<String> stack) {
      if (levelByTable.containsKey(tableName)) return levelByTable[tableName]!;
      if (stack.contains(tableName)) return 0;

      stack.add(tableName);
      final dependencies = dependenciesByTable[tableName] ?? <String>{};
      var level = 0;
      for (final dependency in dependencies) {
        level = _max(level, resolveLevel(dependency, stack) + 1);
      }
      stack.remove(tableName);
      levelByTable[tableName] = level;
      return level;
    }

    final allNames = tableByName.keys.toList()..sort();
    for (final tableName in allNames) {
      resolveLevel(tableName, <String>{});
    }

    final groupedByLevel = <int, List<TableDef>>{};
    for (final entry in tableByName.entries) {
      final level = levelByTable[entry.key] ?? 0;
      groupedByLevel.putIfAbsent(level, () => <TableDef>[]);
      groupedByLevel[level]!.add(entry.value);
    }

    final orderedLevels = groupedByLevel.keys.toList()..sort();
    final rows = <List<TableDef>>[];
    for (final level in orderedLevels) {
      final levelTables = groupedByLevel[level]!
        ..sort((a, b) => a.name.compareTo(b.name));

      for (
        var index = 0;
        index < levelTables.length;
        index += normalizedMaxColumns
      ) {
        final end = _min(index + normalizedMaxColumns, levelTables.length);
        rows.add(levelTables.sublist(index, end));
      }
    }

    return GraphLayoutResult(
      rows: rows,
      maxColumns: normalizedMaxColumns,
      edges: edges,
    );
  }

  int _max(int left, int right) => left > right ? left : right;
  int _min(int left, int right) => left < right ? left : right;
}
