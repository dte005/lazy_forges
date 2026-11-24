// Testes de feature: foreign keys e seu impacto no DDL exportado.
import 'package:lazy_forge/src/components/editor/models/schema_model.dart';
import 'package:lazy_forge/src/components/editor/providers/editor_provider.dart';
import 'package:lazy_forge/src/services/storage/project_storage.dart';
import 'package:test/test.dart';

void main() {
  late EditorProvider editor;

  setUp(() {
    editor = EditorProvider(
      schemaState: SchemaState(),
      projectName: 'proj_test_fk',
      projectStorage: ProjectStorage(),
    );
    editor.submitCommand(
      'create table authors --autoincrement - '
      'create table books --autoincrement - '
      'add column books author_id integer',
    );
  });

  group('F07 adicionar FK', () {
    test('cria FK apontando para PK de outra tabela', () {
      editor.submitCommand('add fk books author_id references authors id');

      expect(editor.lastCommandFailed, isFalse);
      final books = editor.schemaState.findTableByName('books')!;
      final fk = books.foreignKeys.single;
      expect(fk.columnName, 'author_id');
      expect(fk.referenceTableName, 'authors');
      expect(fk.referenceColumnName, 'id');
    });

    test('FK aparece no DDL exportado como FOREIGN KEY', () {
      editor.submitCommand('add fk books author_id references authors id');

      final ddl = editor.schemaState.toSqlDdl();
      expect(ddl, contains('FOREIGN KEY (author_id) REFERENCES authors(id)'));
    });

    test('rejeita FK para tabela de referência inexistente', () {
      editor.submitCommand('add fk books author_id references ghost id');

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.lastFeedback, contains('não encontrada'));
    });

    test('rejeita FK para coluna de referência inexistente', () {
      editor.submitCommand(
        'add fk books author_id references authors ghost_col',
      );

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.lastFeedback, contains('não encontrada'));
    });

    test('rejeita FK para coluna de referência que não é PK', () {
      editor.submitCommand('add column authors nickname varchar(50)');
      editor.submitCommand(
        'add fk books author_id references authors nickname',
      );

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.lastFeedback, contains('precisa ser PK'));
    });

    test(
      'rejeita FK duplicada para a mesma coluna/tabela/coluna de referência',
      () {
        editor.submitCommand('add fk books author_id references authors id');
        editor.submitCommand('add fk books author_id references authors id');

        expect(editor.lastCommandFailed, isTrue);
        expect(editor.lastFeedback, contains('FK já existe'));
      },
    );

    test('rejeita FK em tabela de origem inexistente', () {
      editor.submitCommand('add fk ghost col references authors id');

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.lastFeedback, contains('não encontrada'));
    });
  });
}
