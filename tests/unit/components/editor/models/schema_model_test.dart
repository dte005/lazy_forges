// Unit tests: (de)serialization round-trip and domain rules of
// `SchemaState` / `TableDef` / `ColumnDef` not exercised in
// profundidade pelos testes de feature.
import 'package:lazy_forge/src/components/editor/models/schema_model.dart';
import 'package:lazy_forge/src/shared/models/enums.dart';
import 'package:test/test.dart';

void main() {
  group('ColumnDef', () {
    test('fromJson usa defaults quando campos estão ausentes', () {
      final column = ColumnDef.fromJson(const <String, dynamic>{});

      expect(column.name, '');
      expect(column.type, 'text');
      expect(column.isPrimaryKey, isFalse);
      expect(column.enumOptions, isEmpty);
      expect(column.description, isNull);
    });

    test('toJson/fromJson preserva todos os campos', () {
      final original = ColumnDef(
        name: 'status',
        type: 'enum',
        isPrimaryKey: true,
        enumOptions: ['ativo', 'inativo'],
        description: 'estado atual',
      );

      final restored = ColumnDef.fromJson(original.toJson());

      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.isPrimaryKey, original.isPrimaryKey);
      expect(restored.enumOptions, original.enumOptions);
      expect(restored.description, original.description);
    });
  });

  group('ForeignKeyDef', () {
    test('toJson/fromJson preserva todos os campos', () {
      final original = ForeignKeyDef(
        columnName: 'author_id',
        referenceTableName: 'authors',
        referenceColumnName: 'id',
      );

      final restored = ForeignKeyDef.fromJson(original.toJson());

      expect(restored.columnName, 'author_id');
      expect(restored.referenceTableName, 'authors');
      expect(restored.referenceColumnName, 'id');
    });
  });

  group('SchemaState.fromJson', () {
    test('usa postgres como padrão quando databaseEngine é desconhecido', () {
      final state = SchemaState.fromJson(const <String, dynamic>{
        'databaseEngine': 'oracle',
        'tables': <dynamic>[],
      });

      expect(state.databaseEngine, DatabaseEngine.postgres);
    });

    test('round-trip completo preserva tabelas, colunas e FKs', () {
      final original = SchemaState()..setDatabaseEngine(DatabaseEngine.mysql);
      original.addTable('authors');
      original.addColumn('authors', 'id', 'int');
      original.setPrimaryKey('authors', 'id');
      original.addTable('books');
      original.addColumn('books', 'author_id', 'int');
      original.addForeignKey('books', 'author_id', 'authors', 'id');

      final restored = SchemaState.fromJson(original.toJson());

      expect(restored.databaseEngine, DatabaseEngine.mysql);
      expect(restored.tables.map((t) => t.name), ['authors', 'books']);
      final books = restored.findTableByName('books')!;
      expect(books.foreignKeys.single.referenceTableName, 'authors');
    });

    test('ignora tabelas malformadas na lista sem lançar erro', () {
      final state = SchemaState.fromJson(const <String, dynamic>{
        'databaseEngine': 'postgres',
        'tables': <dynamic>['not-a-map', 42],
      });

      expect(state.tables, isEmpty);
    });
  });

  group('SchemaState tipos por engine', () {
    test('isColumnTypeAllowed ignora parênteses e caixa', () {
      final state = SchemaState();

      expect(state.isColumnTypeAllowed('VARCHAR(255)'), isTrue);
      expect(state.isColumnTypeAllowed('not_a_type'), isFalse);
    });

    test('getAllowedTypes muda conforme a engine selecionada', () {
      final state = SchemaState();
      final postgresTypes = state.getAllowedTypes();

      state.setDatabaseEngine(DatabaseEngine.sqlite);
      final sqliteTypes = state.getAllowedTypes();

      expect(postgresTypes.contains('serial'), isTrue);
      expect(sqliteTypes.contains('serial'), isFalse);
    });
  });

  group('SchemaState mutações com alvo inexistente são no-ops seguros', () {
    test('addColumn em tabela inexistente não lança e não adiciona nada', () {
      final state = SchemaState();

      state.addColumn('ghost', 'col', 'text');

      expect(state.tables, isEmpty);
    });

    test('setPrimaryKey em tabela/coluna inexistente não lança', () {
      final state = SchemaState()..addTable('t');

      state.setPrimaryKey('t', 'ghost_col');
      state.setPrimaryKey('ghost_table', 'col');

      expect(state.findTableByName('t')!.columns, isEmpty);
    });

    test('deleteTable retorna false para tabela inexistente', () {
      final state = SchemaState();

      expect(state.deleteTable('ghost'), isFalse);
    });

    test('renameTable retorna false para tabela inexistente', () {
      final state = SchemaState();

      expect(state.renameTable('ghost', 'new'), isFalse);
    });

    test('renameColumn retorna false quando coluna não existe', () {
      final state = SchemaState()..addTable('t');

      expect(state.renameColumn('t', 'ghost', 'new'), isFalse);
    });

    test('changeColumnType retorna false quando coluna não existe', () {
      final state = SchemaState()..addTable('t');

      expect(state.changeColumnType('t', 'ghost', 'int'), isFalse);
    });

    test('setColumnDescription limpa a descrição quando valor é vazio', () {
      final state = SchemaState()..addTable('t');
      state.addColumn('t', 'c', 'text', description: 'algo');

      final updated = state.setColumnDescription('t', 'c', '   ');

      expect(updated, isTrue);
      final column = state.findColumnByName(state.findTableByName('t')!, 'c')!;
      expect(column.description, isNull);
    });
  });

  group('SchemaState.toSqlDdl', () {
    test('inclui comentário de descrição de coluna quando presente', () {
      final state = SchemaState()..addTable('t');
      state.addColumn('t', 'c', 'text', description: 'um comentário');

      final ddl = state.toSqlDdl();

      expect(ddl, contains('-- c: um comentário'));
    });

    test('escapa aspas simples nos valores de enum', () {
      final state = SchemaState()..addTable('t');
      state.addColumn('t', 'status', 'enum', enumOptions: ["it's ok"]);

      final ddl = state.toSqlDdl();

      expect(ddl, contains("'it''s ok'"));
    });

    test('mantém enumOptions ao trocar tipo de coluna que permanece enum', () {
      final state = SchemaState()..addTable('t');
      state.addColumn('t', 'status', 'enum', enumOptions: ['a', 'b']);

      state.changeColumnType('t', 'status', 'enum', enumOptions: ['c', 'd']);

      final column = state.findColumnByName(
        state.findTableByName('t')!,
        'status',
      )!;
      expect(column.enumOptions, ['c', 'd']);
    });

    test('limpa enumOptions ao trocar de enum para um tipo não-enum', () {
      final state = SchemaState()..addTable('t');
      state.addColumn('t', 'status', 'enum', enumOptions: ['a', 'b']);

      state.changeColumnType('t', 'status', 'text');

      final column = state.findColumnByName(
        state.findTableByName('t')!,
        'status',
      )!;
      expect(column.enumOptions, isEmpty);
    });
  });
}
