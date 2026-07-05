import 'package:nocterm/nocterm.dart';
import '../../../../model/schema_state.dart';

class SidebarComponent extends StatelessComponent {
  const SidebarComponent({super.key, required this.schemas});

  final SchemaState schemas;

  @override
  Component build(BuildContext context) {
    final orderedTables = [...schemas.tables]
      ..sort((left, right) => left.name.compareTo(right.name));

    final items = <Component>[
      const Text(
        'SCHEMA',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
      ),
      const Divider(style: DividerStyle.single),
    ];

    for (final table in orderedTables) {
      final foreignKeysByColumn = <String, List<ForeignKeyDef>>{};
      for (final fk in table.foreignKeys) {
        foreignKeysByColumn.putIfAbsent(fk.columnName.toLowerCase(), () => []);
        foreignKeysByColumn[fk.columnName.toLowerCase()]!.add(fk);
      }

      final nodeChildren = <Component>[
        Text(
          '+ ${table.name}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.cyan,
          ),
        ),
      ];

      if (table.columns.isEmpty) {
        nodeChildren.add(const Text('   - (sem colunas)'));
      } else {
        for (final column in table.columns) {
          final tags = <String>[];
          if (column.isPrimaryKey) tags.add('PK');
          if ((foreignKeysByColumn[column.name.toLowerCase()] ??
                  const <ForeignKeyDef>[])
              .isNotEmpty) {
            tags.add('FK');
          }

          final tagText = tags.isEmpty ? '' : ' [${tags.join('|')}]';
          final enumText = column.enumOptions.isEmpty
              ? ''
              : ' {${column.enumOptions.join('|')}}';
          final descriptionText = (column.description == null || column.description!.isEmpty)
              ? ''
              : ' -- ${column.description}';
          nodeChildren.add(
            Text(
              '   - ${column.name}: ${column.type}$enumText$tagText$descriptionText',
            ),
          );

          final references =
              foreignKeysByColumn[column.name.toLowerCase()] ??
                  const <ForeignKeyDef>[];
          for (final fk in references) {
            nodeChildren.add(
              Text(
                '      => ${fk.referenceTableName}.${fk.referenceColumnName}',
                style: const TextStyle(color: Colors.brightCyan),
              ),
            );
          }
        }
      }

      items.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: nodeChildren,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items,
    );
  }
}