# Feature inventory — LazyForge

Source: `README.md` (main commands) + reading
`lib/src/components/editor/providers/commands_provider.dart`,
`lib/src/components/editor/providers/editor_provider.dart`,
`lib/src/components/editor/models/schema_model.dart`,
`lib/src/services/storage/project_storage.dart` and
`lib/src/components/editor/components/table/graph_layout.dart` +
`graph_routing.dart`.

Status: **Covered** (happy path + error/edge, all passing), **Partial**
(only one of the two, or failing/skipped test), **No test**.

| ID | Feature | Source | Test file | Status |
| --- | --- | --- | --- | --- |
| F01 | `create table <table> [--autoincrement]` | README + code | `tests/features/table_commands_feature_test.dart` | Covered |
| F02 | `delete table` / `drop table` | README + code | `tests/features/table_commands_feature_test.dart` | Covered |
| F03 | `add column <table> <column> <type> [as pk] [options(...)] [description(...)]` | README + code | `tests/features/column_commands_feature_test.dart` | Covered |
| F04 | `add column <column> type <type> to <table> ...` (verbose syntax) | README + code | `tests/features/column_commands_feature_test.dart` | Covered |
| F05 | `add columns <table> <col1 ...; col2 ...>` (batch) | README + code | `tests/features/column_commands_feature_test.dart` | Covered |
| F06 | `set pk <table> <column>` | README + code | `tests/features/column_commands_feature_test.dart` | Covered |
| F07 | `add fk <table> <column> references <ref_table> <ref_column>` | README + code | `tests/features/relationship_commands_feature_test.dart` | Covered |
| F08 | `rename table <old> to <new>` / `change table` | README + code | `tests/features/table_commands_feature_test.dart` | Covered |
| F09 | `rename column <table> <old> to <new>` / `change column` | README + code | `tests/features/column_commands_feature_test.dart` | Covered |
| F10 | `alter column <table> <column> type <new_type>` / `change column ... type` | README + code | `tests/features/column_commands_feature_test.dart` | Covered |
| F11 | `set database <postgres\|mysql\|sqlite>` | README + code | `tests/features/database_engine_feature_test.dart` | Covered |
| F12 | `show database` | README + code | `tests/features/database_engine_feature_test.dart` | Covered |
| F13 | `show types` (allowed types per engine) | README + code | `tests/features/database_engine_feature_test.dart` | Covered |
| F14 | `show tables` | README + code | `tests/features/table_commands_feature_test.dart` | Covered |
| F15 | `history` | README + code | `tests/features/editor_history_feature_test.dart` | Covered |
| F16 | `help` | README + code | `tests/features/editor_history_feature_test.dart` | Covered |
| F17 | Command chaining with ` - ` (chaining) | code (`editor_provider.dart`) | `tests/features/editor_history_feature_test.dart` | Covered |
| F18 | Invalid or empty command with a clear message | code | `tests/features/editor_history_feature_test.dart` | Covered |
| F19 | `export [file_name.sql]` DDL per engine | README + code | `tests/features/export_ddl_feature_test.dart` | Covered |
| F20 | Enum columns with `options(v1\|v2)` and validation | code | `tests/features/column_commands_feature_test.dart` | Covered |
| F21 | Save and reopen project (`ProjectStorage` + automatic persistence) | README + code | `tests/features/project_persistence_feature_test.dart` | Covered |
| F22 | Graph layout (row grouping by FK dependency) | code (`graph_layout.dart`) | `tests/unit/components/editor/components/table/graph_layout_test.dart` | Covered |
| F23 | Graph relationship line routing without crossing tables | code (`graph_routing.dart`) — issue #2 | `tests/unit/components/editor/components/table/graph_routing_test.dart` | Covered |
| F24 | `SchemaState` / `TableDef` / `ColumnDef` `toJson`/`fromJson` (round-trip) | code (`schema_model.dart`) | `tests/unit/components/editor/models/schema_model_test.dart` | Covered |
| F25 | Leave the editor: Esc / `q` on empty input / `sair` call `onExit`; `q` with text is typed; Ctrl+Q ignored; `LazyForgeApp` returns to the menu (spec 002) | spec 002 + code (`editor_component.dart`, `main.dart`) | `tests/features/editor_chrome_feature_test.dart`, `tests/unit/main_test.dart` | Covered |
| F26 | Overlay stacking: Help and BD types open together; Esc/`q` closes the most recently opened first, then exits; `[help]` toggles (spec 002) | spec 002 + code | `tests/features/editor_chrome_feature_test.dart` | Covered |
| F27 | Sidebar soft-wrap of long rows (spec 002) | spec 002 + code (`sidebar_component.dart`) | `tests/features/editor_chrome_feature_test.dart` | Partial (wrap only; scrollbar not asserted) |
| F28 | Init menu quit: Esc/`q` quit only in browse mode, never while typing a name; Esc cancels creation (spec 002) | spec 002 + code (`init_component.dart`) | `tests/features/init_quit_feature_test.dart` | Covered |
| F29 | Graph/sidebar scrollbars and opaque overlay panels (spec 002, US1/US3) | spec 002 + code | — | No test (purely visual; graph emulation not authorized) |

## Notes

- F25–F28 use `nocterm_test` in-process (key and text behavior only, no graph
  drawing) at the maintainer's explicit request for T016. `shutdownApp()` has no
  `TerminalBinding` in-process, so F28 detects "quit requested" as an error
  thrown by the key handler.

- F22/F23 do not have a dedicated user command; they are covered via the public
  API of the pure modules (`GraphLayoutEngine`, `GraphRoutingEngine`), which is
  the visible graph behavior (without depending on `nocterm`/TUI).
- Remaining screen flows (command entry through the TextField, history arrows)
  are still not covered at the widget level — see `tests/REPORT.md`.
