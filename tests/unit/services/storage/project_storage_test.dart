// Unit tests: `ProjectStorage` validations and errors not covered in depth
// by feature tests (corrupt files, invalid names, error-tolerant listing).
import 'dart:io';

import 'package:lazy_forge/src/components/editor/models/schema_model.dart';
import 'package:lazy_forge/src/services/storage/project_storage.dart';
import 'package:lazy_forge/src/shared/models/enums.dart';
import 'package:test/test.dart';

Future<T> _withTempCwd<T>(Future<T> Function(Directory tmp) body) async {
  final tmp = Directory.systemTemp.createTempSync(
    'lazy_forge_storage_unit_test_',
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
  group('ProjectStorage — nomes de projeto', () {
    test('saveProject rejeita nome vazio', () async {
      await _withTempCwd((tmp) async {
        final storage = ProjectStorage();

        expect(
          () => storage.saveProject('   ', SchemaState()),
          throwsA(isA<FormatException>()),
        );
        return null;
      });
    });
  });

  group('ProjectStorage — listProjects', () {
    test('devolve lista vazia quando não há projetos', () async {
      await _withTempCwd((tmp) async {
        final storage = ProjectStorage();

        expect(storage.listProjects(), isEmpty);
        return null;
      });
    });

    test('ignora arquivos .json corrompidos sem lançar erro', () async {
      await _withTempCwd((tmp) async {
        final storage = ProjectStorage();
        storage.createProject('valido', DatabaseEngine.postgres);
        final badFile = File(
          '${tmp.path}${Platform.pathSeparator}lazyforge_projects${Platform.pathSeparator}corrompido.json',
        );
        badFile.writeAsStringSync('{ isso nao é json');

        final summaries = storage.listProjects();

        expect(summaries.map((s) => s.name), ['valido']);
        return null;
      });
    });

    test('ignora arquivos não-.json dentro do workspace', () async {
      await _withTempCwd((tmp) async {
        final storage = ProjectStorage();
        storage.createProject('valido', DatabaseEngine.postgres);
        final otherFile = File(
          '${tmp.path}${Platform.pathSeparator}lazyforge_projects${Platform.pathSeparator}leia_me.txt',
        );
        otherFile.writeAsStringSync('nao é um projeto');

        final summaries = storage.listProjects();

        expect(summaries.map((s) => s.name), ['valido']);
        return null;
      });
    });
  });

  group('ProjectStorage — exportDdl', () {
    test('normaliza nome de arquivo removendo ".sql" duplicado', () async {
      await _withTempCwd((tmp) async {
        final storage = ProjectStorage();
        final project = storage.createProject('p', DatabaseEngine.sqlite);

        final path = storage.exportDdl(
          'p',
          project.schemaState,
          fileName: 'saida.sql',
        );

        expect(path, endsWith('saida.sql'));
        expect(File(path).existsSync(), isTrue);
        return null;
      });
    });

    test('rejeita nome de arquivo com caracteres inválidos', () async {
      await _withTempCwd((tmp) async {
        final storage = ProjectStorage();
        final project = storage.createProject('p', DatabaseEngine.sqlite);

        expect(
          () => storage.exportDdl(
            'p',
            project.schemaState,
            fileName: 'nome inválido!',
          ),
          throwsA(isA<FormatException>()),
        );
        return null;
      });
    });
  });

  group('ProjectStorage — loadProject com payload corrompido', () {
    test('lança StateError quando o conteúdo não é um JSON de objeto', () async {
      await _withTempCwd((tmp) async {
        final storage = ProjectStorage();
        storage.createProject('corrompido', DatabaseEngine.postgres);
        final file = File(
          '${tmp.path}${Platform.pathSeparator}lazyforge_projects${Platform.pathSeparator}corrompido.json',
        );
        file.writeAsStringSync('[1, 2, 3]');

        expect(
          () => storage.loadProject('corrompido'),
          throwsA(isA<StateError>()),
        );
        return null;
      });
    });
  });
}
