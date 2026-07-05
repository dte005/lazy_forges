# LazyForge

LazyForge é uma IDE de terminal (TUI) em Dart para modelagem de schema de banco de dados com fluxo keyboard-driven.

- Página do projeto: https://dte005.github.io/lazy_forges/#database-types
- Repositório: https://github.com/dte005/lazy_forges

## Instalação via pub.dev (após publicação)

```bash
dart pub global activate lazy_forge
lazy_forge
```

## Execução local (desenvolvimento)

```bash
dart pub get
dart run bin/lazy_forge.dart
```

Com hot reload:

```bash
dart --enable-vm-service bin/lazy_forge.dart
```

## Comandos principais

- `create table <table> [--autoincrement]`
- `delete table <table>` / `drop table <table>`
- `add column <table> <column> <type> [as pk] [options(v1|v2)] [description(text)]`
- `add columns <table> <col1 type [as pk] ...; col2 type ...>`
- `add column <column> type <type> to <table> [as pk] [options(v1|v2)] [description(text)]`
- `set pk <table> <column>`
- `add fk <table> <column> references <ref_table> <ref_column>`
- `rename table <old> to <new>`
- `rename column <table> <old> to <new>`
- `alter column <table> <column> type <new_type> [options(v1|v2)]`
- `set database <postgres|mysql|sqlite>`
- `show database`
- `show types`
- `show tables`
- `export [nome_arquivo.sql]`
- `history`
- `help`

## Persistência e export

- Projetos são salvos em `./lazyforge_projects` (diretório atual de execução).
- Export SQL é salvo no diretório atual.

## Bancos suportados

- PostgreSQL
- MySQL
- SQLite

## Licença

MIT.
