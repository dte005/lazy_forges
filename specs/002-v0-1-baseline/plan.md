# Implementation Plan: LazyForge 1.0.0 — Baseline (as-built) e Roadmap de Melhorias

**Branch**: `002-v0-1-baseline` | **Date**: 2026-10-04 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-v0-1-baseline/spec.md`

> **Natureza deste plan**: documentação de referência (as-built) da versão 1.0.0 já liberada, mais um
> backlog de melhorias candidatas. NÃO é instrução para recriar ou alterar código existente (Princípio VIII).
> `/speckit-tasks` e `/speckit-implement` NÃO devem ser executados sobre esta spec (status: Implemented).
> Cada melhoria escolhida vira uma spec nova (003, 004, ...) com plan e tasks próprios.

## Summary

LazyForge é uma TUI em Dart, operada principalmente pelo teclado, para modelar schemas relacionais
(PostgreSQL, MySQL e SQLite) por comandos de texto, visualizar tabelas e relacionamentos em grafo e exportar
DDL SQL. O app já está publicado (pubspec 1.0.0). Abordagem técnica atual: estado do schema em memória
(`SchemaState`), comandos interpretados por regex em um provider, projeto persistido em JSON após cada
alteração, UI em componentes `nocterm`. O trabalho futuro consiste em melhorias incrementais e isoladas, cada
uma justificada por um ganho concreto de usabilidade (Princípio I), sem quebrar projetos salvos nem
comportamento já liberado.

## Technical Context

**Language/Version**: Dart, SDK ^3.11.4

**Primary Dependencies**: `nocterm ^0.8.0` (framework de TUI); dev: `lints`, `test` (existente, não expandir)

**Storage**: arquivos JSON locais em `./lazyforge_projects/<nome>.json` (`{name, updatedAt, schema}`);
DDL exportado como `.sql` no diretório atual

**Testing**: sem suíte automatizada exigida (constituição); validação por revisão manual, verificação
funcional com hot reload e execução manual do DDL nos três bancos

**Target Platform**: terminal (Windows, macOS, Linux); distribuição via `dart pub global activate lazy_forge`

**Project Type**: aplicação CLI/TUI (pacote Dart publicado no pub.dev)

**Performance Goals**: resposta perceptivelmente instantânea a cada comando; schemas de dezenas de tabelas e
centenas de colunas sem bloqueio perceptível (Princípio IV)

**Constraints**: offline; sem conexão a bancos reais; não exigir mouse para fluxos novos; manter compatibilidade
de leitura dos JSON já salvos; nenhuma dependência nova sem aprovação

**Scale/Scope**: uso individual; um projeto = um schema = um banco alvo; ~14 arquivos `.dart` em `lib/`

## Constitution Check

*GATE: aplicado à baseline (v1.2.0 da constituição) e a cada melhoria futura.*

| Princípio | Estado na baseline | Regra para melhorias |
|---|---|---|
| I. Usabilidade | Atendido pelo fluxo de comandos | Toda melhoria declara o problema de usabilidade resolvido |
| II. Comandos previsíveis | Atendido; aliases consistentes | Nova sintaxe passa no teste "um usuário experiente adivinharia?" |
| III. Clareza | Tema `dark` nativo | Sem decoração gratuita |
| IV. Performance | Sem medição formal | Melhoria não pode degradar a resposta |
| V. Credibilidade | Erros em linguagem clara | Sem stack trace para o usuário |
| VI. Estrutura | Conforme (ver abaixo) | Respeitar as pastas reais |
| VII. Simplicidade | Conforme | Sem abstração "para o futuro"; confirmar API do nocterm no código instalado |
| VIII. Preservação | Gate ativo | Mudança de comportamento liberado exige spec nova e justificativa explícita |

Resultado: **PASS** (baseline). Lacunas conhecidas estão registradas na spec e tratadas no backlog abaixo.

## Project Structure

### Documentation (this feature)

```text
specs/002-v0-1-baseline/
├── spec.md              # Baseline as-built (Implemented, somente leitura)
├── plan.md              # Este arquivo
└── checklists/
    └── requirements.md
```

Não gerar `research.md`, `data-model.md`, `contracts/` nem `tasks.md` para a baseline: o código é a
fonte da verdade e não há trabalho a executar.

### Source Code (repository root)

```text
bin/
└── lazy_forge.dart                      # entry point: runApp com TuiTheme dark
lib/
├── lazy_forge.dart                      # barrel público (exporta src/main.dart)
└── src/
    ├── main.dart                        # app raiz: alterna tela inicial/editor
    ├── components/
    │   ├── init/init_component.dart     # criar/abrir projeto; Esc encerra
    │   └── editor/
    │       ├── editor_component.dart    # tela do editor, atalhos, Help, janela de tipos
    │       └── components/
    │           ├── sidebar/             # lista de tabelas e FKs
    │           ├── table/               # grafo: layout e caixas de tabela
    │           └── vertical_divider/
    ├── providers/
    │   └── editor/editor_provider.dart  # EditorProvider (histórico, encadeamento) e
    │                                    # CommandsProvider (regex, validações, handlers)
    ├── model/
    │   ├── schema_state.dart            # SchemaState, TableDef, ColumnDef, ForeignKeyDef,
    │   │                                # tipos por engine, geração do DDL
    │   └── enums.dart                   # DatabaseEngine
    ├── storage/project_storage.dart     # listar/criar/carregar/salvar projeto, exportDdl
    └── services/clipboard_service.dart  # copiar para a área de transferência
specs/                                   # specs do Spec Kit
```

**Structure Decision**: estrutura única de pacote Dart, já conforme a constituição v1.2.0. Responsabilidades:
interpretação de comandos em `providers/`; regras e DDL em `model/`; disco em `storage/`; apresentação em
`components/`. Nenhuma reorganização é planejada.

## Fluxo atual (as-built)

1. `init_component`: o usuário cria um projeto (nome + banco) ou abre um existente via `ProjectStorage`.
2. `editor_component`: captura o texto do comando e chama `EditorProvider.submitCommand`.
3. `EditorProvider`: trata `history` localmente; divide comandos encadeados por ` - ` e delega cada parte ao
   `CommandsProvider.handle`; para na primeira falha.
4. `CommandsProvider`: casa o comando com um regex, valida e altera o `SchemaState`, retornando
   `EditorCommandResult(success, message, shouldPersist)`.
5. Se algum comando pediu persistência, `EditorProvider` chama `ProjectStorage.saveProject`.
6. A UI redesenha sidebar e grafo a partir do `SchemaState`.

## Restrições para qualquer melhoria

- **Compatibilidade de projetos salvos**: `SchemaState.fromJson` deve continuar lendo JSON antigos; campos
  novos são opcionais com valor padrão.
- **Compatibilidade de comandos**: sintaxes e aliases existentes não mudam de significado. Novas formas são
  aditivas.
- **Persistência**: manter salvamento automático; falha de salvamento continua informada ao usuário.
- **DDL**: mudanças na saída do `toSqlDdl` precisam ser descritas como mudança de comportamento liberado e
  conferidas manualmente nos três bancos.
- **Mensagens**: erros acionáveis em português, no padrão atual.

## Backlog de melhorias candidatas (você escolhe; cada uma vira uma spec nova)

Legenda de risco: **Aditivo** = não altera comportamento liberado; **Muda comportamento** = altera algo já
liberado e exige justificativa explícita na spec.

| ID | Melhoria | Origem | Ganho de usabilidade | Arquivos principais | Risco |
|---|---|---|---|---|---|
| M01 | Tecla `q` para sair do editor (e atalhos de teclado para abrir/fechar Help e janela de tipos) | Lacuna 8 e constituição | Fluxo 100% teclado; hoje só o clique sai do editor | `editor_component.dart` | Aditivo |
| M02 | Confirmação ao sobrescrever arquivo no `export` | Lacuna 2 | Evita perda silenciosa de DDL | `project_storage.dart`, `editor_provider.dart` | Muda comportamento |
| M03 | Aviso/confirmação ao `delete table` com FKs dependentes | Lacuna 1 | Evita perda silenciosa de relacionamentos | `schema_state.dart`, `editor_provider.dart` | Muda comportamento |
| M04 | Validar tipos ao `set database` (listar conflitos, sem troca parcial) | Lacuna 3 | Evita schema inválido no novo dialeto | `editor_provider.dart`, `schema_state.dart` | Muda comportamento |
| M05 | `--autoincrement` nativo no DDL (SERIAL/IDENTITY, AUTO_INCREMENT, AUTOINCREMENT) | Lacuna 5 | DDL executável como o usuário espera | `schema_state.dart` | Muda comportamento |
| M06 | Ordenar `CREATE TABLE` por dependência de FK e citar identificadores/palavras reservadas | Lacuna 6 | DDL roda sem erro nos 3 bancos | `schema_state.dart` | Muda comportamento |
| M07 | Validar compatibilidade de tipo na criação de FK | Lacuna 4 | Evita FK que falharia no banco | `editor_provider.dart` | Muda comportamento |
| M08 | Comentário nativo de coluna (ex.: `COMMENT ON COLUMN` no PostgreSQL) | Lacuna 7 | Descrição preservada no banco | `schema_state.dart` | Muda comportamento |
| M09 | Comandos `delete column` e `delete fk` | Lacuna 9 | Corrigir erro sem apagar a tabela inteira | `editor_provider.dart`, `schema_state.dart` | Aditivo |
| M10 | Tratamento de terminal pequeno (rolagem/resumo e aviso claro) | Lacuna 10 | Evita tela quebrada | `editor_component.dart`, `table/` | Aditivo |
| M11 | Export de diagrama Mermaid ER | Fora de escopo 1.0.0 | Diagrama fora do terminal | `storage/`, `model/` | Aditivo |

### Ordem sugerida
1. **Aditivos de baixo risco**: M01, M09, M10.
2. **Qualidade do DDL (SC-002 do produto)**: M05 e M06 juntos, depois M08.
3. **Segurança de dados do usuário**: M02, M03, M04, M07.
4. **Nova funcionalidade**: M11.

### Como cada melhoria entra no Spec Kit
1. `/speckit-specify` com a descrição da melhoria (nova spec com status "Planned" e a menção "estende a
   baseline 002; não altera comportamento fora do escopo").
2. `/speckit-clarify` se houver ambiguidade.
3. `/speckit-plan` e `/speckit-tasks` para a nova spec.
4. `/speckit-analyze` antes do `/speckit-implement`.
5. Após a entrega, mudar o status da spec para "Implemented".

## Complexity Tracking

Sem violações da constituição na baseline. Nenhuma complexidade adicional é introduzida por este plan.
