// Feature tests for spec 002-fix-editor-chrome (editor chrome behavior):
// leaving the editor (Esc / q on empty input / "sair"), overlay stacking
// (Help and BD types close most-recently-opened first), and the sidebar
// soft-wrap. Runs in-process via nocterm_test with key/behavior assertions
// only; it does NOT emulate or inspect the relationship graph drawing.
// Never starts the LazyForge binary; storage is confined to a temp directory.
import 'dart:io';

import 'package:lazy_forge/src/components/editor/components/sidebar/sidebar_component.dart';
import 'package:lazy_forge/src/components/editor/editor_component.dart';
import 'package:lazy_forge/src/components/editor/models/schema_model.dart';
import 'package:lazy_forge/src/services/storage/project_storage.dart';
import 'package:nocterm/nocterm.dart';
import 'package:nocterm/nocterm_test.dart';
import 'package:test/test.dart' hide isNotEmpty, isEmpty;

const _helpMarker = 'Clique no comando para copiar no input';
const _typesMarker = 'BD TYPES';

Future<void> _withTempCwd(Future<void> Function() body) async {
  final tmp = Directory.systemTemp.createTempSync('lazy_forge_chrome_test_');
  try {
    await IOOverrides.runZoned<Future<void>>(
      body,
      getCurrentDirectory: () => tmp,
    );
  } finally {
    tmp.deleteSync(recursive: true);
  }
}

EditorComponent _editor(void Function() onExit) => EditorComponent(
  projectName: 'chrome_test',
  initialSchema: SchemaState(),
  projectStorage: ProjectStorage(),
  onExit: onExit,
);

Future<void> _tapText(NoctermTester tester, String text) async {
  final matches = tester.terminalState.findText(text);
  expect(matches, isNotEmpty, reason: 'expected "$text" on screen');
  await tester.tap(matches.first.x + 1, matches.first.y);
  await tester.pump();
}

void main() {
  group('F25 leave the editor (Esc / q / sair)', () {
    test('Esc on a clean editor calls onExit once', () async {
      await _withTempCwd(() async {
        var exits = 0;
        await testNocterm('esc exits', (tester) async {
          await tester.pumpComponent(_editor(() => exits++));
          await tester.sendEscape();
          expect(exits, 1);
        }, size: const Size(120, 40));
      });
    });

    test('q on an empty input calls onExit', () async {
      await _withTempCwd(() async {
        var exits = 0;
        await testNocterm('q exits', (tester) async {
          await tester.pumpComponent(_editor(() => exits++));
          await tester.enterText('q');
          expect(exits, 1);
        }, size: const Size(120, 40));
      });
    });

    test('q with text in the input does not exit and is typed', () async {
      await _withTempCwd(() async {
        var exits = 0;
        await testNocterm('q typed', (tester) async {
          await tester.pumpComponent(_editor(() => exits++));
          await tester.enterText('create table quux');
          expect(exits, 0);
          expect(tester.terminalState, containsText('create table quux'));
        }, size: const Size(120, 40));
      });
    });

    test('Ctrl+Q does not leave the editor', () async {
      await _withTempCwd(() async {
        var exits = 0;
        await testNocterm('ctrl+q', (tester) async {
          await tester.pumpComponent(_editor(() => exits++));
          await tester.sendKeyEvent(
            KeyboardEvent(
              logicalKey: LogicalKey.keyQ,
              modifiers: const ModifierKeys(ctrl: true),
            ),
          );
          expect(exits, 0);
        }, size: const Size(120, 40));
      });
    });

    test('tapping "sair" calls onExit', () async {
      await _withTempCwd(() async {
        var exits = 0;
        await testNocterm('sair', (tester) async {
          await tester.pumpComponent(_editor(() => exits++));
          await _tapText(tester, 'sair');
          expect(exits, 1);
        }, size: const Size(120, 40));
      });
    });

    test('Esc closes an open overlay first and does not exit', () async {
      await _withTempCwd(() async {
        var exits = 0;
        await testNocterm('esc closes help', (tester) async {
          await tester.pumpComponent(_editor(() => exits++));
          await _tapText(tester, '[help]');
          expect(tester.terminalState, containsText(_helpMarker));

          await tester.sendEscape();
          expect(tester.terminalState.containsText(_helpMarker), isFalse);
          expect(exits, 0);

          await tester.sendEscape();
          expect(exits, 1);
        }, size: const Size(120, 40));
      });
    });

    test('q on empty input also closes the top overlay before exit', () async {
      await _withTempCwd(() async {
        var exits = 0;
        await testNocterm('q closes overlay', (tester) async {
          await tester.pumpComponent(_editor(() => exits++));
          await _tapText(tester, '[help]');
          await tester.enterText('q');
          expect(tester.terminalState.containsText(_helpMarker), isFalse);
          expect(exits, 0);
          await tester.enterText('q');
          expect(exits, 1);
        }, size: const Size(120, 40));
      });
    });
  });

  group('F26 overlay stacking (Help + BD types)', () {
    test(
      'Esc closes the most recently opened overlay first (types last)',
      () async {
        await _withTempCwd(() async {
          var exits = 0;
          await testNocterm('types last', (tester) async {
            await tester.pumpComponent(_editor(() => exits++));
            await _tapText(tester, '[help]');
            await _tapText(tester, 'BD types');
            expect(tester.terminalState, containsText(_helpMarker));
            expect(tester.terminalState, containsText(_typesMarker));

            await tester.sendEscape();
            expect(tester.terminalState.containsText(_typesMarker), isFalse);
            expect(tester.terminalState, containsText(_helpMarker));

            await tester.sendEscape();
            expect(tester.terminalState.containsText(_helpMarker), isFalse);
            expect(exits, 0);
          }, size: const Size(160, 50));
        });
      },
    );

    test(
      'Esc closes the most recently opened overlay first (help last)',
      () async {
        await _withTempCwd(() async {
          var exits = 0;
          await testNocterm('help last', (tester) async {
            await tester.pumpComponent(_editor(() => exits++));
            await _tapText(tester, 'BD types');
            await _tapText(tester, '[help]');

            await tester.sendEscape();
            expect(tester.terminalState.containsText(_helpMarker), isFalse);
            expect(tester.terminalState, containsText(_typesMarker));

            await tester.sendEscape();
            expect(tester.terminalState.containsText(_typesMarker), isFalse);
            expect(exits, 0);
          }, size: const Size(160, 50));
        });
      },
    );

    test('tapping the [help] toggle twice closes the Help panel', () async {
      await _withTempCwd(() async {
        await testNocterm('toggle help', (tester) async {
          await tester.pumpComponent(_editor(() {}));
          await _tapText(tester, '[help]');
          expect(tester.terminalState, containsText(_helpMarker));
          await _tapText(tester, '[help]');
          expect(tester.terminalState.containsText(_helpMarker), isFalse);
        }, size: const Size(120, 40));
      });
    });

    test('BD types panel lists the engine and allowed types', () async {
      await _withTempCwd(() async {
        await testNocterm('types content', (tester) async {
          await tester.pumpComponent(_editor(() {}));
          await _tapText(tester, 'BD types');
          expect(tester.terminalState, containsText('DB: postgres'));
          expect(tester.terminalState, containsText('Esc fecha'));
        }, size: const Size(120, 40));
      });
    });
  });

  group('F27 sidebar soft-wrap', () {
    test(
      'long column rows wrap inside the sidebar width, nothing is cut',
      () async {
        final schema = SchemaState()
          ..addTable('users')
          ..addColumn('users', 'id', 'integer');
        schema.addColumn(
          'users',
          'bio',
          'text',
          description: 'alpha bravo charlie delta echo foxtrot golf hotel',
        );
        await testNocterm('sidebar wrap', (tester) async {
          await tester.pumpComponent(
            SizedBox(width: 24, child: SidebarComponent(schemas: schema)),
          );
          final text = tester.terminalState.getText();
          expect(text, contains('+ users'));
          // The tail of the description must still be visible (wrapped).
          expect(text, contains('hotel'));
          expect(text, contains('alpha'));
        }, size: const Size(40, 20));
      },
    );
  });
}
