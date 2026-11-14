# Inventário de funcionalidades — LazyForge

Fonte: `README.md` (comandos principais) + leitura de
`lib/src/components/editor/providers/commands_provider.dart`,
`lib/src/components/editor/providers/editor_provider.dart`,
`lib/src/components/editor/models/schema_model.dart`,
`lib/src/services/storage/project_storage.dart` e
`lib/src/components/editor/components/table/graph_layout.dart` +
`graph_routing.dart`.

Status: **Coberta** (caminho feliz + erro/borda, todos passando), **Parcial**
(só um dos dois, ou teste falhando/skip), **Sem teste**.

| ID | Funcionalidade | Fonte | Arquivo de teste | Status |
| --- | --- | --- | --- | --- |
| F01 | `create table <table> [--autoincrement]` | README + código | `tests/features/table_commands_feature_test.dart` | Coberta |
| F02 | `delete table` / `drop table` | README + código | `tests/features/table_commands_feature_test.dart` | Coberta |
| F03 | `add column <table> <column> <type> [as pk] [options(...)] [description(...)]` | README + código | `tests/features/column_commands_feature_test.dart` | Coberta |
| F04 | `add column <column> type <type> to <table> ...` (sintaxe verbosa) | README + código | `tests/features/column_commands_feature_test.dart` | Coberta |
| F05 | `add columns <table> <col1 ...; col2 ...>` (lote) | README + código | `tests/features/column_commands_feature_test.dart` | Coberta |
| F06 | `set pk <table> <column>` | README + código | `tests/features/column_commands_feature_test.dart` | Coberta |
| F07 | `add fk <table> <column> references <ref_table> <ref_column>` | README + código | `tests/features/relationship_commands_feature_test.dart` | Coberta |
| F08 | `rename table <old> to <new>` / `change table` | README + código | `tests/features/table_commands_feature_test.dart` | Coberta |
| F09 | `rename column <table> <old> to <new>` / `change column` | README + código | `tests/features/column_commands_feature_test.dart` | Coberta |
| F10 | `alter column <table> <column> type <new_type>` / `change column ... type` | README + código | `tests/features/column_commands_feature_test.dart` | Coberta |
| F11 | `set database <postgres\|mysql\|sqlite>` | README + código | `tests/features/database_engine_feature_test.dart` | Coberta |
| F12 | `show database` | README + código | `tests/features/database_engine_feature_test.dart` | Coberta |
| F13 | `show types` (tipos permitidos por engine) | README + código | `tests/features/database_engine_feature_test.dart` | Coberta |
| F14 | `show tables` | README + código | `tests/features/table_commands_feature_test.dart` | Coberta |
| F15 | `history` | README + código | `tests/features/editor_history_feature_test.dart` | Coberta |
| F16 | `help` | README + código | `tests/features/editor_history_feature_test.dart` | Coberta |
| F17 | Encadeamento de comandos com ` - ` (chaining) | código (`editor_provider.dart`) | `tests/features/editor_history_feature_test.dart` | Coberta |
| F18 | Comando inválido ou vazio com mensagem clara | código | `tests/features/editor_history_feature_test.dart` | Coberta |
| F19 | `export [nome_arquivo.sql]` do DDL por engine | README + código | `tests/features/export_ddl_feature_test.dart` | Coberta |
| F20 | Colunas enum com `options(v1\|v2)` e validação | código | `tests/features/column_commands_feature_test.dart` | Coberta |
| F21 | Salvar e reabrir projeto (`ProjectStorage` + persistência automática) | README + código | `tests/features/project_persistence_feature_test.dart` | Coberta |
| F22 | Layout do grafo (agrupamento em linhas por dependência de FK) | código (`graph_layout.dart`) | `tests/unit/components/editor/components/table/graph_layout_test.dart` | Coberta |
| F23 | Roteamento das linhas de relacionamento do grafo sem cruzar tabelas | código (`graph_routing.dart`) — issue #2 | `tests/unit/components/editor/components/table/graph_routing_test.dart` | Coberta |
| F24 | `SchemaState` / `TableDef` / `ColumnDef` `toJson`/`fromJson` (round-trip) | código (`schema_model.dart`) | `tests/unit/components/editor/models/schema_model_test.dart` | Coberta |

## Observações

- F22/F23 não têm um comando de usuário dedicado; são cobertas via a API
  pública dos módulos puros (`GraphLayoutEngine`, `GraphRoutingEngine`), que é
  o comportamento visível do grafo (sem depender do `nocterm`/TUI).
- Telas do `nocterm` (fluxo de teclas na tela do editor, Help interativo) não
  foram cobertas nesta rodada — ver "Pendências" em `tests/REPORT.md`.
