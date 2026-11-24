// Unit tests: grouping tables into rows by the FK dependency graph
// (`GraphLayoutEngine`).
import 'package:lazy_forge/src/components/editor/components/table/graph_layout.dart';
import 'package:lazy_forge/src/components/editor/models/schema_model.dart';
import 'package:test/test.dart';

TableDef _table(String name, {List<ForeignKeyDef>? fks}) {
  return TableDef(name: name, foreignKeys: fks);
}

void main() {
  const engine = GraphLayoutEngine();

  group('GraphLayoutEngine.build', () {
    test('lista vazia produz layout vazio', () {
      final result = engine.build(const <TableDef>[]);

      expect(result.rows, isEmpty);
      expect(result.edges, isEmpty);
    });

    test('tabelas sem FK ficam todas no nível 0, ordenadas por nome', () {
      final result = engine.build([_table('b'), _table('a')]);

      expect(result.rows, hasLength(1));
      expect(result.rows.single.map((t) => t.name), ['a', 'b']);
    });

    test('tabela com FK fica em nível abaixo da tabela referenciada', () {
      final authors = _table('authors');
      final books = _table(
        'books',
        fks: [
          ForeignKeyDef(
            columnName: 'author_id',
            referenceTableName: 'authors',
            referenceColumnName: 'id',
          ),
        ],
      );

      final result = engine.build([books, authors]);

      expect(result.rows, hasLength(2));
      expect(result.rows[0].single.name, 'authors');
      expect(result.rows[1].single.name, 'books');
    });

    test('ignora FK cuja tabela de referência não está na lista', () {
      final books = _table(
        'books',
        fks: [
          ForeignKeyDef(
            columnName: 'x',
            referenceTableName: 'ghost',
            referenceColumnName: 'id',
          ),
        ],
      );

      final result = engine.build([books]);

      expect(result.rows, hasLength(1));
      expect(result.edges, isEmpty);
    });

    test(
      'auto-relacionamento (FK para a própria tabela) não quebra o layout',
      () {
        final t = _table(
          't',
          fks: [
            ForeignKeyDef(
              columnName: 'parent_id',
              referenceTableName: 't',
              referenceColumnName: 'id',
            ),
          ],
        );

        final result = engine.build([t]);

        expect(result.rows, hasLength(1));
        expect(result.edges, hasLength(1));
      },
    );

    test('respeita maxColumns ao quebrar uma linha longa em sublinhas', () {
      final tables = List.generate(5, (i) => _table('t$i'));

      final result = engine.build(tables, maxColumns: 2);

      expect(result.maxColumns, 2);
      expect(result.rows, hasLength(3));
      expect(result.rows[0], hasLength(2));
      expect(result.rows[2], hasLength(1));
    });

    test('maxColumns menor que 2 é normalizado para 2', () {
      final tables = List.generate(3, (i) => _table('t$i'));

      final result = engine.build(tables, maxColumns: 1);

      expect(result.maxColumns, 2);
    });

    test('ciclo de dependências entre tabelas não entra em loop infinito', () {
      final a = _table(
        'a',
        fks: [
          ForeignKeyDef(
            columnName: 'b_id',
            referenceTableName: 'b',
            referenceColumnName: 'id',
          ),
        ],
      );
      final b = _table(
        'b',
        fks: [
          ForeignKeyDef(
            columnName: 'a_id',
            referenceTableName: 'a',
            referenceColumnName: 'id',
          ),
        ],
      );

      final result = engine.build([a, b]);

      expect(result.rows.expand((r) => r), hasLength(2));
      expect(result.edges, hasLength(2));
    });
  });
}
