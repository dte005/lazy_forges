// Testes de funcionalidade: adicionar/renomear/alterar colunas, PK e
// colunas enum, dirigidos pela API pública (`EditorProvider.submitCommand`).
import 'package:lazy_forge/src/components/editor/models/schema_model.dart';
import 'package:lazy_forge/src/components/editor/providers/editor_provider.dart';
import 'package:lazy_forge/src/services/storage/project_storage.dart';
import 'package:test/test.dart';

void main() {
  late EditorProvider editor;

  setUp(() {
    editor = EditorProvider(
      schemaState: SchemaState(),
      projectName: 'proj_test_columns',
      projectStorage: ProjectStorage(),
    );
    editor.submitCommand('create table users');
  });

  group('F03 adicionar coluna (sintaxe curta)', () {
    test('adiciona coluna simples', () {
      editor.submitCommand('add column users name varchar(255)');

      expect(editor.lastCommandFailed, isFalse);
      final table = editor.schemaState.findTableByName('users')!;
      expect(editor.schemaState.findColumnByName(table, 'name'), isNotNull);
    });

    test('adiciona coluna como pk com "as pk"', () {
      editor.submitCommand('add column users id integer as pk');

      final table = editor.schemaState.findTableByName('users')!;
      final column = editor.schemaState.findColumnByName(table, 'id')!;
      expect(column.isPrimaryKey, isTrue);
    });

    test('rejeita tipo inválido para a engine atual com mensagem clara', () {
      editor.submitCommand('add column users weird_col notatype');

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.lastFeedback, contains('inválido'));
    });

    test('rejeita coluna duplicada na mesma tabela', () {
      editor.submitCommand('add column users name varchar(255)');
      editor.submitCommand('add column users name text');

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.lastFeedback, contains('já existe'));
    });
  });

  group('F04 adicionar coluna (sintaxe verbosa)', () {
    test('adiciona coluna com "add column <col> type <type> to <table>"', () {
      editor.submitCommand('add column email type varchar(255) to users');

      final table = editor.schemaState.findTableByName('users')!;
      expect(editor.schemaState.findColumnByName(table, 'email'), isNotNull);
    });
  });

  group('F05 adicionar colunas em lote', () {
    test('cria múltiplas colunas separadas por ";"', () {
      editor.submitCommand('add columns users name varchar(255); age integer');

      final table = editor.schemaState.findTableByName('users')!;
      expect(editor.schemaState.findColumnByName(table, 'name'), isNotNull);
      expect(editor.schemaState.findColumnByName(table, 'age'), isNotNull);
    });

    test('rejeita lote com formato de coluna inválido', () {
      editor.submitCommand('add columns users ,,,');

      expect(editor.lastCommandFailed, isTrue);
    });
  });

  group('F06 definir PK', () {
    test('define PK em coluna existente', () {
      editor.submitCommand('add column users id integer');
      editor.submitCommand('set pk users id');

      final table = editor.schemaState.findTableByName('users')!;
      expect(
        editor.schemaState.findColumnByName(table, 'id')!.isPrimaryKey,
        isTrue,
      );
    });

    test('rejeita definir PK em coluna já PK', () {
      editor.submitCommand('add column users id integer as pk');
      editor.submitCommand('set pk users id');

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.lastFeedback, contains('já é PK'));
    });

    test('rejeita definir PK em coluna inexistente', () {
      editor.submitCommand('set pk users ghost');

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.lastFeedback, contains('não encontrada'));
    });
  });

  group('F09 renomear coluna', () {
    test('renomeia coluna com "rename column"', () {
      editor.submitCommand('add column users nm varchar(255)');
      editor.submitCommand('rename column users nm to name');

      final table = editor.schemaState.findTableByName('users')!;
      expect(editor.schemaState.findColumnByName(table, 'nm'), isNull);
      expect(editor.schemaState.findColumnByName(table, 'name'), isNotNull);
    });

    test('renomeia coluna com "change column" (sinônimo)', () {
      editor.submitCommand('add column users nm varchar(255)');
      editor.submitCommand('change column users nm to name');

      final table = editor.schemaState.findTableByName('users')!;
      expect(editor.schemaState.findColumnByName(table, 'name'), isNotNull);
    });

    test('rejeita renomear para nome de coluna já existente', () {
      editor.submitCommand('add columns users a integer; b integer');
      editor.submitCommand('rename column users a to b');

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.lastFeedback, contains('já existe'));
    });
  });

  group('F10 alterar tipo de coluna', () {
    test('altera tipo com "alter column ... type"', () {
      editor.submitCommand('add column users age varchar(10)');
      editor.submitCommand('alter column users age type integer');

      final table = editor.schemaState.findTableByName('users')!;
      expect(
        editor.schemaState.findColumnByName(table, 'age')!.type,
        'integer',
      );
    });

    test('altera tipo com "change column ... type" (sinônimo)', () {
      editor.submitCommand('add column users age varchar(10)');
      editor.submitCommand('change column users age type integer');

      final table = editor.schemaState.findTableByName('users')!;
      expect(
        editor.schemaState.findColumnByName(table, 'age')!.type,
        'integer',
      );
    });

    test('rejeita alterar para tipo não suportado na engine atual', () {
      editor.submitCommand('add column users age integer');
      editor.submitCommand('alter column users age type notatype');

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.lastFeedback, contains('inválido'));
    });
  });

  group('F20 colunas enum', () {
    test('cria coluna enum com options(v1|v2) e aplica no DDL como CHECK', () {
      editor.submitCommand(
        'add column users status enum as pk options(ativo|inativo)',
      );

      expect(editor.lastCommandFailed, isFalse);
      final ddl = editor.schemaState.toSqlDdl();
      expect(ddl, contains("CHECK (status IN ('ativo', 'inativo'))"));
    });

    test('rejeita enum sem options(...)', () {
      editor.submitCommand('add column users status enum');

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.lastFeedback, contains('precisa de options'));
    });

    test('rejeita options(...) em coluna não-enum', () {
      editor.submitCommand('add column users name varchar options(a|b)');

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.lastFeedback, contains('só pode ser usado com tipo enum'));
    });

    test('rejeita valores duplicados em options(...)', () {
      editor.submitCommand('add column users status enum options(a|a)');

      expect(editor.lastCommandFailed, isTrue);
      expect(editor.lastFeedback, contains('duplicado'));
    });
  });
}
