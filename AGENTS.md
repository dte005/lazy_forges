# LazyForge — Guia para agentes

Orientação básica para agentes que trabalham neste repositório. Em caso de conflito,
a ordem de precedência é: **código liberado > constituição
(`.specify/memory/constitution.md`) > este arquivo**. Detalhes de produto estão no
`README.md` e em `specs/`.

## O que é

LazyForge é uma IDE de terminal (TUI), operada pelo teclado, para modelar schemas
de banco relacional (PostgreSQL, MySQL e SQLite) e exportar o DDL SQL, com
visualização em grafo atualizada a cada comando. Inspirada em LazyGit e LazyVim.

- **Linguagem:** Dart (SDK ^3.11.4)
- **TUI:** [`nocterm`](https://pub.dev/packages/nocterm) (`StatefulComponent`,
  `State`, `setState`, `Focusable`, `Column`/`Row`/`Expanded`)
- **Distribuição:** pacote no pub.dev (`dart pub global activate lazy_forge`)

## Estado do projeto

A **v0.1 (baseline) está em produção** (`pubspec.yaml` em 1.0.0). O código
existente é a fonte da verdade.

- Não reescreva, reorganize nem "corrija" código liberado sem uma spec nova que
  justifique a mudança.
- Specs com status **Implemented**, **Draft** ou **Superseded** (ex.:
  `specs/002-v0-1-baseline/`) são só referência. Nunca as use como entrada para
  `/speckit.implement`.
- Só implemente specs com status **Planned**, e apenas o escopo delas.
- Lacunas conhecidas da v0.1 estão listadas na spec baseline. Não as corrija
  fora de uma spec própria.

## Estrutura real do código

```
bin/lazy_forge.dart            # entry point
lib/lazy_forge.dart            # barrel público
lib/src/
├── main.dart
├── components/                # UI (editor/, init/)
├── providers/editor/          # estado do editor e parsing dos comandos
├── model/                     # SchemaState, TableDef, ColumnDef, enums
├── storage/                   # persistência de projetos e export do DDL
└── services/                  # utilitários (ex.: clipboard)
specs/                         # specs do Spec Kit
```

Esta estrutura é a mesma da constituição (v1.2.0). Não mova arquivos sem spec.

## Regras de código

- Dart idiomático: `lib/` público, `lib/src/` privado, arquivos em `snake_case`,
  classes em `PascalCase`. Nunca crie `index.dart`.
- Use **`ColumnDef`**, nunca `Column` para o modelo de coluna (colide com o widget
  do `nocterm`).
- Parsing de comandos não vai dentro de componentes de UI; fica em
  `lib/src/providers/`.
- Simplicidade: sem abstrações "para o futuro", sem gambiarras.
- **Nunca presuma a API do `nocterm`.** Confirme no código-fonte instalado
  localmente (cache do pub) antes de usar.
- **Pergunte antes de adicionar dependência** ao `pubspec.yaml`.
- Explique o motivo da escolha de arquitetura antes de alterar
  `lib/src/model/` ou `lib/src/components/`.

## Produto e UX

- Toda funcionalidade deve resolver um problema concreto de usabilidade. Nada
  vago ou especulativo.
- Comandos previsíveis, com mensagens de erro claras e acionáveis; nunca expor
  stack trace ao usuário.
- Clareza acima de estética. A v0.1 usa o tema `dark` nativo do `nocterm`;
  gruvbox é só preferência. Mantenha o mesmo tema em todas as telas.
- Performance é requisito: nada que trave a interface, mesmo com schemas grandes.
- Teclado é o modo primário. Funcionalidade nova ou tela nova deve oferecer a
  tecla `q` para sair (sem depender só de `Ctrl+C`). A v0.1 não tem `q` (sai por
  `Esc` na tela inicial e por clique em "sair" no editor); isso é lacuna
  conhecida, a tratar em spec própria.
- Interações por clique já existentes (sair, fechar/copiar no Help) não devem
  ser removidas sem spec.

## Testes

Este projeto **não exige testes automatizados** (decisão da constituição). O
`test/` existente não deve ser expandido e não devem ser adicionadas novas
dependências de teste sem aprovação explícita. Valide por revisão e execução
manual.

## Desenvolvimento

```bash
dart pub get
dart --enable-vm-service bin/lazy_forge.dart   # com hot reload
```

Mudanças em `build()` aplicam por hot reload; mudanças em `initState()` ou
`main()` exigem reiniciar o processo.
