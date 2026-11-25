# Test report — LazyForge

## Update — T016, spec 002-fix-editor-chrome

| Metric | Value |
| --- | --- |
| Features fully covered | 27 of 29 (93%) — F01–F26 and F28 |
| Features with partial coverage | 1 (F27 sidebar soft-wrap: wrap asserted, scrollbar not) |
| Features with no test | 1 (F29 scrollbars / opaque panels: visual only) |
| Line coverage (lib/) | **not collected** — `coverage` is not in `pubspec.yaml` nor globally activated; needs approval for `dart pub global activate coverage` (or `dart pub add dev:coverage`) |
| Tests (`dart test tests`) | 139 passing, 0 failing, 0 skipped |

New files (no `lib/`, `bin/`, `pubspec.yaml` changes):

- `tests/features/editor_chrome_feature_test.dart` — F25 (Esc / `q` on empty
  input call `onExit`; `q` with text is typed and does not exit; Ctrl+Q ignored;
  `sair` tap; Esc/`q` close overlay before exiting), F26 (Esc closes the most
  recently opened of Help / BD types, in both opening orders; `[help]` toggle;
  BD types content), F27 (sidebar soft-wrap in a 24-column box).
- `tests/features/init_quit_feature_test.dart` — F28 (Esc/`q` quit only in
  browse mode; `q` typed in create mode; Esc cancels creation).
- `tests/unit/main_test.dart` — `LazyForgeApp`: Enter opens the editor, Esc and
  `sair` return to the menu.

All use a temp dir via `IOOverrides.runZoned`; the binary was never run.
`nocterm_test` was used for key/text behavior only (explicit T016 request); no
relationship-graph drawing was emulated or inspected.

Notes / untestable in `lib` (reported, not changed):

- `shutdownApp()` in `InitComponent` depends on the global `TerminalBinding`,
  which does not exist in-process; the test can only assert that a quit was
  requested (the handler throws). A injectable quit callback would make this
  precise (suggestion for a spec).
- Scrollbar visibility and opaque panel colors (FR-001/002/004) are only
  verifiable visually; not asserted. `dart format tests` also reformats two
  pre-existing graph test files; I reverted that to keep the diff scoped.
- `dart analyze tests`: 5 `unnecessary_import` infos for
  `package:nocterm/nocterm_test.dart` (same pattern as the existing graph tests;
  the import is harmless).

The sections below are from the previous issue #2 round and are unchanged.

On-demand run of the **Dart Test Creator** agent, focused on the session that
implemented the fix for issue #2 (graph relationship lines crossing tables,
`specs/001-fix-graph-relation-lines/`). There were no tests under `tests/`
before this run (only the empty skeleton in `test/lazy_forge_test.dart`).

## Summary

| Metric | Value |
| --- | --- |
| Features covered (complete) | 24 of 24 (100%) |
| Features with partial coverage | 0 |
| Features with no test | 0 |
| Line coverage (lib/) | not collected this round — see "Open items" |
| Tests | 115 passing, 0 failing, 0 skipped |

**Post-report update**: Bug 1 described below was found by this test round and
**fixed in the same implementation session** (outside the original scope of
this test agent, but recorded here for traceability). The two tests that were
`skip` were re-enabled and now pass — see "Bugs found" for the technical detail
of the applied fix.

## Features

| ID | Feature | Status | Test file |
| --- | --- | --- | --- |
| F01 | `create table` (with/without `--autoincrement`) | Covered | `tests/features/table_commands_feature_test.dart` |
| F02 | `delete table` / `drop table` | Covered | `tests/features/table_commands_feature_test.dart` |
| F03 | `add column` (short syntax) | Covered | `tests/features/column_commands_feature_test.dart` |
| F04 | `add column ... to ...` (verbose syntax) | Covered | `tests/features/column_commands_feature_test.dart`, `tests/unit/.../commands_provider_test.dart` |
| F05 | `add columns` (batch) | Covered | `tests/features/column_commands_feature_test.dart` |
| F06 | `set pk` | Covered | `tests/features/column_commands_feature_test.dart` |
| F07 | `add fk` | Covered | `tests/features/relationship_commands_feature_test.dart` |
| F08 | `rename table` / `change table` | Covered | `tests/features/table_commands_feature_test.dart` |
| F09 | `rename column` / `change column` | Covered | `tests/features/column_commands_feature_test.dart` |
| F10 | `alter column ... type` / `change column ... type` | Covered | `tests/features/column_commands_feature_test.dart` |
| F11 | `set database` | Covered | `tests/features/database_engine_feature_test.dart` |
| F12 | `show database` | Covered | `tests/features/database_engine_feature_test.dart` |
| F13 | `show types` | Covered | `tests/features/database_engine_feature_test.dart` |
| F14 | `show tables` | Covered | `tests/features/table_commands_feature_test.dart` |
| F15 | `history` | Covered | `tests/features/editor_history_feature_test.dart` |
| F16 | `help` | Covered | `tests/features/editor_history_feature_test.dart` |
| F17 | Command chaining with ` - ` | Covered | `tests/features/editor_history_feature_test.dart` |
| F18 | Invalid/empty command | Covered | `tests/features/editor_history_feature_test.dart` |
| F19 | `export [file.sql]` | Covered | `tests/features/export_ddl_feature_test.dart` |
| F20 | Enum columns / `options(...)` | Covered | `tests/features/column_commands_feature_test.dart` |
| F21 | Save/reopen project (`ProjectStorage`) | Covered | `tests/features/project_persistence_feature_test.dart`, `tests/unit/services/storage/project_storage_test.dart` |
| F22 | Graph layout (`GraphLayoutEngine`) | Covered | `tests/unit/.../graph_layout_test.dart` |
| F23 | Graph line routing (`GraphRoutingEngine`, issue #2) | Covered | `tests/unit/.../graph_routing_test.dart` |
| F24 | `SchemaState`/`TableDef`/`ColumnDef` `toJson`/`fromJson` | Covered | `tests/unit/.../schema_model_test.dart` |

Full inventory (with source for each item) in `tests/features/FEATURES.md`.

## Files with lowest line coverage

Line % could not be measured this round (see "Open items"). Based on manual
code reading and the tests written, the files with branches hardest to reach
via public tests are:

1. `lib/src/components/editor/components/table/table_component.dart` — UI
   component (`nocterm`) that only consumes `GraphLayoutEngine` and
   `GraphRoutingEngine` to draw; not tested directly (see "Open items").
2. `lib/src/components/editor/components/table/graph_routing.dart` — most
   classification branches (`_EdgeKind`) are exercised, but the "bypass"
   branch with multiple simultaneous relationships on margin corridors
   (`marginCorridors`, lane > 1) was not tested in depth beyond the basic case.
3. `lib/src/components/init/components/init_component.dart` and
   `lib/src/components/editor/editor_component.dart` — `nocterm` screens, not
   exercised (see "Open items").
4. `lib/src/services/clipboard_service.dart` — not read/tested this round
   (out of scope for this session; no user command mapped in the README).
5. `lib/src/main.dart` — entry point, not tested (see "Skipped").

## Created / Updated / Skipped

### Created

- `tests/features/FEATURES.md` — feature inventory.
- `tests/features/table_commands_feature_test.dart`
- `tests/features/column_commands_feature_test.dart`
- `tests/features/relationship_commands_feature_test.dart`
- `tests/features/database_engine_feature_test.dart`
- `tests/features/editor_history_feature_test.dart`
- `tests/features/export_ddl_feature_test.dart`
- `tests/features/project_persistence_feature_test.dart`
- `tests/unit/components/editor/models/schema_model_test.dart`
- `tests/unit/components/editor/providers/commands_provider_test.dart`
- `tests/unit/components/editor/components/table/graph_layout_test.dart`
- `tests/unit/components/editor/components/table/graph_routing_test.dart`
- `tests/unit/services/storage/project_storage_test.dart`
- `tests/REPORT.md` (this file)

### Updated

No pre-existing tests under `tests/` (there were none). No files under
`lib/`, `bin/`, or `pubspec.yaml` were changed.

### Skipped (no test generated for)

- `test/lazy_forge_test.dart` — pre-existing empty skeleton, outside the
  scope of `tests/`. **Was neither deleted nor expanded**, per agent
  instruction. Question for the user: can it be removed?
- `lib/lazy_forge.dart` — public barrel, no logic of its own.
- `lib/src/main.dart` — entry point (`main()`), builds the `nocterm` tree and
  calls `runApp`; no isolatable behavior without starting the real TUI.
- `lib/src/components/editor/components/table/components/table_box.dart`,
  `lib/src/components/editor/components/sidebar/sidebar_component.dart`,
  `lib/src/components/editor/components/vertical_divider/vertical_divider_component.dart`,
  `lib/src/components/editor/editor_component.dart`,
  `lib/src/components/init/components/init_component.dart` — `nocterm`
  rendering/screen components. Screen flows were not feasible to test this
  round (see "Open items").
- `lib/src/services/clipboard_service.dart` — out of scope for the current
  session (not touched by the issue #2 fix) and no user command mapped in the
  README to drive a feature test; left untested to avoid widening this round's
  scope too far.

## Bugs found in code (fixed after this test round)

### Bug 1 — `GraphRoutingEngine` crossed tables on same-row/column "bypass" when there were 3+ tables and the relationship skipped more than one (FIXED)

- **Where**: `lib/src/components/editor/components/table/graph_routing.dart`,
  case `_EdgeKind.sameRowBypass` / `_EdgeKind.rowSkipBypass` (same code block,
  around line ~555).
- **What happens**: for an FK between non-adjacent columns on the same row
  (e.g. tables `a`, `b`, `c` side by side, FK from `a` to `c`), the first
  outline segment is drawn **at the Y height of the source column anchor,
  across the entire row** to the side margin, before turning vertical. Because
  all tables on the same row share the same Y band, that horizontal segment
  visually passes over any intermediate table (in the example, `b`) before
  exiting to the margin — violates **FR-001** of the spec
  `specs/001-fix-graph-relation-lines/spec.md` ("a residual crossing is never
  acceptable"). The symmetric case between rows (tables stacked in the same
  column, skipping more than one row) **works correctly**, because in that case
  intermediate tables do not share the same X used by the margin.
- **How to reproduce** (tests documenting expected behavior, with `skip`
  citing this bug):
  `tests/unit/components/editor/components/table/graph_routing_test.dart`,
  group "GraphRoutingEngine.plan — issue #2 regression (do not cross tables)",
  tests "FK between non-adjacent columns on the same row routes via the
  margin, without crossing the middle table" and "no routed segment crosses a
  table that is neither source nor destination, in a graph with multiple
  tables and relationships".
- **Practical impact**: occurs in schemas with 3 or more tables drawn on the
  same graph row (or same column, after wrapping by `maxColumns`) when there
  is an FK between two that are not direct neighbors on the same row. This is
  exactly one of the central scenarios issue #2 asked to fix ("when current
  spacing... MUST increase... a residual crossing is never acceptable").
- **Applied suggestion (fix implemented in the same session)**: the
  `sameRowBypass`/`rowSkipBypass` case no longer exits sideways at the column
  anchor Y. Routing now always escapes first above the source table itself (a
  vertical segment to the band immediately above its row — a band that never
  contains tables, including for row 0, where that band is the top margin),
  then travels horizontally to the outer margin (outside all columns), goes
  down or up along the margin to the band above the destination row, travels
  horizontally to the destination table, and enters from above it. Because the
  band just above any row is always free and the outer margin sits outside all
  table bounds, no segment crosses intermediate tables, regardless of how many
  tables sit on the same row/column. The two tests previously marked `skip`
  were re-enabled and pass, as does a new equivalent test added for multiple
  simultaneous "bypasses" on the same row.

## Open items and decisions that need the user

1. **`coverage` dependency to measure line %**: it is not in `pubspec.yaml`
   and `coverage` is not activated globally in this environment without
   changing the project (`dart pub global list` does not list `coverage`). Per
   this run's instructions, **I did not add the dependency nor run
   `dart pub global activate coverage`** — that requires explicit user
   approval (via `dart pub add dev:coverage` or
   `dart pub global activate coverage`). Without that, the report only covers
   feature coverage.
2. **Bug found and fixed** (see section above) — same-row/column "bypass"
   routing with 3+ tables was fixed in the same session; the two affected
   tests were re-enabled (no `skip`) and pass.
3. **`test/lazy_forge_test.dart`**: pre-existing empty skeleton outside
   `tests/`. Can it be removed? I did not touch it, per agent instruction.
4. **`nocterm` screens** (key flows in the editor, Help screen, sidebar, init
   screen): not covered this round. `nocterm` exposes
   `testNocterm`/`NoctermTester` (`lib/nocterm_test.dart` in the installed
   package), but investigating and writing those screen tests would cost more
   time than budgeted for this run; left out of scope for this issue #2–focused
   round. Can be resumed on a later call of this agent, if approved.
5. **`clipboard_service.dart`**: no user command documented in the README that
   exercises it directly; left untested to avoid widening scope beyond what
   this session touched. If there is a real usage flow, say so so it can enter
   the next inventory.
