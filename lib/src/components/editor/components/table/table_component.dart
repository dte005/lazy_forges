import 'package:nocterm/nocterm.dart';

import '../../models/schema_model.dart';
import './graph_layout.dart';

class _TableNodeLayout {
  const _TableNodeLayout({
    required this.table,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.columnYByName,
  });

  final TableDef table;
  final int x;
  final int y;
  final int width;
  final int height;
  final Map<String, int> columnYByName;

  int get centerX => x + (width ~/ 2);

  int columnAnchorY(String columnName) {
    return columnYByName[columnName.toLowerCase()] ?? (y + 1);
  }
}

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

    const rowGap = 3;
    const colGap = 8;
    const marginX = 2;
    const marginY = 1;

    final rowWidths = <int>[];
    final rowHeights = <int>[];
    for (final row in layout.rows) {
      var width = 0;
      var rowHeight = 0;
      for (var i = 0; i < row.length; i++) {
        final spec = tableSpecs[row[i].name.toLowerCase()]!;
        width += spec.width;
        if (i > 0) width += colGap;
        if (spec.height > rowHeight) rowHeight = spec.height;
      }
      rowWidths.add(width);
      rowHeights.add(rowHeight);
    }

    var maxRowWidth = 0;
    for (final width in rowWidths) {
      if (width > maxRowWidth) maxRowWidth = width;
    }

    final nodesByName = <String, _TableNodeLayout>{};
    var cursorY = marginY;
    for (var rowIndex = 0; rowIndex < layout.rows.length; rowIndex++) {
      final row = layout.rows[rowIndex];
      final rowWidth = rowWidths[rowIndex];
      var cursorX = marginX + ((maxRowWidth - rowWidth) ~/ 2);

      for (final table in row) {
        final spec = tableSpecs[table.name.toLowerCase()]!;
        nodesByName[table.name.toLowerCase()] = _TableNodeLayout(
          table: table,
          x: cursorX,
          y: cursorY,
          width: spec.width,
          height: spec.height,
          columnYByName: <String, int>{},
        );
        cursorX += spec.width + colGap;
      }

      cursorY += rowHeights[rowIndex] + rowGap;
    }

    var minX = 0;
    var minY = 0;
    var maxX = 0;
    var maxY = 0;
    for (final node in nodesByName.values) {
      if (node.x < minX) minX = node.x;
      if (node.y < minY) minY = node.y;
      if (node.x + node.width > maxX) maxX = node.x + node.width;
      if (node.y + node.height > maxY) maxY = node.y + node.height;
    }

    for (final edge in layout.edges) {
      final source = nodesByName[edge.sourceTable.toLowerCase()];
      final target = nodesByName[edge.targetTable.toLowerCase()];
      if (source == null || target == null) continue;

      final sourceToRight = target.centerX >= source.centerX;
      final sourceOutX = sourceToRight
          ? (source.x + source.width)
          : (source.x - 1);
      final targetInX = sourceToRight
          ? (target.x - 1)
          : (target.x + target.width);
      var midX = (sourceOutX + targetInX) ~/ 2;

      if (sourceToRight && targetInX <= sourceOutX) {
        midX = sourceOutX + 2;
      } else if (!sourceToRight && targetInX >= sourceOutX) {
        midX = sourceOutX - 2;
      }

      if (sourceOutX < minX) minX = sourceOutX;
      if (targetInX < minX) minX = targetInX;
      if (midX < minX) minX = midX;
      if (sourceOutX > maxX) maxX = sourceOutX;
      if (targetInX > maxX) maxX = targetInX;
      if (midX > maxX) maxX = midX;
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

      if (current == ' ' || char == '>' || char == '<') {
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

    for (final entry in nodesByName.entries) {
      final node = entry.value;
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

      final title = fit(node.table.name, innerWidth);
      drawText(node.x + 1, node.y + 1, title);

      final sepY = node.y + 2;
      drawAt(node.x, sepY, '+');
      drawAt(node.x + node.width - 1, sepY, '+');
      for (var x = node.x + 1; x < node.x + node.width - 1; x++) {
        drawAt(x, sepY, '-');
      }

      final foreignKeysByColumn = <String, List<ForeignKeyDef>>{};
      for (final fk in node.table.foreignKeys) {
        foreignKeysByColumn.putIfAbsent(fk.columnName.toLowerCase(), () => []);
        foreignKeysByColumn[fk.columnName.toLowerCase()]!.add(fk);
      }

      final mutableMap = <String, int>{};
      if (node.table.columns.isEmpty) {
        drawText(node.x + 1, node.y + 3, fit('(sem colunas)', innerWidth));
      } else {
        for (var index = 0; index < node.table.columns.length; index++) {
          final column = node.table.columns[index];
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
              columnColorByKey[_columnKey(node.table.name, column.name)];
          drawText(
            node.x + 1,
            lineY,
            fit(label, innerWidth),
            color: relationColor,
          );
          mutableMap[column.name.toLowerCase()] = lineY;
        }
      }

      nodesByName[entry.key] = _TableNodeLayout(
        table: node.table,
        x: node.x,
        y: node.y,
        width: node.width,
        height: node.height,
        columnYByName: mutableMap,
      );
    }

    for (var edgeIndex = 0; edgeIndex < layout.edges.length; edgeIndex++) {
      final edge = layout.edges[edgeIndex];
      final edgeColor = edgeColorByIndex[edgeIndex];
      final source = nodesByName[edge.sourceTable.toLowerCase()];
      final target = nodesByName[edge.targetTable.toLowerCase()];
      if (source == null || target == null) continue;

      final sourceY = source.columnAnchorY(edge.sourceColumn);
      final targetY = target.columnAnchorY(edge.targetColumn);
      final sourceToRight = target.centerX >= source.centerX;
      final sourceOutX = sourceToRight
          ? (source.x + source.width)
          : (source.x - 1);
      final targetInX = sourceToRight
          ? (target.x - 1)
          : (target.x + target.width);
      var midX = (sourceOutX + targetInX) ~/ 2;

      if (sourceToRight && targetInX <= sourceOutX) {
        midX = sourceOutX + 2;
      } else if (!sourceToRight && targetInX >= sourceOutX) {
        midX = sourceOutX - 2;
      }

      drawHorizontal(sourceY, sourceOutX, midX, color: edgeColor);
      drawVertical(midX, sourceY, targetY, color: edgeColor);
      drawHorizontal(targetY, midX, targetInX, color: edgeColor);
      drawAt(midX, sourceY, '+', color: edgeColor);
      drawAt(midX, targetY, '+', color: edgeColor);
      drawAt(targetInX, targetY, sourceToRight ? '>' : '<', color: edgeColor);
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
