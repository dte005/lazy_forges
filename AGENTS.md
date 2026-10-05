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

## Regras de código

- Dart idiomático: `lib/` público, `lib/src/` privado, arquivos em `snake_case`,
  classes em `PascalCase`. Nunca crie `index.dart`.
- Use **`ColumnDef`**, nunca `Column` para o modelo de coluna (colide com o widget
  do `nocterm`).
- Parsing de comandos não vai dentro de componentes de UI; fica em
  `lib/src/components/editor/providers/commands_provider.dart`.
- Para encerrar o app use `shutdownApp()` do `nocterm`, nunca `exit(0)` (causava
  corrupção do terminal no Mac).
- Simplicidade: sem abstrações "para o futuro", sem gambiarras.
- **Nunca presuma a API do `nocterm`.** Confirme no código-fonte instalado
  localmente (cache do pub) antes de usar.
- **Pergunte antes de adicionar dependência** ao `pubspec.yaml`.
- Explique o motivo da escolha de arquitetura antes de alterar modelos
  (`.../models/`) ou componentes (`lib/src/components/`).

## Produto e UX

- Toda funcionalidade deve resolver um problema concreto de usabilidade. Nada
  vago ou especulativo.
- Comandos previsíveis, com mensagens de erro claras e acionáveis; nunca expor
  stack trace ao usuário.
- Clareza acima de estética. A v0.1 usa o tema `dark` nativo do `nocterm`;
  gruvbox é só preferência. Mantenha o mesmo tema em todas as telas.
- Performance é requisito: nada que trave a interface, mesmo com schemas grandes.
- Teclado é o modo primário. Funcionalidade nova ou tela nova deve oferecer a
  tecla `q` para sair (sem depender só de `Ctrl+C`). A baseline não tem `q` (sai por
  `Esc` na tela inicial e por clique em "sair" no editor); isso é lacuna
  conhecida, tratada em issue própria.
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
