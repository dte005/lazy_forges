// In-process graphical emulation of the schema relationship graph via
// nocterm_test (no real terminal window, no LazyForge binary).
//
// Gated by project policy: run/extend for significant graphical changes only
// with express maintainer approval; observe relationship drawing only with
// explicit terminal authorization. See .github/copilot-instructions.md.
import 'package:lazy_forge/src/components/editor/components/table/table_component.dart';
import 'package:lazy_forge/src/components/editor/models/schema_model.dart';
import 'package:nocterm/nocterm.dart';
import 'package:nocterm/nocterm_test.dart';
import 'package:test/test.dart' hide isNotEmpty;

/// Builds a multi-table schema with FKs suitable for visual graph checks.
SchemaState _schemaWithRelationships() {
  final schema = SchemaState();

  schema.addTable('users');
  schema.addColumn('users', 'id', 'integer');
  schema.addColumn('users', 'name', 'text');
  schema.setPrimaryKey('users', 'id');

  schema.addTable('orders');
  schema.addColumn('orders', 'id', 'integer');
  schema.addColumn('orders', 'user_id', 'integer');
  schema.setPrimaryKey('orders', 'id');
  schema.addForeignKey('orders', 'user_id', 'users', 'id');

  schema.addTable('items');
  schema.addColumn('items', 'id', 'integer');
  schema.addColumn('items', 'order_id', 'integer');
  schema.setPrimaryKey('items', 'id');
  schema.addForeignKey('items', 'order_id', 'orders', 'id');

  schema.addTable('tags');
  schema.addColumn('tags', 'id', 'integer');
  schema.setPrimaryKey('tags', 'id');

  return schema;
}

void main() {
  group('F-graph nocterm visual — TableGraphLayoutComponent', () {
    test('empty schema shows Portuguese empty message on canvas', () async {
      await testNocterm(
        'empty graph message',
        (tester) async {
          await tester.pumpComponent(
            TableGraphLayoutComponent(schemaState: SchemaState()),
          );

          expect(
            tester.terminalState,
            containsText('Nenhuma tabela no schema.'),
          );
        },
        size: const Size(60, 20),
      );
    });

    test(
      'renders table names and relation line characters for multi-FK schema',
      () async {
        await testNocterm(
          'relationship graph paint',
          (tester) async {
            final schema = _schemaWithRelationships();

            await tester.pumpComponent(
              TableGraphLayoutComponent(schemaState: schema),
            );
            // Stateless graph paint: a single pump is enough. pumpAndSettle can
            // hit max iterations if the binding keeps scheduling frames.
            await tester.pump();

            final state = tester.terminalState;
            final text = state.getText();
            final snapshot = tester.toSnapshot();

            // Tables appear as labeled boxes on the canvas.
            expect(state, containsText('users'));
            expect(state, containsText('orders'));
            expect(state, containsText('items'));
            expect(state, containsText('tags'));

            // Columns used in FKs should be visible in box bodies.
            expect(state, containsText('user_id'));
            expect(state, containsText('order_id'));

            // Relationship drawing uses ASCII segments / arrow tips.
            final hasLineArt =
                text.contains('-') ||
                text.contains('|') ||
                text.contains('+') ||
                text.contains('>') ||
                text.contains('<') ||
                text.contains('^') ||
                text.contains('v');
            expect(
              hasLineArt,
              isTrue,
              reason: 'expected relationship line art on the canvas',
            );

            // Snapshot is non-empty and stable enough for agent inspection.
            expect(snapshot, isNotEmpty);

            // Optional debug dump for authorized visual review sessions:
            // print(tester.renderToString());
          },
          // Wide canvas so multi-column graph layout is not clipped away.
          size: const Size(120, 40),
        );
      },
    );

    test(
      'bypass FK (a→c with b in between) still paints without empty canvas',
      () async {
        await testNocterm(
          'bypass relationship paint',
          (tester) async {
            final schema = SchemaState();
            for (final name in ['a', 'b', 'c']) {
              schema.addTable(name);
              schema.addColumn(name, 'id', 'integer');
              schema.setPrimaryKey(name, 'id');
            }
            schema.addColumn('a', 'c_id', 'integer');
            schema.addForeignKey('a', 'c_id', 'c', 'id');

            await tester.pumpComponent(
              TableGraphLayoutComponent(schemaState: schema),
            );
            await tester.pump();

            final state = tester.terminalState;
            expect(state, containsText('a'));
            expect(state, containsText('b'));
            expect(state, containsText('c'));
            expect(tester.toSnapshot(), isNotEmpty);
          },
          size: const Size(100, 30),
        );
      },
    );
  });
}
