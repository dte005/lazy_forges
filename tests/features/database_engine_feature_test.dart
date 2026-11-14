// Testes de funcionalidade: troca de engine de banco, "show database" e
// "show types".
import 'package:lazy_forge/src/components/editor/models/schema_model.dart';
import 'package:lazy_forge/src/components/editor/providers/editor_provider.dart';
import 'package:lazy_forge/src/services/storage/project_storage.dart';
import 'package:test/test.dart';

void main() {
  late EditorProvider editor;

  setUp(() {
    editor = EditorProvider(
      schemaState: SchemaState(),
      projectName: 'proj_test_engine',
      projectStorage: ProjectStorage(),
    );
  });

  group('F11 trocar engine', () {
    test('troca para mysql com "set database mysql"', () {
      editor.submitCommand('set database mysql');

      expect(editor.lastCommandFailed, isFalse);
      expect(editor.schemaState.databaseEngine.label, 'mysql');
    });

    test('troca para sqlite com "set database sqlite"', () {
      editor.submitCommand('set database sqlite');

      expect(editor.schemaState.databaseEngine.label, 'sqlite');
    });

    test('rejeita engine desconhecida com mensagem clara', () {
      editor.submitCommand('set database oracle');

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.lastFeedback, contains('inválido'));
    });

    test(
      'tipo válido numa engine pode ficar inválido depois de trocar de engine',
      () {
        editor.submitCommand('create table t - add column t amount decimal');
        editor.submitCommand('set database sqlite');
        editor.submitCommand('alter column t amount type decimal');

        expect(editor.lastCommandFailed, isTrue);
        expect(editor.lastFeedback, contains('inválido'));
      },
    );
  });

  group('F12 "show database"', () {
    test('informa a engine atual (postgres por padrão)', () {
      editor.submitCommand('show database');

      expect(editor.lastFeedback, contains('postgres'));
    });
  });

  group('F13 "show types"', () {
    test('lista tipos permitidos para postgres', () {
      editor.submitCommand('show types');

      expect(editor.lastFeedback, contains('varchar'));
      expect(editor.lastFeedback, contains('postgres'));
    });

    test('lista tipos diferentes depois de trocar para sqlite', () {
      editor.submitCommand('set database sqlite');
      editor.submitCommand('show types');

      expect(editor.lastFeedback, contains('sqlite'));
      expect(editor.lastFeedback, isNot(contains('serial')));
    });
  });
}
