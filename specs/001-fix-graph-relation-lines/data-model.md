# Data Model: Corrigir linhas de relacionamento transpassando tabelas no grafo

**Feature**: [spec.md](./spec.md) | **Research**: [research.md](./research.md)

Este documento descreve as entidades conceituais envolvidas no roteamento do
grafo. São estruturas internas de renderização (não persistidas, recalculadas
a cada desenho a partir do `SchemaState` já existente) — não alteram o
formato dos projetos salvos em `lazyforge_projects/` (FR-007).

## TableObstacle

Representa o retângulo ocupado por uma tabela já posicionada, usado para
impedir que qualquer segmento de relação o atravesse.

| Campo | Tipo | Descrição |
|---|---|---|
| `tableKey` | String | Nome da tabela em minúsculas (chave de identidade) |
| `x`, `y` | int | Canto superior esquerdo no canvas de texto |
| `width`, `height` | int | Dimensões do retângulo (iguais às já calculadas hoje em `_TableNodeLayout`) |

**Regra de validação**: nenhum segmento de uma relação cujo `sourceTable` e
`targetTable` sejam diferentes deste `tableKey` pode ocupar uma célula dentro
deste retângulo (incluindo a borda). Para a própria origem/destino da
relação, apenas o ponto de saída/entrada (na borda) é permitido.

## RoutingCorridor (Pista/Corredor)

Representa o espaço livre entre duas tabelas (ou duas linhas de tabelas)
através do qual relações podem passar.

| Campo | Tipo | Descrição |
|---|---|---|
| `orientation` | enum: `horizontal` \| `vertical` | Se o corredor corre entre colunas (`colGap`) ou entre linhas (`rowGap`) |
| `position` | int | Coordenada fixa do corredor (ex.: a linha Y do `rowGap`, ou a faixa X do `colGap`) |
| `availableSpan` | int | Largura/altura disponível hoje (`colGap = 8` ou `rowGap = 3`, podendo crescer pela Decisão 4) |
| `allocatedLanes` | List\<RoutingLaneAssignment\> | Pistas já atribuídas dentro deste corredor, em ordem de alocação |

**Regra de validação**: `allocatedLanes.length` nunca excede o número de
pistas que cabem em `availableSpan` com espaçamento legível entre elas; se
excederia, `availableSpan` é aumentado antes de alocar a nova pista (nunca o
inverso).

## RoutingLaneAssignment

Associa uma relação específica a uma posição (offset) dentro de um
`RoutingCorridor`.

| Campo | Tipo | Descrição |
|---|---|---|
| `edgeIndex` | int | Índice da relação em `GraphLayoutResult.edges`, usado como identidade estável |
| `offset` | int | Deslocamento dentro do corredor (0 = posição central/padrão, 1, 2, ... para pistas adicionais) |

**Regra de validação**: dentro do mesmo `RoutingCorridor`, cada `edgeIndex`
tem um `offset` único; a ordem de alocação segue a ordem de `edgeIndex`
(determinística entre redesenhos idênticos do mesmo schema).

## RoutedEdge

Resultado final do roteamento de uma `GraphRelationEdge` existente (de
`graph_model.dart`), pronto para ser desenhado por `table_component.dart`.

| Campo | Tipo | Descrição |
|---|---|---|
| `edge` | GraphRelationEdge | Referência à relação original (origem/destino/colunas) |
| `segments` | List\<RoutedSegment\> | Lista ordenada de trechos horizontais/verticais que formam o caminho completo, já livres de colisão com obstáculos |
| `arrowPoint` | (x: int, y: int, direction: enum `up`\|`down`\|`left`\|`right`) | Ponto onde a seta é desenhada, sempre adjacente ao lado da tabela de destino por onde o último segmento chega |
| `color` | Color | Cor já atribuída hoje por relação (paleta existente, inalterada) |

### RoutedSegment

| Campo | Tipo | Descrição |
|---|---|---|
| `orientation` | enum: `horizontal` \| `vertical` | Direção do trecho |
| `start`, `end` | (x: int, y: int) | Extremidades do trecho no canvas |

**Regra de validação**: a concatenação de `segments`, na ordem da lista,
MUST formar um caminho contínuo (o fim de um trecho coincide com o início do
próximo) do ponto de saída da tabela de origem até o `arrowPoint` na tabela
de destino, sem nenhum ponto intermediário dentro de um `TableObstacle` que
não seja a origem ou o destino.

## Relação com entidades existentes

- `TableDef`, `ColumnDef`, `ForeignKeyDef` (`schema_model.dart`): não são
  alteradas; continuam sendo a fonte de verdade do schema.
- `GraphRelationEdge`, `GraphLayoutResult` (`graph_model.dart`): continuam
  representando, respectivamente, uma relação a desenhar e o resultado da
  distribuição em linhas/colunas; `GraphLayoutResult` pode, se necessário,
  ganhar o espaçamento (`colGap`/`rowGap`) ajustado pela Decisão 4 como campo
  adicional, sem remover nenhum campo existente.
- `_TableNodeLayout` (interno a `table_component.dart`): continua
  representando a posição final de cada tabela no canvas; é a fonte dos
  `TableObstacle` consumidos pelo novo módulo de roteamento.

## Casos especiais cobertos pelo modelo

- **Auto-relacionamento** (origem = destino): representado como um
  `RoutedEdge` cujo primeiro e último segmento saem/entram pela mesma tabela,
  por lados diferentes, sem nenhum `TableObstacle` de outra tabela
  necessariamente envolvido — mas ainda validado contra todas as outras
  tabelas, caso o laço precise contornar vizinhos próximos.
- **Múltiplas FKs entre o mesmo par de tabelas**: cada FK gera um
  `GraphRelationEdge` e, portanto, um `RoutedEdge` independente; se os
  caminhos calculados coincidirem no mesmo corredor, a alocação de pistas
  (Decisão 3) garante offsets distintos.
