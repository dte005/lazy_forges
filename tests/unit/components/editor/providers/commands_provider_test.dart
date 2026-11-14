// Testes unitários do `CommandsProvider` isolados de `EditorProvider`,
// cobrindo ramos de parsing que os testes de funcionalidade não exercitam
// diretamente (ex.: sintaxe verbosa com options/description e specs
// malformadas em lote).
import 'package:lazy_forge/src/components/editor/models/schema_model.dart';
import 'package:lazy_forge/src/components/editor/providers/commands_provider.dart';
import 'package:lazy_forge/src/services/storage/project_storage.dart';
import 'package:test/test.dart';

void main() {
  late CommandsProvider provider;
  late SchemaState schema;
  late ProjectStorage storage;

  setUp(() {
    provider = CommandsProvider();
    schema = SchemaState();
    storage = ProjectStorage();
    schema.addTable('t');
  });

  EditorCommandResultLike handle(String command) {
    final result = provider.handle(
      command,
      schema,
      projectName: 'unit_cmd_provider',
      projectStorage: storage,
    );
    return EditorCommandResultLike(
      result.success,
      result.message,
      result.shouldPersist,
    );
  }

  group('CommandsProvider.handle — sintaxe verbosa com options/description', () {
    test('cria coluna enum com options e description na sintaxe verbosa', () {
      final result = handle(
        'add column status type enum to t as pk options(a|b) description(estado)',
      );

      expect(result.success, isTrue);
      final table = schema.findTableByName('t')!;
      final column = schema.findColumnByName(table, 'status')!;
      expect(column.enumOptions, ['a', 'b']);
      expect(column.description, 'estado');
      expect(column.isPrimaryKey, isTrue);
    });
  });

  group('CommandsProvider.handle — lote de colunas malformado', () {
    test('mensagem de erro cita o trecho inválido do lote', () {
      final result = handle('add columns t nome_sem_tipo');

      expect(result.success, isFalse);
      expect(result.message, contains('Formato inválido de coluna'));
    });

    test('lote vazio (apenas separadores) gera mensagem de erro dedicada', () {
      final result = handle('add columns t ;;; ,,,');

      expect(result.success, isFalse);
      expect(result.message, contains('Nenhuma coluna detectada'));
    });
  });

  group('CommandsProvider.handle — comando desconhecido', () {
    test('não persiste e devolve shouldPersist=false', () {
      final result = handle('isso nao existe');

      expect(result.success, isFalse);
      expect(result.shouldPersist, isFalse);
    });
  });

  group('CommandsProvider.handle — alias "string" normaliza para "text"', () {
    test('tipo "string" é tratado como "text" ao adicionar coluna', () {
      final result = handle('add column t apelido string');

      expect(result.success, isTrue);
      final table = schema.findTableByName('t')!;
      expect(schema.findColumnByName(table, 'apelido')!.type, 'text');
    });
  });
}

/// Pequeno wrapper para expor os três campos relevantes de
/// `EditorCommandResult` sem acoplar os testes ao tipo exato.
class EditorCommandResultLike {
  EditorCommandResultLike(this.success, this.message, this.shouldPersist);

  final bool success;
  final String message;
  final bool shouldPersist;
}
