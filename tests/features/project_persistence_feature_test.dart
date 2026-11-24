// Testes de feature: createsr, salvar, listar e reabrir projetos via
// `ProjectStorage`, including automatic persistence triggered by
// `EditorProvider` quando um comando tem `shouldPersist = true`. Usa um
// temporary directory isolado via `IOOverrides` para never escrever no
// repository.
import 'dart:io';

import 'package:lazy_forge/src/components/editor/models/schema_model.dart';
import 'package:lazy_forge/src/components/editor/providers/editor_provider.dart';
import 'package:lazy_forge/src/services/storage/project_storage.dart';
import 'package:lazy_forge/src/shared/models/enums.dart';
import 'package:test/test.dart';

Future<T> _withTempCwd<T>(Future<T> Function(Directory tmp) body) async {
  final tmp = Directory.systemTemp.createTempSync(
    'lazy_forge_persistence_test_',
  );
  try {
    return await IOOverrides.runZoned<Future<T>>(
      () => body(tmp),
      getCurrentDirectory: () => tmp,
    );
  } finally {
    tmp.deleteSync(recursive: true);
  }
}

void main() {
  group('F21 criar/salvar/reabrir projeto', () {
    test(
      'ProjectStorage.createProject grava o projeto no workspace local',
      () async {
        await _withTempCwd((tmp) async {
          final storage = ProjectStorage();

          final created = storage.createProject(
            'meu_proj',
            DatabaseEngine.postgres,
          );

          expect(created.name, 'meu_proj');
          final file = File(
            '${tmp.path}${Platform.pathSeparator}lazyforge_projects${Platform.pathSeparator}meu_proj.json',
          );
          expect(file.existsSync(), isTrue);
          return null;
        });
      },
    );

    test(
      'comandos com shouldPersist salvam o projeto automaticamente',
      () async {
        await _withTempCwd((tmp) async {
          ProjectStorage().createProject('auto_save', DatabaseEngine.postgres);
          final editor = EditorProvider(
            schemaState: SchemaState(),
            projectName: 'auto_save',
            projectStorage: ProjectStorage(),
          );

          editor.submitCommand('create table users');

          final reloaded = ProjectStorage().loadProject('auto_save');
          expect(reloaded.schemaState.findTableByName('users'), isNotNull);
          return null;
        });
      },
    );

    test(
      'loadProject recupera exatamente o schema salvo (round-trip)',
      () async {
        await _withTempCwd((tmp) async {
          final storage = ProjectStorage();
          final created = storage.createProject(
            'round_trip',
            DatabaseEngine.mysql,
          );
          final editor = EditorProvider(
            schemaState: created.schemaState,
            projectName: 'round_trip',
            projectStorage: storage,
          );
          editor.submitCommand(
            'create table t --autoincrement - '
            'add column t name varchar(255) as pk description(nome do item)',
          );

          final reloaded = storage.loadProject('round_trip');

          expect(reloaded.schemaState.databaseEngine, DatabaseEngine.mysql);
          final table = reloaded.schemaState.findTableByName('t')!;
          final nameCol = reloaded.schemaState.findColumnByName(table, 'name')!;
          expect(nameCol.description, 'nome do item');
          return null;
        });
      },
    );

    test(
      'listProjects lista os projetos criados, ordenados por nome',
      () async {
        await _withTempCwd((tmp) async {
          final storage = ProjectStorage();
          storage.createProject('zebra', DatabaseEngine.postgres);
          storage.createProject('alpha', DatabaseEngine.postgres);

          final summaries = storage.listProjects();

          expect(summaries.map((s) => s.name).toList(), ['alpha', 'zebra']);
          return null;
        });
      },
    );

    test('loadProject lança erro claro quando o projeto não existe', () async {
      await _withTempCwd((tmp) async {
        final storage = ProjectStorage();

        expect(
          () => storage.loadProject('inexistente'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('não encontrado'),
            ),
          ),
        );
        return null;
      });
    });

    test('createProject rejeita nome já existente', () async {
      await _withTempCwd((tmp) async {
        final storage = ProjectStorage();
        storage.createProject('dup', DatabaseEngine.postgres);

        expect(
          () => storage.createProject('dup', DatabaseEngine.postgres),
          throwsA(isA<StateError>()),
        );
        return null;
      });
    });

    test('createProject rejeita nome com caracteres inválidos', () async {
      await _withTempCwd((tmp) async {
        final storage = ProjectStorage();

        expect(
          () =>
              storage.createProject('nome inválido!', DatabaseEngine.postgres),
          throwsA(isA<FormatException>()),
        );
        return null;
      });
    });
  });
}
