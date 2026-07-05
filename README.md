# LazyForge

LazyForge é uma aplicação TUI (Terminal User Interface) em Dart para modelagem de schema de banco de dados direto no terminal.

A proposta é oferecer uma experiência keyboard-driven, inspirada em ferramentas como LazyGit e LazyVim: você edita estrutura de tabelas por comandos e vê o resultado em tempo real, sem depender de interface gráfica externa.

## Status do projeto

Projeto em fase inicial (protótipo funcional).

Hoje já existe:
- app TUI rodando com `nocterm`;
- navegação entre tela inicial e editor;
- estado de schema em memória (`SchemaState`, `TableDef`, `ColumnDef`);
- renderização de tabela e colunas no editor;
- atualização reativa da UI ao adicionar colunas.

Ainda em evolução:
- parser de comandos (`create table`, `add column`, `export schema`, `export erd`);
- exportação DDL SQL;
- exportação Mermaid ER diagram;
- refinamento de UX e fluxo completo de edição.

## Objetivo do MVP

- Criar/remover tabelas e colunas via comando de texto.
- Visualizar o schema em tempo real na TUI.
- Exportar o schema como SQL DDL.
- Exportar o schema como Mermaid ERD.

## Stack técnica

- Dart `^3.11.4`
- [nocterm](https://pub.dev/packages/nocterm) `^0.8.0`

## Como rodar localmente

1. Instale dependências:

```bash path=null start=null
dart pub get
```

2. Rode o app:

```bash path=null start=null
dart run bin/lazy_forge.dart
```

Para desenvolvimento com hot reload:

```bash path=null start=null
dart --enable-vm-service bin/lazy_forge.dart
```

## Controles atuais (protótipo)

Tela inicial:
- `↑` / `↓`: muda projeto selecionado
- `Enter`: entra no editor

Editor:
- `Espaço`: adiciona uma coluna de exemplo na tabela `subjects`

Saída:
- atualmente via `Ctrl + C`

## Estrutura atual do projeto

- `bin/lazy_forge.dart`: entrypoint da aplicação
- `lib/lazy_forge.dart`: barrel público
- `lib/src/main.dart`: componente raiz e troca de telas
- `lib/src/model/`: estado e modelos de schema
- `lib/src/components/`: componentes de UI (init/editor/sidebar)
- `test/lazy_forge_test.dart`: base inicial de testes

## Roadmap (curto prazo)

- Implementar parser de comandos no domínio de comandos.
- Conectar comandos ao `SchemaState`.
- Adicionar exportadores:
  - SQL DDL
  - Mermaid ERD
- Melhorar experiência de navegação e feedback de erros.

## Contribuição

Issues e sugestões são bem-vindas para evoluir o projeto.
