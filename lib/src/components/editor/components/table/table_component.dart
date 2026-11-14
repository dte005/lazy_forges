import 'package:nocterm/nocterm.dart';

import '../../models/graph_model.dart';
import '../../models/schema_model.dart';
import './graph_layout.dart';
import './graph_routing.dart';

class TableGraphLayoutComponent extends StatelessComponent {
  const TableGraphLayoutComponent({super.key, required this.schemaState});

  final SchemaState schemaState;

  static const List<Color> _relationPalette = <Color>[
    Colors.cyan,
    Colors.yellow,
    Colors.green,
    Colors.magenta,
    Colors.blue,
    Colors.red,
    Colors.brightCyan,
    Colors.brightYellow,
    Colors.brightGreen,
    Colors.brightMagenta,
    Colors.brightBlue,
    Colors.brightRed,
  ];

  @override
  Component build(BuildContext context) {
    final GraphLayoutResult layout = const GraphLayoutEngine().build(
      schemaState.tables,
      maxColumns: 3,
    );

    if (layout.rows.isEmpty) {
      return const Text('Nenhuma tabela no schema.');
    }
    final tableSpecs = <String, ({int width, int height, int innerWidth})>{};
    for (final table in schemaState.tables) {
      final specs = _measureTable(table);
      tableSpecs[table.name.toLowerCase()] = specs;
    }

    final edgeColorByIndex = <int, Color>{};
    final columnColorByKey = <String, Color>{};
    for (var i = 0; i < layout.edges.length; i++) {
      final edge = layout.edges[i];
      final color = _relationPalette[i % _relationPalette.length];
      edgeColorByIndex[i] = color;

      final sourceKey = _columnKey(edge.sourceTable, edge.sourceColumn);
      final targetKey = _columnKey(edge.targetTable, edge.targetColumn);
      columnColorByKey.putIfAbsent(sourceKey, () => color);
      columnColorByKey.putIfAbsent(targetKey, () => color);
    }

    const marginX = 2;
    const marginY = 1;

    final tableSizes = <String, ({int width, int height})>{};
    for (final entry in tableSpecs.entries) {
      tableSizes[entry.key] = (
        width: entry.value.width,
        height: entry.value.height,
      );
    }

    final routingPlan = const GraphRoutingEngine().plan(
      layout: layout,
      tableSizes: tableSizes,
      marginX: marginX,
      marginY: marginY,
    );
    final nodesByName = routingPlan.tablePositions;

    var minX = 0;
    var minY = 0;
    var maxX = 0;
    var maxY = 0;
    for (final node in nodesByName.values) {
      if (node.x < minX) minX = node.x;
      if (node.y < minY) minY = node.y;
      if (node.right > maxX) maxX = node.right;
      if (node.bottom > maxY) maxY = node.bottom;
    }

    for (final routed in routingPlan.routedEdges) {
      for (final segment in routed.segments) {
        if (segment.x1 < minX) minX = segment.x1;
        if (segment.x2 < minX) minX = segment.x2;
        if (segment.y1 < minY) minY = segment.y1;
        if (segment.y2 < minY) minY = segment.y2;
        if (segment.x1 > maxX) maxX = segment.x1;
        if (segment.x2 > maxX) maxX = segment.x2;
        if (segment.y1 > maxY) maxY = segment.y1;
        if (segment.y2 > maxY) maxY = segment.y2;
      }
    }

    final offsetX = (minX < 0) ? (-minX + 1) : 0;
    final offsetY = (minY < 0) ? (-minY + 1) : 0;
    final canvasWidth = (maxX + offsetX + marginX + 2);
    final canvasHeight = (maxY + offsetY + marginY + 1);
    final canvas = List.generate(
      canvasHeight,
      (_) => List.filled(canvasWidth, ' '),
    );
    final colorCanvas = List.generate(
      canvasHeight,
      (_) => List<Color?>.filled(canvasWidth, null),
    );

    void drawAt(int x, int y, String char, {Color? color}) {
      final cx = x + offsetX;
      final cy = y + offsetY;
      if (cy < 0 || cy >= canvas.length) return;
      if (cx < 0 || cx >= canvas[cy].length) return;

      final current = canvas[cy][cx];
      if (current == char) {
        if (color != null) {
          colorCanvas[cy][cx] = color;
        }
        return;
      }

      if (current == ' ' ||
          char == '>' ||
          char == '<' ||
          char == '^' ||
          char == 'v') {
        canvas[cy][cx] = char;
        if (color != null) {
          colorCanvas[cy][cx] = color;
        }
        return;
      }

      if ((current == '-' && char == '|') || (current == '|' && char == '-')) {
        canvas[cy][cx] = '+';
        if (color != null) {
          colorCanvas[cy][cx] = color;
        }
        return;
      }

      if (current == '+') {
        if (color != null && colorCanvas[cy][cx] == null) {
          colorCanvas[cy][cx] = color;
        }
        return;
      }

      if ('+'.contains(current) && '-|+'.contains(char)) {
        if (color != null && colorCanvas[cy][cx] == null) {
          colorCanvas[cy][cx] = color;
        }
        return;
      }

      if ('-|+'.contains(current) && '-|+'.contains(char)) {
        canvas[cy][cx] = '+';
        if (color != null) {
          colorCanvas[cy][cx] = color;
        }
      }
    }

    void drawText(int x, int y, String text, {Color? color}) {
      for (var i = 0; i < text.length; i++) {
        drawAt(x + i, y, text[i], color: color);
      }
    }

    void drawHorizontal(int y, int x1, int x2, {Color? color}) {
      final start = x1 <= x2 ? x1 : x2;
      final end = x1 <= x2 ? x2 : x1;
      for (var x = start; x <= end; x++) {
        drawAt(x, y, '-', color: color);
      }
    }

    void drawVertical(int x, int y1, int y2, {Color? color}) {
      final start = y1 <= y2 ? y1 : y2;
      final end = y1 <= y2 ? y2 : y1;
      for (var y = start; y <= end; y++) {
        drawAt(x, y, '|', color: color);
      }
    }

    String fit(String value, int width) {
      if (value.length <= width) {
        return value.padRight(width);
      }
      if (width <= 3) return value.substring(0, width);
      return '${value.substring(0, width - 3)}...';
    }

    final tableByKey = <String, TableDef>{};
    for (final table in schemaState.tables) {
      tableByKey[table.name.toLowerCase()] = table;
    }

    for (final entry in nodesByName.entries) {
      final node = entry.value;
      final table = tableByKey[entry.key]!;
      final innerWidth = node.width - 2;
      final boxTop = node.y;
      final boxBottom = node.y + node.height - 1;

      drawAt(node.x, boxTop, '+');
      drawAt(node.x + node.width - 1, boxTop, '+');
      drawAt(node.x, boxBottom, '+');
      drawAt(node.x + node.width - 1, boxBottom, '+');

      for (var x = node.x + 1; x < node.x + node.width - 1; x++) {
        drawAt(x, boxTop, '-');
        drawAt(x, boxBottom, '-');
      }
      for (var y = boxTop + 1; y < boxBottom; y++) {
        drawAt(node.x, y, '|');
        drawAt(node.x + node.width - 1, y, '|');
      }

      final title = fit(table.name, innerWidth);
      drawText(node.x + 1, node.y + 1, title);

      final sepY = node.y + 2;
      drawAt(node.x, sepY, '+');
      drawAt(node.x + node.width - 1, sepY, '+');
      for (var x = node.x + 1; x < node.x + node.width - 1; x++) {
        drawAt(x, sepY, '-');
      }

      final foreignKeysByColumn = <String, List<ForeignKeyDef>>{};
      for (final fk in table.foreignKeys) {
        foreignKeysByColumn.putIfAbsent(fk.columnName.toLowerCase(), () => []);
        foreignKeysByColumn[fk.columnName.toLowerCase()]!.add(fk);
      }

      if (table.columns.isEmpty) {
        drawText(node.x + 1, node.y + 3, fit('(sem colunas)', innerWidth));
      } else {
        for (var index = 0; index < table.columns.length; index++) {
          final column = table.columns[index];
          final tags = <String>[];
          if (column.isPrimaryKey) tags.add('PK');
          if ((foreignKeysByColumn[column.name.toLowerCase()] ??
                  const <ForeignKeyDef>[])
              .isNotEmpty) {
            tags.add('FK');
          }
          final label = _buildColumnLabel(column, tags);
          final lineY = node.y + 3 + index;
          final relationColor =
              columnColorByKey[_columnKey(table.name, column.name)];
          drawText(
            node.x + 1,
            lineY,
            fit(label, innerWidth),
            color: relationColor,
          );
        }
      }
    }

    for (final routed in routingPlan.routedEdges) {
      final edgeColor = edgeColorByIndex[routed.edgeIndex];
      for (final segment in routed.segments) {
        if (segment.orientation == RouteOrientation.horizontal) {
          drawHorizontal(segment.y1, segment.x1, segment.x2, color: edgeColor);
        } else {
          drawVertical(segment.x1, segment.y1, segment.y2, color: edgeColor);
        }
      }
      for (var s = 0; s < routed.segments.length - 1; s++) {
        final joint = routed.segments[s];
        drawAt(joint.x2, joint.y2, '+', color: edgeColor);
      }
      final arrow = routed.arrowPoint;
      final arrowChar = switch (arrow.direction) {
        ArrowDirection.up => '^',
        ArrowDirection.down => 'v',
        ArrowDirection.left => '<',
        ArrowDirection.right => '>',
      };
      drawAt(arrow.x, arrow.y, arrowChar, color: edgeColor);
    }

    final lines = <Component>[];
    for (var rowIndex = 0; rowIndex < canvas.length; rowIndex++) {
      lines.add(_buildCanvasLine(canvas[rowIndex], colorCanvas[rowIndex]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines,
    );
  }

  Component _buildCanvasLine(List<String> row, List<Color?> colors) {
    var lastNonSpace = -1;
    for (var i = row.length - 1; i >= 0; i--) {
      if (row[i] != ' ') {
        lastNonSpace = i;
        break;
      }
    }

    if (lastNonSpace == -1) {
      return const Text(' ');
    }

    final segments = <Component>[];
    var start = 0;
    while (start <= lastNonSpace) {
      final color = colors[start];
      var end = start;
      while (end + 1 <= lastNonSpace && colors[end + 1] == color) {
        end += 1;
      }

      final text = row.sublist(start, end + 1).join();
      if (color == null) {
        segments.add(Text(text));
      } else {
        segments.add(Text(text, style: TextStyle(color: color)));
      }
      start = end + 1;
    }

    if (segments.length == 1) {
      return segments.first;
    }
    return Row(children: segments);
  }

  ({int width, int height, int innerWidth}) _measureTable(TableDef table) {
    var contentWidth = table.name.length;
    if (table.columns.isEmpty) {
      contentWidth = _max(contentWidth, '(sem colunas)'.length);
    } else {
      final foreignKeysByColumn = <String, List<ForeignKeyDef>>{};
      for (final fk in table.foreignKeys) {
        foreignKeysByColumn.putIfAbsent(fk.columnName.toLowerCase(), () => []);
        foreignKeysByColumn[fk.columnName.toLowerCase()]!.add(fk);
      }

      for (final column in table.columns) {
        final tags = <String>[];
        if (column.isPrimaryKey) tags.add('PK');
        if ((foreignKeysByColumn[column.name.toLowerCase()] ??
                const <ForeignKeyDef>[])
            .isNotEmpty) {
          tags.add('FK');
        }
        final label = _buildColumnLabel(column, tags);
        contentWidth = _max(contentWidth, label.length);
      }
    }

    final innerWidth = _max(16, _min(42, contentWidth + 2));
    final height = 4 + _max(1, table.columns.length);
    return (width: innerWidth + 2, height: height, innerWidth: innerWidth);
  }

  int _max(int left, int right) => left > right ? left : right;
  int _min(int left, int right) => left < right ? left : right;

  String _columnKey(String tableName, String columnName) {
    return '${tableName.toLowerCase()}::${columnName.toLowerCase()}';
  }

  String _buildColumnLabel(ColumnDef column, List<String> tags) {
    final enumText = column.enumOptions.isEmpty
        ? ''
        : ' {${column.enumOptions.join('|')}}';
    final suffix = tags.isEmpty ? '' : ' [${tags.join('|')}]';
    final descriptionText =
        (column.description == null || column.description!.isEmpty)
        ? ''
        : ' -- ${column.description}';
    return '${column.name}: ${column.type}$enumText$suffix$descriptionText';
  }
}
