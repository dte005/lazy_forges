# LazyForge

[![pub package](https://img.shields.io/pub/v/lazy_forge.svg)](https://pub.dev/packages/lazy_forge)

LazyForge é uma IDE de terminal (TUI) para modelagem de schema SQL com fluxo keyboard-driven, focada em velocidade de edição, visualização em tempo real e exportação de DDL.

## Links oficiais

- Site do projeto: https://dte005.github.io/lazy_forges/
- Documentação da página (tipos de banco): https://dte005.github.io/lazy_forges/#database-types
- Pacote no pub.dev: https://pub.dev/packages/lazy_forge
- Repositório: https://github.com/dte005/lazy_forges

## Mídias do projeto

<img src="https://raw.githubusercontent.com/dte005/lazy_forges/gh_page/assets/lazy_forge_sleep_icon.svg" alt="LazyForge — ícone principal" width="220" />

- Favicon: https://raw.githubusercontent.com/dte005/lazy_forges/gh_page/assets/lazy_forge_favicon.svg
- Brand kit (PDF): https://raw.githubusercontent.com/dte005/lazy_forges/gh_page/assets/lazy_forge_brand_kit.pdf

## Principais capacidades

- Criação, alteração e remoção de tabelas por comando.
- Definição de colunas com tipos por engine de banco.
- Relacionamentos PK/FK com visualização em grafo no terminal.
- Seleção de engine (`postgres`, `mysql`, `sqlite`).
- Exportação de schema para SQL DDL.
- Histórico de comandos e atalhos de produtividade no editor.

## Instalação (pub.dev)

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

- Projetos são salvos automaticamente em `./lazyforge_projects` (diretório atual de execução).
- Arquivos SQL exportados são gravados no diretório atual.

## Bancos suportados

- PostgreSQL
- MySQL
- SQLite

## Licença

MIT.
