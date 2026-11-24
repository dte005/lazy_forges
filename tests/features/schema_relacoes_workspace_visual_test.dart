// Loads the workspace project schema_relacoes (or equivalent JSON) and paints
// TableGraphLayoutComponent in-process to analyze relationship graph behavior.
//
// This file is for maintainer-authorized graphical observation of a populated
// schema. Default suite may run it as a normal test (no binary, no repo junk).
import 'dart:convert';
import 'dart:io';

import 'package:lazy_forge/src/components/editor/components/table/table_component.dart';
import 'package:lazy_forge/src/components/editor/models/schema_model.dart';
import 'package:nocterm/nocterm.dart';
import 'package:nocterm/nocterm_test.dart';
import 'package:test/test.dart' hide isNotEmpty;

/// Sibling workspace used for real LazyForge sessions (outside the git repo).
final Directory _workspaceRoot = Directory(
  '${Directory.current.path}${Platform.pathSeparator}..'
  '${Platform.pathSeparator}dbs_schema_lazyforges',
);

File get _projectFile => File(
  '${_workspaceRoot.path}${Platform.pathSeparator}lazyforge_projects'
  '${Platform.pathSeparator}schema_relacoes.json',
);

SchemaState _loadSchemaRelacoes() {
  expect(
    _projectFile.existsSync(),
    isTrue,
    reason: 'expected ${_projectFile.path} — populate dbs_schema_lazyforges first',
  );
  final raw = jsonDecode(_projectFile.readAsStringSync());
  expect(raw, isA<Map>());
  final map = Map<String, dynamic>.from(raw as Map);
  final schemaMap = Map<String, dynamic>.from(map['schema'] as Map);
  return SchemaState.fromJson(schemaMap);
}

void main() {
  group('workspace schema_relacoes — graph visual analysis', () {
    test('project has at least 12 tables and dense FK graph', () {
      final schema = _loadSchemaRelacoes();
      expect(schema.tables.length, greaterThanOrEqualTo(12));

      var fkCount = 0;
      for (final t in schema.tables) {
        fkCount += t.foreignKeys.length;
      }
      expect(fkCount, greaterThanOrEqualTo(12));
    });

    test('nocterm paint: all table names and line art visible', () async {
      final schema = _loadSchemaRelacoes();

      await testNocterm(
        'schema_relacoes graph',
        (tester) async {
          await tester.pumpComponent(
            TableGraphLayoutComponent(schemaState: schema),
          );
          await tester.pump();

          final state = tester.terminalState;
          final text = state.getText();
          final snapshot = tester.toSnapshot();

          for (final table in schema.tables) {
            expect(
              state,
              containsText(table.name),
              reason: 'table ${table.name} should appear on canvas',
            );
          }

          // FK columns that drive relationships should show in boxes.
          expect(state, containsText('user_id'));
          expect(state, containsText('order_id'));
          expect(state, containsText('product_id'));
          expect(state, containsText('category_id'));
          expect(state, containsText('warehouse_id'));
          expect(state, containsText('supplier_id'));

          final hasLineArt =
              text.contains('-') ||
              text.contains('|') ||
              text.contains('+') ||
              text.contains('>') ||
              text.contains('<') ||
              text.contains('^') ||
              text.contains('v');
          expect(hasLineArt, isTrue);
          expect(snapshot, isNotEmpty);

          // Print canvas for authorized visual review (agent/maintainer).
          // ignore: avoid_print
          print('\n=== schema_relacoes graph canvas ===\n');
          // ignore: avoid_print
          print(tester.renderToString());
        },
        // Dense multi-row graph needs a large virtual terminal so table boxes
        // are not clipped off-canvas during visual inspection.
        size: const Size(220, 80),
      );
    });
  });
}
