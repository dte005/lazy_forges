# Implementation Plan: Corrigir linhas de relacionamento transpassando tabelas no grafo

**Branch**: `001-fix-graph-relation-lines` | **Date**: 2026-10-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-fix-graph-relation-lines/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

O grafo de relacionamentos do editor (`table_component.dart` + `graph_layout.dart`)
roteia cada linha de relacionamento sem conhecimento geométrico das outras
tabelas já posicionadas, decide o lado de saída/entrada olhando só o centro
horizontal das tabelas, e não reserva espaço próprio para relações que
compartilham o mesmo corredor. Isso causa linhas atravessando tabelas, setas
mal posicionadas e relações indistinguíveis quando próximas (issue #2).

A abordagem técnica introduz uma etapa de **roteamento consciente de
obstáculos e pistas (lanes)**, executada depois do `GraphLayoutEngine` atual e
antes do desenho em `table_component.dart`:

1. Construir, a cada renderização, a lista de retângulos ocupados por cada
   tabela já posicionada (obstáculos).
2. Para cada relação, escolher a estratégia de saída/entrada (lateral,
   vertical ou combinada) com base na posição relativa real entre origem e
   destino — linha (nível) e coluna —, não apenas no centro horizontal.
3. Alocar cada segmento de relação a uma **pista** dentro do corredor
   (colGap/rowGap) que ele atravessa; relações que dividem o mesmo corredor
   recebem posições (offsets) distintas dentro dele.
4. Se o espaço disponível em um corredor não comportar todas as pistas
   necessárias, aumentar esse corredor especificamente (recalculando as
   posições das tabelas afetadas) o quanto for preciso — nunca aceitar
   cruzamento residual.
5. Antes de desenhar, validar que nenhum segmento do caminho final cruza o
   retângulo de uma tabela que não seja a origem ou o destino daquela relação
   (incluindo o caso de auto-relacionamento, tratado como um laço que sai e
   reentra na mesma tabela por lados diferentes).

Nenhuma dependência nova é necessária; a mudança fica contida na mesma pasta
(`lib/src/components/editor/components/table/`), como um novo módulo auxiliar
de roteamento consumido por `table_component.dart`.

## Technical Context

**Language/Version**: Dart (SDK ^3.11.4, conforme `pubspec.yaml`)

**Primary Dependencies**: `nocterm` (TUI já usado pelo projeto); nenhuma
dependência nova é introduzida por esta correção.

**Storage**: N/A — o grafo é recalculado em memória a partir do `SchemaState`
a cada renderização; não há persistência de layout (FR-007). Os arquivos de
projeto em `lazyforge_projects/` continuam sendo lidos sem alteração de
formato.

**Testing**: N/A — o projeto não exige suíte de testes automatizados
(decisão da constituição); validação por revisão manual conforme
`quickstart.md`.

**Target Platform**: Terminal multiplataforma (Linux, WSL, macOS, Windows);
bug reportado em Linux/WSL, mas a correção deve valer para qualquer terminal
suportado pelo `nocterm`.

**Project Type**: Aplicação de terminal (TUI) single-project em Dart.

**Performance Goals**: Redesenho do grafo perceptivelmente instantâneo a cada
comando (referência: abaixo de ~100ms), mantendo o padrão já exigido pela
constituição (Princípio V — Velocidade Percebida como Requisito), inclusive
em schemas com dezenas de tabelas e múltiplos relacionamentos.

**Constraints**: Sem novas dependências; sem criar ou expandir testes
automatizados; sem alterar comandos, parsing, export de DDL ou persistência;
sem criar pastas fora da estrutura existente (`lib/src/components/editor/components/table/`);
schemas sem conflito de roteamento devem continuar sendo desenhados
exatamente como hoje (FR-006); garantia de zero cruzamento deve valer sempre,
mesmo que isso exija aumentar o espaçamento entre tabelas (ver Clarifications
do spec).

**Scale/Scope**: Schemas com 4 ou mais tabelas e relacionamentos cruzados
(caso mínimo de reprodução da issue) até dezenas de tabelas com múltiplos
relacionamentos concorrentes no mesmo corredor, incluindo auto-relacionamento.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação |
|---|---|
| I. Interface a Serviço da Decisão | PASS — a correção existe exatamente para que o grafo volte a comunicar o estado real do schema (linhas e setas corretas); não introduz nenhum elemento decorativo novo. |
| II. Comandos que Falam SQL | N/A — nenhum comando é criado, alterado ou removido por esta correção. |
| III. Resultado Portável, Nunca Aprisionado | N/A — não altera export de DDL nem o formato dos arquivos de projeto (FR-007, FR-008). |
| IV. Terminal do Início ao Fim | PASS — a correção é puramente visual dentro do TUI existente; não introduz interação por mouse nem depende de ferramenta externa. |
| V. Velocidade Percebida como Requisito | PASS COM ATENÇÃO — o roteamento consciente de obstáculos adiciona trabalho por relação (checar obstáculos, alocar pistas). Mantido simples (varredura linear sobre tabelas e corredores, sem busca de caminho genérica tipo A*) para preservar resposta instantânea em dezenas de tabelas, conforme FR-005. Deve ser revalidado manualmente com um schema grande no quickstart. |
| VI. Confiança Desde o Primeiro Comando | PASS — melhora a confiabilidade do feedback visual do grafo, que é redesenhado a cada comando; não muda o fluxo de salvamento automático nem o suporte aos três engines. |
| VII. Simplicidade Deliberada | PASS COM JUSTIFICATIVA — a alocação de pistas e o aumento pontual de espaçamento são a forma mais direta de cumprir a garantia de zero cruzamento exigida na spec (Clarifications); não é complexidade especulativa, é requisito explícito do usuário. Nenhuma abstração extra (ex.: motor de grafo genérico) é introduzida além do necessário. |
| VIII. Estabilidade do que Já Existe | PASS — FR-006 exige que schemas sem conflito de roteamento continuem exatamente iguais a hoje; a mudança é aditiva (nova etapa de roteamento), não reescreve `GraphLayoutEngine` nem o formato de projeto salvo. |

Nenhuma violação sem justificativa. Nenhuma entrada necessária em
"Complexity Tracking".

**Reavaliação pós-Fase 1**: `research.md` e `data-model.md` confirmam que a
abordagem continua uma varredura linear sobre obstáculos e corredores (sem
pathfinding genérico) e que nenhuma entidade nova é persistida — apenas
estruturas internas de renderização. Os status PASS e PASS COM
ATENÇÃO/JUSTIFICATIVA acima permanecem válidos; nenhum princípio muda de
avaliação após o design detalhado.

## Project Structure

### Documentation (this feature)

```text
specs/001-fix-graph-relation-lines/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md         # Phase 1 output (/speckit-plan command)
├── quickstart.md         # Phase 1 output (/speckit-plan command)
└── tasks.md              # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

Não há `contracts/`: esta correção não expõe nenhuma interface pública nova
(API, comando ou formato de arquivo); é um ajuste interno de renderização do
grafo no editor.

### Source Code (repository root)

```text
lib/src/components/editor/
├── components/
│   └── table/
│       ├── graph_layout.dart      # já existe — distribuição de tabelas em linhas/colunas (NÃO alterado em sua API pública)
│       ├── graph_routing.dart     # NOVO — obstáculos, decisão de lado, alocação de pistas e ajuste de espaçamento
│       └── table_component.dart   # já existe — passa a consumir graph_routing.dart para desenhar linhas/setas
└── models/
    └── graph_model.dart           # já existe — pode ganhar campos auxiliares (ex.: pista alocada) sem quebrar o formato de SchemaState persistido
```

**Structure Decision**: Single project (Dart TUI). A correção fica inteiramente
dentro de `lib/src/components/editor/components/table/`, a mesma pasta onde o
bug foi localizado, adicionando um novo módulo auxiliar (`graph_routing.dart`)
em vez de inflar `table_component.dart` ou `graph_layout.dart` com
responsabilidades adicionais. Nenhuma pasta nova é criada, conforme a
restrição de escopo do spec.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

Nenhuma violação do Constitution Check exige entrada nesta tabela.
