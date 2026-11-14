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

A **baseline (rótulo interno "v0.1") está em produção**, hoje publicada como
**1.0.1** (`pubspec.yaml`). A versão oficial de cada entrega é a do **milestone**
da issue no GitHub; `pubspec.yaml` e `CHANGELOG.md` devem seguir essa versão (pergunte
ao mantenedor antes de alterá-los). O código existente é a fonte da verdade.

O backlog de melhorias vive em **issues do GitHub** (`dte005/lazy_forges`). Cada issue
segue um template em `.github/ISSUE_TEMPLATE/` com diretivas para o agente; ao receber
`#N` ou uma URL, leia a issue com `gh issue view N` e siga o fluxo Spec Kit descrito nela.

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
├── components/
│   ├── init/components/init_component.dart   # criar/abrir projeto
│   └── editor/
│       ├── editor_component.dart             # tela do editor, atalhos, Help
│       ├── components/                       # sidebar/, table/ (grafo), vertical_divider/
│       ├── models/                           # schema_model.dart (SchemaState, TableDef,
│       │                                     # ColumnDef, DDL), editor_model, graph_model
│       └── providers/                        # commands_provider.dart (parsing e handlers),
│                                             # editor_provider.dart (histórico, encadeamento)
├── services/
│   ├── clipboard_service.dart
│   └── storage/                              # project_storage.dart (projetos JSON e export
│                                             # do DDL) e models/project_model.dart
└── shared/models/enums.dart                  # DatabaseEngine e afins
specs/                         # specs do Spec Kit
.github/ISSUE_TEMPLATE/        # templates de issue (feature, bug, refactor)
```

Esta estrutura foi reorganizada depois da constituição v1.2.0, que ainda cita
`providers/`, `model/` e `storage/` na raiz de `lib/src/`. **Vale o código.** Não mova
arquivos sem spec; a constituição deve ser emendada em seguida.

## Desenvolvimento

```bash
dart pub get
dart --enable-vm-service bin/lazy_forge.dart   # com hot reload
```

Mudanças em `build()` aplicam por hot reload; mudanças em `initState()` ou
`main()` exigem reiniciar o processo.
