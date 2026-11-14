# Quickstart: Validar a correção das linhas de relacionamento no grafo

**Feature**: [spec.md](./spec.md) | **Data model**: [data-model.md](./data-model.md)

Este guia reproduz a issue #2 e valida que o comportamento esperado (definido
no spec, seção "Requirements" e "Success Criteria") passa a ocorrer depois da
implementação. Não há testes automatizados neste projeto; esta é a validação
oficial.

## Pré-requisitos

- `dart pub get` já executado.
- Branch `001-fix-graph-relation-lines` com a implementação aplicada.

## Preparar o ambiente

```bash
dart pub get
dart --enable-vm-service bin/lazy_forge.dart
```

Crie (ou abra) um projeto quando solicitado pela tela inicial.

## Cenário 1 — Linha cruzando tabela intermediária (US1 / FR-001 / SC-001)

No editor, digite:

```
create table clientes
add column clientes id int as pk
create table pedidos
add column pedidos id int as pk
add column pedidos cliente_id int
create table itens_pedido
add column itens_pedido id int as pk
add column itens_pedido pedido_id int
create table produtos
add column produtos id int as pk
add fk pedidos cliente_id references clientes id
add fk itens_pedido pedido_id references pedidos id
add fk itens_pedido produto_id references produtos id
```

(ajuste a sintaxe exata conforme o comando real de `add fk`/`add column` do
projeto; o objetivo é ter 4 tabelas com relações cujo caminho mais curto
cruzaria uma tabela intermediária na mesma linha ou coluna do grafo).

**Esperado**: nenhuma linha de relacionamento passa por cima do interior,
borda ou texto de `produtos` ou de qualquer outra tabela que não seja a
origem/destino daquela relação específica.

## Cenário 2 — Tabelas na mesma coluna (US2 / FR-002 / SC-002)

Garanta, pelo schema acima ou por um adicional, que duas tabelas relacionadas
fiquem em níveis (linhas do grafo) diferentes mas na mesma coluna (isso
acontece quando uma depende diretamente da outra e ambas são as únicas na sua
linha). Observe o relacionamento entre elas.

**Esperado**: a seta aparece exatamente no ponto onde a linha chega à tabela
de destino (topo ou base), nunca em um lado lateral desconectado do traço.

## Cenário 3 — Relações no mesmo corredor (US3 / FR-003 / SC-003)

Crie uma quinta tabela que também referencie `clientes`, de forma que duas
relações (`pedidos → clientes` e a nova tabela `→ clientes`) tendam a cruzar
o mesmo corredor vertical.

**Esperado**: as duas linhas aparecem em pistas paralelas distintas, cada uma
com sua própria cor, sem se fundir em um único traço.

### Cenário 3b — Múltiplas FKs entre o mesmo par de tabelas (Edge Case)

No mesmo schema, adicione uma segunda coluna e uma segunda FK entre as
*mesmas* duas tabelas (ex.: `pedidos` ganha `substituto_cliente_id` e uma
segunda `add fk pedidos substituto_cliente_id references clientes id`).

**Esperado**: as duas FKs entre `pedidos` e `clientes` aparecem como duas
linhas em pistas distintas, cada uma com sua cor, mesmo compartilhando
origem e destino.

## Cenário 4 — Auto-relacionamento (Edge Case)

```
create table funcionarios
add column funcionarios id int as pk
add column funcionarios gerente_id int
add fk funcionarios gerente_id references funcionarios id
```

**Esperado**: o laço do relacionamento é desenhado em volta da própria
tabela `funcionarios`, sem cruzar nenhuma outra tabela, com a seta apontando
de volta para `funcionarios`.

## Cenário 5 — Sem regressão em schema simples (FR-006 / SC-004)

Em um projeto novo, crie apenas:

```
create table a
add column a id int as pk
create table b
add column b a_id int
add fk b a_id references a id
```

**Esperado**: o grafo de 2 tabelas lado a lado é desenhado exatamente como
antes da correção (linha reta entre as duas, sem desvios desnecessários).

## Cenário 6 — Projeto salvo antes da correção (FR-007 / SC-005)

1. Antes de aplicar a implementação (ou usando uma cópia de backup de um
   projeto já existente em `lazyforge_projects/`), abra esse projeto no
   editor já corrigido.

**Esperado**: o projeto carrega normalmente e o grafo é exibido sem erros,
com o roteamento corrigido aplicado ao schema existente.

## Cenário 7 — Desempenho em schema grande (FR-005)

Crie ou carregue um schema com dezenas de tabelas e vários relacionamentos
cruzados (pode ser gerado repetindo o padrão do Cenário 1 em lote, via
histórico de comandos).

**Esperado**: a navegação e o redesenho do grafo após cada comando continuam
perceptivelmente instantâneos (referência: abaixo de ~100ms), sem
travamentos perceptíveis.

## Cenário 8 — Desvio ao redor de uma linha inteira de tabelas (Edge Case)

Crie um schema largo: uma linha do grafo com 3+ tabelas lado a lado (sem
relação entre si) e, em outra linha, duas tabelas cuja única relação precisa
desviar por fora de toda a linha intermediária para não cruzá-la.

**Esperado**: a linha de relacionamento contorna a linha inteira de tabelas
(pelas laterais ou por cima/baixo do corredor), sem cruzar nenhuma delas.

## Critério de aceite geral

A correção é considerada validada quando todos os 8 cenários acima (incluindo
3b) produzem o resultado esperado na mesma sessão de teste manual, sem
necessidade de reiniciar o processo entre eles (apenas comandos novos no
editor já aberto).
