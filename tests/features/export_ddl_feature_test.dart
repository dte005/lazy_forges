// Testes de funcionalidade: exportação do DDL SQL para cada engine. Usa um
// diretório temporário isolado via `IOOverrides` para nunca escrever no
// repositório.
import 'dart:io';

import 'package:lazy_forge/src/components/editor/models/schema_model.dart';
import 'package:lazy_forge/src/components/editor/providers/editor_provider.dart';
import 'package:lazy_forge/src/services/storage/project_storage.dart';
import 'package:test/test.dart';

/// Roda [body] com `Directory.current` apontando para um diretório temporário
/// isolado, garantindo que nada seja escrito no repositório real.
Future<T> _withTempCwd<T>(Future<T> Function(Directory tmp) body) async {
  final tmp = Directory.systemTemp.createTempSync('lazy_forge_export_test_');
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
  group('F19 export do DDL', () {
    test('exporta DDL com nome padrão (nome do projeto) em postgres', () async {
      await _withTempCwd((tmp) async {
        final editor = EditorProvider(
          schemaState: SchemaState(),
          projectName: 'meu_projeto',
          projectStorage: ProjectStorage(),
        );
        editor.submitCommand(
          'create table users --autoincrement - '
          'add column users name varchar(255)',
        );

        editor.submitCommand('export');

        expect(editor.lastCommandFailed, isFalse);
        final exported = File(
          '${tmp.path}${Platform.pathSeparator}meu_projeto.sql',
        );
        expect(exported.existsSync(), isTrue);
        final content = exported.readAsStringSync();
        expect(content, contains('CREATE TABLE users'));
        expect(content, contains('Database: postgres'));
        return null;
      });
    });

    test('exporta DDL com nome de arquivo customizado', () async {
      await _withTempCwd((tmp) async {
        final editor = EditorProvider(
          schemaState: SchemaState(),
          projectName: 'meu_projeto',
          projectStorage: ProjectStorage(),
        );
        editor.submitCommand('create table t');

        editor.submitCommand('export saida_customizada.sql');

        final exported = File(
          '${tmp.path}${Platform.pathSeparator}saida_customizada.sql',
        );
        expect(exported.existsSync(), isTrue);
        return null;
      });
    });

    test('DDL muda de acordo com a engine selecionada (mysql)', () async {
      await _withTempCwd((tmp) async {
        final editor = EditorProvider(
          schemaState: SchemaState(),
          projectName: 'proj_mysql',
          projectStorage: ProjectStorage(),
        );
        editor.submitCommand('set database mysql');
        editor.submitCommand('create table t - add column t amount int');

        editor.submitCommand('export');

        final exported = File(
          '${tmp.path}${Platform.pathSeparator}proj_mysql.sql',
        );
        final content = exported.readAsStringSync();
        expect(content, contains('Database: mysql'));
        expect(content, contains('amount INT'));
        return null;
      });
    });

    test('rejeita nome de arquivo inválido com mensagem clara', () async {
      await _withTempCwd((tmp) async {
        final editor = EditorProvider(
          schemaState: SchemaState(),
          projectName: 'proj',
          projectStorage: ProjectStorage(),
        );
        editor.submitCommand('create table t');

        editor.submitCommand('export "arquivo inválido!"');

        expect(editor.lastCommandFailed, isTrue);
        return null;
      });
    });
  });
}
