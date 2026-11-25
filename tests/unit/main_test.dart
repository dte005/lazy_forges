// Unit tests for LazyForgeApp (lib/src/main.dart): the `_exitEditor` callback
// returns from the editor to the entry menu. Uses a temp cwd via IOOverrides
// so ProjectStorage never touches the repository.
import 'dart:io';

import 'package:lazy_forge/src/main.dart';
import 'package:lazy_forge/src/services/storage/project_storage.dart';
import 'package:lazy_forge/src/shared/models/enums.dart';
import 'package:nocterm/nocterm.dart';
import 'package:nocterm/nocterm_test.dart';
import 'package:test/test.dart' hide isNotEmpty, isEmpty;

void main() {
  group('LazyForgeApp navigation', () {
    test('Enter opens the editor and Esc returns to the entry menu', () async {
      final tmp = Directory.systemTemp.createTempSync('lazy_forge_app_test_');
      try {
        await IOOverrides.runZoned<Future<void>>(() async {
          ProjectStorage().createProject('demo', DatabaseEngine.postgres);
          await testNocterm('app navigation', (tester) async {
            await tester.pumpComponent(const LazyForgeApp());
            expect(tester.terminalState, containsText('Projetos salvos'));
            expect(tester.terminalState, containsText('demo'));

            await tester.sendEnter();
            expect(tester.terminalState, containsText('[demo'));
            expect(tester.terminalState, containsText('sair'));
            expect(
              tester.terminalState.containsText('Projetos salvos'),
              isFalse,
            );

            await tester.sendEscape();
            expect(tester.terminalState, containsText('Projetos salvos'));
          }, size: const Size(120, 40));
        }, getCurrentDirectory: () => tmp);
      } finally {
        tmp.deleteSync(recursive: true);
      }
    });

    test('tapping "sair" in the editor returns to the entry menu', () async {
      final tmp = Directory.systemTemp.createTempSync('lazy_forge_app_test_');
      try {
        await IOOverrides.runZoned<Future<void>>(() async {
          ProjectStorage().createProject('demo', DatabaseEngine.sqlite);
          await testNocterm('sair navigation', (tester) async {
            await tester.pumpComponent(const LazyForgeApp());
            await tester.sendEnter();
            final sair = tester.terminalState.findText('sair').first;
            await tester.tap(sair.x + 1, sair.y);
            await tester.pump();
            expect(tester.terminalState, containsText('Projetos salvos'));
          }, size: const Size(120, 40));
        }, getCurrentDirectory: () => tmp);
      } finally {
        tmp.deleteSync(recursive: true);
      }
    });
  });
}
