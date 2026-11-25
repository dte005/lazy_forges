// In-process graphical emulation (nocterm_test) of the editor chrome for spec
// 002-fix-editor-chrome: scrollbars, horizontal indicator, opaque overlays.
// Authorized by the maintainer for this change. Never starts the LazyForge
// binary; storage is confined to a temp directory.
import 'dart:io';

import 'package:lazy_forge/src/components/editor/editor_component.dart';
import 'package:lazy_forge/src/components/editor/models/schema_model.dart';
import 'package:lazy_forge/src/services/storage/project_storage.dart';
import 'package:nocterm/nocterm.dart';
import 'package:nocterm/nocterm_test.dart';
import 'package:test/test.dart' hide isNotEmpty, isEmpty;

Future<void> _withTempCwd(Future<void> Function() body) async {
  final tmp = Directory.systemTemp.createTempSync('lazy_forge_visual_test_');
  try {
    await IOOverrides.runZoned<Future<void>>(
      body,
      getCurrentDirectory: () => tmp,
    );
  } finally {
    tmp.deleteSync(recursive: true);
  }
}

SchemaState _denseSchema() {
  final schema = SchemaState();
  for (var i = 0; i < 14; i++) {
    final t = 'table_number_$i';
    schema.addTable(t);
    schema.addColumn(t, 'id', 'integer');
    schema.setPrimaryKey(t, 'id');
    for (var c = 0; c < 6; c++) {
      schema.addColumn(t, 'some_long_column_name_$c', 'text');
    }
    if (i > 0) {
      schema.addColumn(t, 'parent_id', 'integer');
      schema.addForeignKey(t, 'parent_id', 'table_number_${i - 1}', 'id');
    }
  }
  return schema;
}

SchemaState _smallSchema() {
  final schema = SchemaState();
  schema.addTable('users');
  schema.addColumn('users', 'id', 'integer');
  schema.setPrimaryKey('users', 'id');
  return schema;
}

EditorComponent _editor(SchemaState schema) => EditorComponent(
  projectName: 'visual',
  initialSchema: schema,
  projectStorage: ProjectStorage(),
  onExit: () {},
);

SchemaState _wideSchema() {
  final schema = SchemaState();
  for (var i = 0; i < 3; i++) {
    final t = 'wide_$i';
    schema.addTable(t);
    schema.addColumn(t, 'id', 'integer');
    schema.setPrimaryKey(t, 'id');
    schema.addColumn(t, 'c' * 150, 'text');
  }
  schema.addColumn('wide_1', 'p', 'integer');
  schema.addForeignKey('wide_1', 'p', 'wide_0', 'id');
  return schema;
}

Future<void> _ctrlRight(NoctermTester tester) async {
  await tester.sendKeyEvent(
    KeyboardEvent(
      logicalKey: LogicalKey.arrowRight,
      modifiers: const ModifierKeys(ctrl: true),
    ),
  );
  await tester.pump();
}

Future<void> _tapText(NoctermTester tester, String text) async {
  final m = tester.terminalState.findText(text);
  expect(m, isNotEmpty, reason: 'expected "$text" on screen');
  await tester.tap(m.first.x + 1, m.first.y);
  await tester.pump();
}

int _count(String text, String ch) => ch.allMatches(text).length;

void main() {
  test(
    'vertical scrollbars show on overflow and hide on a small schema',
    () async {
      await _withTempCwd(() async {
        await testNocterm('vertical bars', (tester) async {
          await tester.pumpComponent(_editor(_denseSchema()));
          await tester.pump();
          await tester.pump();
          // One scrollbar for the sidebar and one for the graph canvas.
          expect(_count(tester.terminalState.getText(), '▲'), 2);
        }, size: const Size(110, 34));
        await testNocterm('small schema', (tester) async {
          await tester.pumpComponent(_editor(_smallSchema()));
          await tester.pump();
          await tester.pump();
          expect(tester.terminalState.getText().contains('▲'), isFalse);
          expect(tester.terminalState.getText().contains('◄'), isFalse);
        }, size: const Size(110, 34));
      });
    },
  );

  test(
    'horizontal indicator shows only on overflow and follows scroll',
    () async {
      await _withTempCwd(() async {
        await testNocterm('wide', (tester) async {
          await tester.pumpComponent(_editor(_wideSchema()));
          await tester.pump();
          await tester.pump();
          String bar() => tester.terminalState
              .getText()
              .split('\n')
              .firstWhere((l) => l.contains('◄'));
          final before = bar();
          expect(before.contains('►'), isTrue);
          expect(before.indexOf('▬'), lessThan(before.indexOf('░')));
          for (var i = 0; i < 12; i++) {
            await _ctrlRight(tester);
          }
          final after = bar();
          expect(after.indexOf('░'), lessThan(after.indexOf('▬')));
        }, size: const Size(110, 34));
      });
    },
  );

  test('overlays are opaque and close most recent first', () async {
    await _withTempCwd(() async {
      await testNocterm('overlays', (tester) async {
        await tester.pumpComponent(_editor(_denseSchema()));
        await tester.pump();
        await tester.pump();
        await _tapText(tester, '[help]');
        await _tapText(tester, 'BD types');
        final text = tester.terminalState.getText();
        expect(text.contains('BD TYPES'), isTrue);
        // No graph or sidebar text bleeds inside the Help panel rows.
        final row = text
            .split('\n')
            .firstWhere((l) => l.contains('show tables'));
        final right = row.lastIndexOf('║');
        final inner = row.substring(row.lastIndexOf('║', right - 1) + 1, right);
        expect(inner.trim(), 'show tables');

        await tester.sendEscape();
        final afterEsc = tester.terminalState.getText();
        expect(afterEsc.contains('BD TYPES'), isFalse);
        expect(afterEsc.contains('show tables'), isTrue);
        await tester.sendEscape();
        expect(tester.terminalState.getText().contains('show tables'), isFalse);
      }, size: const Size(110, 34));
    });
  });
}
