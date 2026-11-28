# LazyForge

[![pub package](https://img.shields.io/pub/v/lazy_forge.svg)](https://pub.dev/packages/lazy_forge) ![License](https://img.shields.io/badge/license-MIT-blue.svg)

LazyForge is a terminal IDE (TUI) for SQL schema modeling with a keyboard-driven workflow, focused on editing speed, real-time visualization, and DDL export.

## Official links

- Project site: https://dte005.github.io/lazy_forges/
- Page documentation (database types): https://dte005.github.io/lazy_forges/#database-types
- Package on pub.dev: https://pub.dev/packages/lazy_forge
- Repository: https://github.com/dte005/lazy_forges

## Project media

<img src="https://raw.githubusercontent.com/dte005/lazy_forges/gh_page/assets/lazy_forge_sleep_icon.svg" alt="LazyForge — main icon" width="220" />

## Main capabilities

- Create, alter, and remove tables by command.
- Define columns with types per database engine.
- PK/FK relationships with graph visualization in the terminal.
- Engine selection (`postgres`, `mysql`, `sqlite`).
- Export schema to SQL DDL.
- Command history and productivity shortcuts in the editor.

## Installation (pub.dev)

```bash
dart pub global activate lazy_forge
# to execute
lazy_forge
```

## Local run (development)

```bash
dart pub get
dart run bin/lazy_forge.dart
```

With hot reload:

```bash
dart --enable-vm-service bin/lazy_forge.dart
```

## Releasing (maintainers)

Publishing to pub.dev is automated through GitHub Actions. Bump `version` in
`pubspec.yaml` (and `CHANGELOG.md`), merge to `master`, then push a matching tag:

```bash
git tag v1.0.2 && git push origin v1.0.2
```

The workflow fails if the tag differs from the `pubspec.yaml` version, and runs
`dart analyze` and `dart test tests` before publishing.

## Main commands

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
- `export [file_name.sql]`
- `history`
- `help`

## Canvas navigation

- Click the arrow buttons (`▲ ▼ ◄ ►`) at the ends of the scrollbars to move the graph 3 lines/columns per click. A scrollbar only appears when the graph overflows on that axis.
- Hold the right mouse button and drag over the graph to pan it (the content follows the pointer). Some terminals may not forward right-button drag events; use the keyboard then.
- `PageUp` / `PageDown` scroll the graph vertically by one page; `Left` / `Right` scroll it horizontally while the command input is empty.

## Persistence and export

- Projects are saved automatically under `./lazyforge_projects` (current working directory).
- Exported SQL files are written to the current directory.

## Supported databases

- PostgreSQL
- MySQL
- SQLite

## License

MIT.
