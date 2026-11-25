// Feature tests for the entry menu (InitComponent) exit controls from spec
// 002-fix-editor-chrome: Esc/q quit only in browse mode; never while typing a
// project name. In tests there is no real TerminalBinding, so `shutdownApp()`
// surfaces as an error thrown from the key handler; that is the observable
// signal for "quit requested". Storage is confined to a temp directory.
import 'dart:io';

import 'package:lazy_forge/src/components/init/components/init_component.dart';
import 'package:lazy_forge/src/services/storage/project_storage.dart';
import 'package:nocterm/nocterm.dart';
import 'package:nocterm/nocterm_test.dart';
import 'package:test/test.dart' hide isNotEmpty, isEmpty;

Future<void> _withTempCwd(Future<void> Function() body) async {
  final tmp = Directory.systemTemp.createTempSync('lazy_forge_init_test_');
  try {
    await IOOverrides.runZoned<Future<void>>(
      body,
      getCurrentDirectory: () => tmp,
    );
  } finally {
    tmp.deleteSync(recursive: true);
  }
}

InitComponent _init() =>
    InitComponent(onSelect: (_) {}, projectStorage: ProjectStorage());

void main() {
  group('F28 init screen quit controls', () {
    test('browse mode shows the Esc/q quit hint and control', () async {
      await _withTempCwd(() async {
        await testNocterm('quit hint', (tester) async {
          await tester.pumpComponent(_init());
          expect(tester.terminalState, containsText('Esc/q: sair'));
          expect(tester.terminalState, containsText('[ Esc/q: sair ]'));
        }, size: const Size(120, 40));
      });
    });

    test('q in browse mode requests shutdown', () async {
      await _withTempCwd(() async {
        await testNocterm('q quits', (tester) async {
          await tester.pumpComponent(_init());
          // No TerminalBinding exists in-process: shutdownApp() throws.
          await expectLater(tester.enterText('q'), throwsA(anything));
        }, size: const Size(120, 40));
      });
    });

    test('Esc in browse mode requests shutdown', () async {
      await _withTempCwd(() async {
        await testNocterm('esc quits', (tester) async {
          await tester.pumpComponent(_init());
          await expectLater(tester.sendEscape(), throwsA(anything));
        }, size: const Size(120, 40));
      });
    });

    test('q while typing a project name does not quit and is typed', () async {
      await _withTempCwd(() async {
        await testNocterm('q typed in create', (tester) async {
          await tester.pumpComponent(_init());
          await tester.enterText('n');
          expect(tester.terminalState, containsText('Novo projeto'));
          await tester.enterText('quiz');
          expect(tester.terminalState, containsText('quiz'));
          expect(tester.terminalState, containsText('Novo projeto'));
        }, size: const Size(120, 40));
      });
    });

    test('Esc in create mode cancels creation instead of quitting', () async {
      await _withTempCwd(() async {
        await testNocterm('esc cancels create', (tester) async {
          await tester.pumpComponent(_init());
          await tester.enterText('n');
          await tester.sendEscape();
          expect(tester.terminalState, containsText('Criação cancelada.'));
        }, size: const Size(120, 40));
      });
    });
  });
}
