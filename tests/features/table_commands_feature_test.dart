// Testes de funcionalidade: criação, remoção, renomeação e listagem de
// tabelas, dirigidos pela API pública (`EditorProvider.submitCommand`).
import 'package:lazy_forge/src/components/editor/models/schema_model.dart';
import 'package:lazy_forge/src/components/editor/providers/editor_provider.dart';
import 'package:lazy_forge/src/services/storage/project_storage.dart';
import 'package:test/test.dart';

void main() {
  late EditorProvider editor;

  setUp(() {
    editor = EditorProvider(
      schemaState: SchemaState(),
      projectName: 'proj_test_tables',
      projectStorage: ProjectStorage(),
    );
  });

  group('F01 criar tabela', () {
    test('cria tabela vazia com sucesso', () {
      editor.submitCommand('create table users');

      expect(editor.lastCommandFailed, isFalse);
      expect(editor.schemaState.findTableByName('users'), isNotNull);
    });

    test('cria tabela com --autoincrement e id como PK', () {
      editor.submitCommand('create table users --autoincrement');

      expect(editor.lastCommandFailed, isFalse);
      final table = editor.schemaState.findTableByName('users')!;
      final id = editor.schemaState.findColumnByName(table, 'id');
      expect(id, isNotNull);
      expect(id!.isPrimaryKey, isTrue);
    });

    test('rejeita criar tabela duplicada com mensagem clara', () {
      editor.submitCommand('create table users');
      editor.submitCommand('create table users');

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.lastFeedback, contains('já existe'));
    });
  });

  group('F02 remover tabela', () {
    test('remove tabela existente com "delete table"', () {
      editor.submitCommand('create table users');
      editor.submitCommand('delete table users');

      expect(editor.lastCommandFailed, isFalse);
      expect(editor.schemaState.findTableByName('users'), isNull);
    });

    test('remove tabela existente com "drop table"', () {
      editor.submitCommand('create table orders');
      editor.submitCommand('drop table orders');

      expect(editor.lastCommandFailed, isFalse);
      expect(editor.schemaState.findTableByName('orders'), isNull);
    });

    test('rejeita remover tabela inexistente com mensagem clara', () {
      editor.submitCommand('delete table ghost');

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.lastFeedback, contains('não encontrada'));
    });

    test('remover tabela referenciada limpa FKs que apontavam para ela', () {
      editor.submitCommand(
        'create table authors --autoincrement - '
        'create table books --autoincrement - '
        'add column books author_id integer - '
        'add fk books author_id references authors id',
      );
      expect(editor.lastCommandFailed, isFalse);
      editor.submitCommand('delete table authors');

      final books = editor.schemaState.findTableByName('books')!;
      expect(books.foreignKeys, isEmpty);
    });
  });

  group('F08 renomear/trocar tabela', () {
    test('renomeia tabela com "rename table"', () {
      editor.submitCommand('create table clients');
      editor.submitCommand('rename table clients to customers');

      expect(editor.lastCommandFailed, isFalse);
      expect(editor.schemaState.findTableByName('clients'), isNull);
      expect(editor.schemaState.findTableByName('customers'), isNotNull);
    });

    test('renomeia tabela com "change table" (sinônimo)', () {
      editor.submitCommand('create table products');
      editor.submitCommand('change table products to items');

      expect(editor.lastCommandFailed, isFalse);
      expect(editor.schemaState.findTableByName('items'), isNotNull);
    });

    test('rejeita renomear para nome já existente', () {
      editor.submitCommand('create table a');
      editor.submitCommand('create table b');
      editor.submitCommand('rename table a to b');

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.lastFeedback, contains('já existe'));
    });

    test('renomear tabela atualiza referências de FK existentes', () {
      editor.submitCommand(
        'create table authors --autoincrement - '
        'create table books --autoincrement - '
        'add column books author_id integer - '
        'add fk books author_id references authors id',
      );
      editor.submitCommand('rename table authors to writers');

      final books = editor.schemaState.findTableByName('books')!;
      expect(books.foreignKeys.single.referenceTableName, 'writers');
    });
  });

  group('F14 listar tabelas', () {
    test('"show tables" informa que não há tabelas quando vazio', () {
      editor.submitCommand('show tables');

      expect(editor.lastCommandFailed, isFalse);
      expect(editor.lastFeedback, contains('Nenhuma tabela'));
    });

    test('"show tables" lista os nomes das tabelas criadas', () {
      editor.submitCommand('create table a - create table b');
      editor.submitCommand('show tables');

      expect(editor.lastFeedback, contains('a'));
      expect(editor.lastFeedback, contains('b'));
    });
  });
}
