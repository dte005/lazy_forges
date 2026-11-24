// Testes de feature: command history, "help", encadeamento com
// " - " and handling of invalid/empty commands.
import 'package:lazy_forge/src/components/editor/models/schema_model.dart';
import 'package:lazy_forge/src/components/editor/providers/editor_provider.dart';
import 'package:lazy_forge/src/services/storage/project_storage.dart';
import 'package:test/test.dart';

void main() {
  late EditorProvider editor;

  setUp(() {
    editor = EditorProvider(
      schemaState: SchemaState(),
      projectName: 'proj_test_history',
      projectStorage: ProjectStorage(),
    );
  });

  group('F15 histórico de comandos', () {
    test('informa que não há histórico quando nenhum comando foi digitado', () {
      editor.submitCommand('history');

      expect(editor.lastCommandFailed, isFalse);
      expect(editor.lastFeedback, contains('não há comandos'));
    });

    test('lista comandos já submetidos, numerados', () {
      editor.submitCommand('create table a');
      editor.submitCommand('create table b');
      editor.submitCommand('history');

      expect(editor.lastFeedback, contains('1. create table a'));
      expect(editor.lastFeedback, contains('2. create table b'));
    });

    test('registra comando mesmo quando ele falha', () {
      editor.submitCommand('comando invalido xyz');

      expect(editor.commandHistory, contains('comando invalido xyz'));
    });

    test(
      '"history" em si não entra no próprio histórico listado antes dele',
      () {
        editor.submitCommand('create table a');
        editor.submitCommand('history');

        expect(editor.commandHistory, ['create table a']);
      },
    );
  });

  group('F16 "help"', () {
    test('lista os comandos suportados mencionando a engine atual', () {
      editor.submitCommand('help');

      expect(editor.lastCommandFailed, isFalse);
      expect(editor.lastFeedback, contains('DB atual: postgres'));
      expect(editor.lastFeedback, contains('create table'));
    });
  });

  group('F17 encadeamento de comandos com " - "', () {
    test('executa múltiplos comandos em sequência numa única chamada', () {
      editor.submitCommand(
        'create table users - add column users name varchar(255)',
      );

      expect(editor.lastCommandFailed, isFalse);
      final table = editor.schemaState.findTableByName('users')!;
      expect(editor.schemaState.findColumnByName(table, 'name'), isNotNull);
    });

    test('interrompe a cadeia no primeiro comando que falhar', () {
      editor.submitCommand(
        'create table users - add column ghost_table name varchar(255) - '
        'create table should_not_run',
      );

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.schemaState.findTableByName('should_not_run'), isNull);
      // The first command in the chain was already applied before the failure.
      expect(editor.schemaState.findTableByName('users'), isNotNull);
    });

    test('não separa em "-" dentro de options(...)/description(...)', () {
      editor.submitCommand(
        'create table t - add column t status enum as pk '
        'description(texto - com traço)',
      );

      expect(
        editor.lastCommandFailed,
        isTrue,
        reason: 'enum exige options(...)',
      );
      expect(editor.lastFeedback, contains('precisa de options'));
    });
  });

  group('F18 comando inválido/vazio', () {
    test('comando vazio retorna mensagem clara e não quebra o app', () {
      editor.submitCommand('   ');

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.lastFeedback, contains('Comando vazio'));
    });

    test('comando desconhecido retorna mensagem acionável citando "help"', () {
      editor.submitCommand('faz alguma coisa estranha');

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.lastFeedback, contains('help'));
    });
  });
}
