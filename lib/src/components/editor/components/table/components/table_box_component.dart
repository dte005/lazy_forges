import 'package:nocterm/nocterm.dart';

import '../../../models/schema_model.dart';

class TableBoxComponent extends StatelessComponent {
  const TableBoxComponent({super.key, required this.table});

  final TableDef table;

  @override
  Component build(BuildContext context) {
    final foreignKeysByColumn = <String, List<ForeignKeyDef>>{};
    for (final fk in table.foreignKeys) {
      foreignKeysByColumn.putIfAbsent(fk.columnName.toLowerCase(), () => []);
      foreignKeysByColumn[fk.columnName.toLowerCase()]!.add(fk);
    }
    final rows = <Component>[
      Text(
        table.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.brightCyan,
        ),
      ),
      const Divider(style: DividerStyle.single),
    ];

    if (table.columns.isEmpty) {
      rows.add(const Text('  (sem colunas)'));
    } else {
      for (final column in table.columns) {
        final fkRefs =
            foreignKeysByColumn[column.name.toLowerCase()] ?? const [];
        final tags = <String>[];
        if (column.isPrimaryKey) {
          tags.add('PK');
        }
        if (fkRefs.isNotEmpty) {
          tags.add('FK');
        }

        final tagPrefix = tags.isEmpty ? '' : '[${tags.join('|')}] ';
        rows.add(Text('  $tagPrefix${column.name} : ${column.type}'));

        for (final fk in fkRefs) {
          rows.add(
            Text(
              '      -> ${fk.referenceTableName}.${fk.referenceColumnName}',
              style: const TextStyle(color: Colors.brightCyan),
            ),
          );
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        border: BoxBorder.all(style: BoxBorderStyle.solid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }
}
