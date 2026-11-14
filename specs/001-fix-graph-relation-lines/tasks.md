---

description: "Task list for fixing graph relationship line crossing (issue #2)"
---

# Tasks: Corrigir linhas de relacionamento transpassando tabelas no grafo

**Input**: Design documents from `specs/001-fix-graph-relation-lines/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Não solicitados como critério de aceite desta correção
(constituição `.specify/memory/constitution.md`, Princípio VIII e
`.github/docs/context-tech.md`); a validação principal é manual via `quickstart.md`. A spec
(seção "Execução das Tarefas") exige, além disso, que a tarefa final (T025)
execute o subagente `test-manager-executer`, cujo resultado é informativo e
não bloqueia a entrega desta correção.

**Organization**: Tarefas agrupadas pelas User Stories do `spec.md` (US1 e
US2 são P1; US3 é P2). Conforme a seção "Execução das Tarefas" do `spec.md`,
toda tarefa de implementação MUST se apoiar na skill de Dart pertinente em
`.agents/skills/` quando houver uma equivalente; cada tarefa abaixo indica a
skill aplicável entre colchetes `(skill: ...)` quando for o caso.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependência de tarefa incompleta)
- **[Story]**: User story a que a tarefa pertence (US1, US2, US3)
- Caminhos de arquivo exatos estão incluídos em cada descrição

## Path Conventions

Projeto único em Dart. Todo o trabalho ocorre em:
- `lib/src/components/editor/components/table/graph_routing.dart` (NOVO)
- `lib/src/components/editor/components/table/table_component.dart` (existente)
- `lib/src/components/editor/components/table/graph_layout.dart` (existente, não alterado em sua API pública — só é tocado por T009/T018, e apenas se a expansão dinâmica de corredor exigir expor `rowGap`/`colGap` como parâmetros)
- `lib/src/components/editor/models/graph_model.dart` (existente, pode ganhar campos auxiliares sem quebrar o formato de `SchemaState` persistido)

---

## Phase 1: Setup

**Purpose**: Criar o esqueleto do novo módulo de roteamento antes de qualquer lógica.

- [X] T001 Criar `lib/src/components/editor/components/table/graph_routing.dart` com o cabeçalho do módulo (imports de `graph_model.dart` e `schema_model.dart`) e as classes vazias `TableObstacle`, `RoutingCorridor`, `RoutingLaneAssignment`, `RoutedEdge`, `RoutedSegment` descritas em `data-model.md` (apenas campos, sem lógica ainda) (skills: `.agents/skills/dart-use-primary-constructors/SKILL.md` para os construtores dessas classes; `.agents/skills/dart-write-documentation/SKILL.md` para documentar o módulo público)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Infraestrutura de roteamento que TODAS as user stories (US1, US2, US3) precisam antes de qualquer correção visível.

**⚠️ CRITICAL**: Nenhuma user story pode ser implementada antes desta fase.

- [X] T002 [P] Implementar função que constrói a lista de `TableObstacle` (um por tabela: `tableKey`, `x`, `y`, `width`, `height`) a partir do mapa `nodesByName` (`_TableNodeLayout`) já calculado, em `lib/src/components/editor/components/table/graph_routing.dart` (skill: `.agents/skills/dart-use-primary-constructors/SKILL.md`)
- [X] T003 [P] Implementar `RoutingCorridor`/`RoutingLaneAssignment` como estruturas internas (sem lógica de alocação ainda, só os construtores) em `lib/src/components/editor/components/table/graph_routing.dart`, garantindo que `allocatedLanes` comece vazio e `availableSpan` inicie com o `colGap`/`rowGap` atual (8 e 3, respectivamente) (skill: `.agents/skills/dart-use-primary-constructors/SKILL.md`)
- [X] T004 Implementar a nova função de decisão de lado/orientação (substitui `sourceToRight`), considerando linha (nível) E coluna relativas entre origem e destino — mesma linha → lateral; mesma coluna → vertical; diagonal → combinação lateral+vertical — em `lib/src/components/editor/components/table/graph_routing.dart` (depende de T002) (skill: `.agents/skills/dart-use-pattern-matching/SKILL.md` para o `switch`/pattern matching da decisão de orientação)
- [X] T005 Implementar o caso de auto-relacionamento (origem = destino) como um laço que sai por um lado da própria tabela e reentra por um lado adjacente, validado contra os `TableObstacle` de outras tabelas, em `lib/src/components/editor/components/table/graph_routing.dart` (depende de T004) (skill: `.agents/skills/dart-use-pattern-matching/SKILL.md`)
- [X] T006 Substituir, em `lib/src/components/editor/components/table/table_component.dart`, o cálculo inline de `sourceToRight`/`midX` (nos dois laços sobre `layout.edges`, incluindo o de cálculo de bounds do canvas) por chamadas à nova função de roteamento de `graph_routing.dart`, mantendo o restante do fluxo de desenho (`drawAt`, `drawText`, cores) intacto (depende de T004, T005)

**Checkpoint**: A partir daqui, `table_component.dart` já desenha usando o novo módulo de roteamento (ainda sem evitar obstáculos nem pistas); as user stories passam a adicionar as garantias de comportamento sobre essa base.

---

## Phase 3: User Story 1 - Ver o grafo sem linhas atravessando tabelas (Priority: P1) 🎯 MVP

**Goal**: Nenhuma linha de relacionamento passa pelo interior, borda ou texto de uma tabela que não seja origem/destino daquela relação (FR-001, SC-001).

**Independent Test**: Criar um schema com 4+ tabelas e relacionamentos cujo caminho mais curto cruzaria uma tabela intermediária; verificar visualmente que nenhuma linha atravessa o interior ou a borda de nenhuma tabela (quickstart.md Cenário 1).

### Implementation for User Story 1

- [X] T007 [US1] Implementar verificação de colisão de um segmento (horizontal ou vertical) candidato contra a lista de `TableObstacle`, excluindo a tabela de origem e a de destino da própria relação, em `lib/src/components/editor/components/table/graph_routing.dart` (depende de T002)
- [X] T008 [US1] Implementar a construção do caminho (`segments`) que desvia por corredores livres (`colGap`/`rowGap`) sempre que o segmento direto colidiria com um obstáculo, reaproveitando a decisão de lado de T004, em `lib/src/components/editor/components/table/graph_routing.dart` (depende de T004, T007) (skill: `.agents/skills/dart-use-pattern-matching/SKILL.md`)
- [X] T009 [US1] Implementar a expansão pontual de um corredor (aumentar `availableSpan` e recalcular as posições das tabelas posicionadas depois dele) quando o espaço atual não for suficiente para desviar uma linha sem cruzar tabelas — nunca aceitar cruzamento residual, conforme FR-001 ("quando o espaçamento atual entre tabelas não for suficiente para desviar uma linha, a correção MUST aumentar o espaçamento... o quanto for necessário para manter zero cruzamentos") — em `lib/src/components/editor/components/table/graph_routing.dart` e `lib/src/components/editor/components/table/table_component.dart` (depende de T008)
- [X] T010 [US1] Substituir, em `lib/src/components/editor/components/table/table_component.dart`, as chamadas diretas a `drawHorizontal`/`drawVertical` com `midX` fixo pelo desenho dos `segments` retornados pelo roteamento (T008/T009), preservando a cor de cada relação (depende de T008, T009)
- [X] T011 [US1] Validar manualmente o Cenário 1 do `quickstart.md` (schema com 4+ tabelas, relação cruzando tabela intermediária), o Cenário 5 (schema de 2 tabelas sem conflito, confirmando ausência de regressão conforme FR-006) e o Cenário 8 (desvio ao redor de uma linha inteira de tabelas) (depende de T010) (skill de apoio, se surgir erro em runtime durante a validação: `.agents/skills/dart-fix-runtime-errors/SKILL.md`)

**Checkpoint**: User Story 1 completa e testável de forma independente — nenhuma linha atravessa tabelas, e schemas simples continuam iguais a hoje.

---

## Phase 4: User Story 2 - Ver a seta de relacionamento no lugar certo (Priority: P1)

**Goal**: A seta de cada relacionamento aparece sempre adjacente ao lado da tabela de destino por onde a linha efetivamente chega (FR-002, SC-002).

**Independent Test**: Criar duas tabelas na mesma coluna do grafo (níveis diferentes) e relacioná-las; verificar que a seta aparece exatamente onde a linha encontra a tabela de destino (quickstart.md Cenário 2).

### Implementation for User Story 2

- [X] T012 [US2] Implementar o cálculo de `arrowPoint` (posição x/y e direção `up`/`down`/`left`/`right`) a partir da orientação e do ponto final do último segmento do caminho roteado (T008), cobrindo os casos mesma linha, mesma coluna e diagonal, em `lib/src/components/editor/components/table/graph_routing.dart` (depende de T008) (skill: `.agents/skills/dart-use-pattern-matching/SKILL.md`)
- [X] T013 [US2] Atualizar o desenho da seta em `lib/src/components/editor/components/table/table_component.dart` para usar `arrowPoint` (caractere `>`/`<`/`^`/`v` conforme a direção) em vez do par fixo `targetInX`/`sourceToRight ? '>' : '<'`, garantindo que a seta fique sempre adjacente ao lado correto da tabela de destino (depende de T012)
- [X] T014 [US2] Validar que o laço de auto-relacionamento (T005) também produz um `arrowPoint` correto, apontando de volta para a própria tabela, em `lib/src/components/editor/components/table/graph_routing.dart` (depende de T005, T012)
- [X] T015 [US2] Validar manualmente o Cenário 2 (tabelas na mesma coluna) e o Cenário 4 (auto-relacionamento) do `quickstart.md` (depende de T013, T014) (skill de apoio: `.agents/skills/dart-fix-runtime-errors/SKILL.md`)

**Checkpoint**: User Stories 1 e 2 completas e testáveis de forma independente — linhas não cruzam tabelas e as setas ficam sempre no lado correto, incluindo mesma coluna e auto-relacionamento.

---

## Phase 5: User Story 3 - Distinguir relacionamentos que compartilham o mesmo corredor (Priority: P2)

**Goal**: Relacionamentos que dividem o mesmo corredor de roteamento recebem pistas (offsets) próprias, visíveis lado a lado, sem se fundir em um único traço (FR-003, SC-003).

**Independent Test**: Criar um schema onde duas relações diferentes calculariam a mesma coluna/linha de roteamento; verificar que as duas linhas aparecem em pistas paralelas distintas, cada uma com sua cor (quickstart.md Cenário 3).

### Implementation for User Story 3

- [X] T016 [US3] Implementar a alocação de pistas por corredor: ao rotear uma relação que atravessaria um `RoutingCorridor` já usado por outra, atribuir o próximo `offset` livre, com "cada `edgeIndex` tendo um `offset` único" dentro do mesmo corredor e ordem de alocação seguindo a ordem de `edgeIndex` (determinística entre redesenhos), em `lib/src/components/editor/components/table/graph_routing.dart` (depende de T008) (skill: `.agents/skills/dart-use-pattern-matching/SKILL.md`)
- [X] T017 [US3] Aplicar o `offset` alocado (T016) ao deslocar o segmento correspondente do caminho roteado, de modo que relações no mesmo corredor fiquem em colunas/linhas distintas dentro do corredor, em `lib/src/components/editor/components/table/graph_routing.dart` (depende de T016)
- [X] T018 [US3] Estender a expansão de corredor (T009) para considerar o número de pistas necessárias naquele corredor (não apenas a passagem de uma única linha), aumentando `availableSpan` o suficiente para comportar todas as pistas com espaçamento legível, em `lib/src/components/editor/components/table/graph_routing.dart` (depende de T009, T016)
- [X] T019 [US3] Validar manualmente o Cenário 3 do `quickstart.md` (duas relações no mesmo corredor, pistas paralelas e cores distintas) e o Cenário 3b (múltiplas FKs entre o mesmo par de tabelas) (depende de T017, T018) (skill de apoio: `.agents/skills/dart-fix-runtime-errors/SKILL.md`)

**Checkpoint**: Todas as user stories completas e testáveis de forma independente.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validação final cobrindo desempenho, compatibilidade e limpeza, conforme FR-004, FR-005, FR-007 e Restrições do spec.

- [X] T020 [P] Validar manualmente o Cenário 6 do `quickstart.md` (abrir um projeto salvo em `lazyforge_projects/` antes desta correção e confirmar que carrega normalmente e o grafo é exibido, SC-005)
- [X] T021 [P] Validar manualmente o Cenário 7 do `quickstart.md` (schema com dezenas de tabelas e relacionamentos cruzados; confirmar que o redesenho do grafo continua perceptivelmente instantâneo após cada comando, FR-005)
- [X] T022 Remover qualquer cálculo de `sourceToRight`/`midX` remanescente e código morto em `lib/src/components/editor/components/table/table_component.dart` após a migração completa para `graph_routing.dart`
- [X] T023 Revisar `lib/src/components/editor/components/table/graph_routing.dart` e `table_component.dart` para confirmar que nenhum comando, parsing, export de DDL ou formato de persistência foi alterado (FR-008), e que o grafo continua sendo recalculado a cada comando sem nenhuma informação de layout persistida (FR-004, FR-007)
- [X] T024 Rodar análise estática e formatação sobre os arquivos alterados (`graph_routing.dart`, `table_component.dart`), apoiado pela skill `.agents/skills/dart-run-static-analysis/SKILL.md`, e corrigir qualquer apontamento antes de considerar a correção pronta (depende de T022, T023)
- [X] T025 Executar o subagente `test-manager-executer` (`.github/agents/test-manager-executer.md`), conforme exigido pela seção "Execução das Tarefas" do `spec.md`, após todas as demais tarefas estarem concluídas; o resultado (testes criados em `tests/` e relatório de cobertura) é informativo e NÃO bloqueia a entrega desta correção — consistente com a política já declarada no próprio subagente ("testes não são critério de aceite") (depende de T001-T024)

**Nota sobre T025**: a spec (`spec.md`, seção "Execução das Tarefas" e "Restrições") contém uma tensão entre "não criar nem expandir testes automatizados" e a exigência de rodar um subagente cujo propósito é justamente criar testes automatizados (ver `/speckit-analyze`, finding F1). Esta tarefa assume a leitura menos invasiva possível: T025 roda por último, não bloqueia a conclusão das demais tarefas, e qualquer teste por ela criado fica isolado em `tests/` (fora de `lib/`, `bin/` e `pubspec.yaml`). Essa contradição na spec ainda não foi resolvida pelo mantenedor e deve ser esclarecida antes da implementação.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — pode começar imediatamente.
- **Foundational (Phase 2)**: Depende do Setup — BLOQUEIA todas as user stories.
- **User Story 1 (Phase 3)**: Depende apenas do Foundational.
- **User Story 2 (Phase 4)**: Depende do Foundational; reaproveita o roteamento de caminho de T008 (US1), portanto deve seguir US1 ou ser desenvolvida em paralelo com cuidado de merge no mesmo arquivo.
- **User Story 3 (Phase 5)**: Depende do Foundational e de T008/T009 (US1).
- **Polish (Phase 6)**: Depende de todas as user stories desejadas estarem completas. Dentro do Polish, T024 (análise estática) depende de T022/T023; T025 (subagente `test-manager-executer`) depende de T001-T024 e deve ser a última tarefa executada.

### User Story Dependencies

- **US1 (P1)**: Nenhuma dependência de outra story; é o MVP.
- **US2 (P1)**: Tecnicamente depende do caminho roteado produzido em US1 (T008) para calcular `arrowPoint`, mas é testável e entregável de forma independente (a seta pode ser corrigida mesmo que a expansão dinâmica de corredor de US1 ainda não esteja completa).
- **US3 (P2)**: Depende do caminho roteado de US1 (T008) e da expansão de corredor (T009) para alocar pistas corretamente.

### Within Each User Story

- Lógica de roteamento antes da integração com o desenho (`table_component.dart`).
- Implementação antes da validação manual (quickstart).
- Story completa antes de avançar para a próxima prioridade.

### Parallel Opportunities

- T002 e T003 (Foundational) podem rodar em paralelo (estruturas de dados independentes).
- T020 e T021 (Polish) podem rodar em paralelo (cenários de validação independentes).
- Dentro de uma mesma fase, tarefas sem dependência declarada entre si e em arquivos diferentes podem ser paralelizadas; neste fix a maior parte do código se concentra em `graph_routing.dart`, então o paralelismo real é limitado — a maioria das tarefas é sequencial por tocar o mesmo arquivo.

---

## Parallel Example: Foundational Phase

```bash
# Lançar as estruturas de dados independentes da Fase 2 juntas:
Task: "Implementar TableObstacle e construção da lista de obstáculos em graph_routing.dart"
Task: "Implementar RoutingCorridor/RoutingLaneAssignment em graph_routing.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Completar Fase 1: Setup
2. Completar Fase 2: Foundational (CRÍTICO — bloqueia todas as stories)
3. Completar Fase 3: User Story 1
4. **PARAR e VALIDAR**: testar User Story 1 de forma independente (quickstart Cenário 1 e 5)
5. Este já é o MVP que resolve o sintoma mais grave da issue #2 (linhas atravessando tabelas)

### Incremental Delivery

1. Setup + Foundational → base de roteamento pronta
2. US1 → validar independentemente → já corrige o sintoma principal da issue
3. US2 → validar independentemente → corrige a seta mal posicionada
4. US3 → validar independentemente → resolve a sobreposição de relações no mesmo corredor
5. Polish → valida compatibilidade com projetos antigos e desempenho em schemas grandes, roda análise estática (T024) e, por último, o subagente `test-manager-executer` (T025)

---

## Notes

- [P] = arquivos/estruturas diferentes, sem dependência pendente
- [Story] identifica a user story de cada tarefa para rastreabilidade com o `spec.md`
- Sem tarefas de teste automatizado criadas por este fix; a única exceção é T025, que delega ao subagente `test-manager-executer` de forma informativa e não bloqueante, conforme a seção "Execução das Tarefas" do `spec.md`
- Toda tarefa de implementação com skill de Dart equivalente em `.agents/skills/` indica a skill entre parênteses; consulte o `SKILL.md` correspondente antes de implementar
- Validar cada story manualmente (quickstart.md) antes de avançar para a próxima
- Nenhuma pasta nova é criada; todo o trabalho fica em `lib/src/components/editor/components/table/` e `lib/src/components/editor/models/graph_model.dart`, conforme Restrições do spec
- **Atenção**: a tensão entre "não criar testes automatizados" (Restrições) e a exigência de T025 (ver nota após T025) é uma contradição não resolvida em `spec.md` (finding F1 do `/speckit-analyze`); recomenda-se resolvê-la antes de iniciar `/speckit-implement`
