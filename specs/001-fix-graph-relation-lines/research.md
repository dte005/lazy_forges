# Research: Corrigir linhas de relacionamento transpassando tabelas no grafo

**Feature**: [spec.md](./spec.md) | **Date**: 2026-10-08

Não há itens `NEEDS CLARIFICATION` pendentes no Technical Context do
`plan.md` — a stack (Dart + `nocterm`, sem dependências novas, sem testes
automatizados) já é conhecida e fixada pelo projeto. Esta pesquisa cobre as
decisões de abordagem técnica necessárias para cumprir o comportamento
definido no spec (causa raiz confirmada + clarifications).

## Decisão 1 — Como detectar e evitar cruzamento com tabelas

**Decision**: Antes de desenhar as linhas, construir uma lista de
**obstáculos** (retângulos `x, y, width, height` de cada tabela já
posicionada pelo `GraphLayoutEngine`). O roteamento de cada relação passa a
ser feito sobre esse mapa de obstáculos: qualquer segmento horizontal ou
vertical candidato é validado contra os retângulos de todas as tabelas
exceto a de origem e a de destino daquela relação. Se um segmento cruzaria um
obstáculo, o roteamento desvia pelo corredor livre mais próximo (acima/abaixo
da linha de tabelas, ou à esquerda/direita da coluna), em vez de apenas traçar
o ponto médio geométrico como hoje.

**Rationale**: é a forma mínima de corrigir a causa raiz #1 (roteamento cego
à posição de outras tabelas) sem reescrever o `GraphLayoutEngine` nem mudar a
ordenação das tabelas (fora de escopo). Resolver por geometria explícita
(retângulos) é mais simples e previsível em um grid de texto do que portar um
algoritmo de pathfinding genérico.

**Alternatives considered**:
- *A\* / busca de caminho célula a célula sobre todo o canvas*: resolveria o
  problema, mas é complexidade desproporcional para um layout em grade
  conhecida (tabelas em linhas/colunas fixas) e arriscaria regressão de
  performance em schemas grandes (Princípio V). Rejeitada por violar
  Simplicidade Deliberada sem necessidade comprovada.
- *Ignorar o problema e apenas truncar/ocultar linhas que cruzariam tabelas*:
  rejeitada porque esconderia relacionamentos reais do usuário, violando o
  propósito do grafo (Princípio I).

## Decisão 2 — Como decidir o lado de saída/entrada (substitui `sourceToRight`)

**Decision**: A decisão de lado passa a considerar tanto a coluna (posição
horizontal) quanto a linha/nível (posição vertical) relativa entre origem e
destino:
- Mesma linha (nível), colunas diferentes → sai pelo lado horizontal mais
  próximo do destino (comportamento atual, preservado — FR-006).
- Mesma coluna (faixa horizontal sobreposta), linhas diferentes → sai/entra
  verticalmente (topo/base), usando o corredor vertical (`rowGap`) entre as
  linhas, nunca lateralmente.
- Linhas e colunas diferentes (diagonal) → combina: sai lateralmente até
  alinhar com a coluna do destino, depois usa o corredor vertical para mudar
  de linha, entrando lateralmente no destino.
- Origem igual ao destino (auto-relacionamento) → trata como um laço: sai por
  um lado da própria tabela e reentra por um lado adjacente (ex.: direita e
  depois base), usando apenas espaço fora do retângulo da própria tabela,
  sem depender de nenhuma outra tabela como referência de lado.

**Rationale**: resolve a causa raiz #2 (decisão baseada só no centro
horizontal) cobrindo exatamente os casos citados no spec (User Story 2,
Edge Cases) com regras simples e determinísticas, sem introduzir heurísticas
de distância genéricas.

**Alternatives considered**:
- *Sempre sair pelo lado mais próximo em linha reta (ângulo)*: mais "natural"
  visualmente, mas exigiria diagonais, que não existem no conjunto de
  caracteres do canvas de texto atual (`-`, `|`, `+`, setas). Rejeitada por
  incompatibilidade com o desenho ortogonal existente.

## Decisão 3 — Como distinguir relações que dividem o mesmo corredor

**Decision**: Cada corredor (um `rowGap` ou `colGap` específico entre duas
tabelas/linhas adjacentes) passa a ter um conjunto de **pistas** numeradas
(posições inteiras dentro da largura/altura do corredor). Ao rotear uma
relação que precisa atravessar um corredor já usado por outra relação, o
roteamento aloca a próxima pista livre daquele corredor para o segmento
dessa relação, deslocando o traço em 1 ou mais colunas/linhas em relação ao
usado por outras relações no mesmo corredor. A ordem de alocação segue a
ordem das relações no schema (estável e determinística, para não "piscar"
pistas diferentes entre redesenhos idênticos).

**Rationale**: implementa diretamente a clarificação do spec ("pistas
paralelas: cada relação que compartilha um corredor recebe uma posição
própria"). Também corrige, como efeito colateral correto, a causa raiz #3
(mesmo `midX` reaproveitado entre relações).

**Alternatives considered**:
- *Manter um único traço por corredor e só preservar a cor dominante*:
  rejeitada explicitamente na clarificação (Session 2026-10-08, pergunta 2).

## Decisão 4 — Como garantir zero cruzamento mesmo em layouts densos

**Decision**: Se o número de pistas necessárias em um corredor exceder a
largura/altura disponível hoje (`colGap = 8`, `rowGap = 3`), o corredor
afetado é aumentado especificamente o quanto for necessário para comportar
todas as pistas com espaçamento legível entre elas, e as tabelas posicionadas
depois desse corredor são deslocadas de acordo (mesma lógica de
posicionamento cumulativo que `table_component.dart` já usa ao somar
larguras/alturas + gaps). A ordenação das tabelas em linhas/colunas
(`GraphLayoutEngine`) não muda — apenas o espaçamento entre elas, quando
necessário.

**Rationale**: cumpre a clarificação de garantia forte (Session 2026-10-08,
pergunta 1) sem exigir um motor de layout totalmente novo; é uma extensão
pontual do cálculo de espaçamento já existente.

**Alternatives considered**:
- *Aceitar cruzamento residual em casos extremos*: rejeitada explicitamente
  pela clarificação.
- *Aumentar todos os corredores do grafo uniformemente, sempre*: mais simples
  de implementar, mas desperdiça espaço em telas pequenas e se afasta do
  Princípio VII (Simplicidade Deliberada / nenhuma mudança além do
  necessário); rejeitada em favor do ajuste pontual por corredor.

## Decisão 5 — Onde o código deve viver

**Decision**: Criar `lib/src/components/editor/components/table/graph_routing.dart`
como módulo puro (sem estado, sem widgets do `nocterm`), responsável por:
receber `GraphLayoutResult` + posições de tabela já calculadas, e devolver,
para cada `GraphRelationEdge`, o caminho final (lista de segmentos) e o ponto
da seta. `table_component.dart` passa a chamar esse módulo em vez de calcular
`midX`/`sourceToRight` inline.

**Rationale**: mantém a separação já existente entre "distribuição em
linhas" (`graph_layout.dart`) e "desenho" (`table_component.dart`), sem criar
pastas novas, e torna o roteamento testável manualmente de forma isolada
(entra layout + obstáculos, sai caminho).

**Alternatives considered**:
- *Colocar a lógica dentro de `graph_layout.dart`*: misturaria a
  responsabilidade de "distribuir tabelas em níveis" com "rotear linhas
  entre posições concretas", que são preocupações diferentes; rejeitada por
  clareza de responsabilidade.
- *Colocar tudo inline em `table_component.dart`*: é o estado atual que
  causou o bug (lógica de roteamento misturada com desenho); rejeitada por
  ser exatamente o padrão que gerou a causa raiz #1–#3.

## Resumo das decisões

| # | Decisão | Resolve causa raiz / clarificação |
|---|---|---|
| 1 | Roteamento consciente de obstáculos (retângulos de tabela) | Causa raiz #1 |
| 2 | Lado de saída/entrada por linha E coluna relativas (+ laço para auto-FK) | Causa raiz #2, Edge Case auto-relacionamento |
| 3 | Pistas numeradas por corredor | Causa raiz #3, Clarification 2 |
| 4 | Aumento pontual de corredor quando pistas não cabem | Clarification 1 |
| 5 | Novo módulo `graph_routing.dart` | Estrutura/Simplicidade |

Todas as decisões estão prontas para a Fase 1 (data-model e quickstart); não
há `NEEDS CLARIFICATION` restante.
