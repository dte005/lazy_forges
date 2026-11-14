# Feature Specification: Corrigir linhas de relacionamento transpassando tabelas no grafo

**Feature Branch**: `001-fix-graph-relation-lines`

**Created**: 2026-10-08

**Status**: Planned

**Source issue**: #2

**Input**: User description: "Fonte: issue #2 do repositório dte005/lazy_forges, '[bug] Linhas de relacionamento estao transpassando tabelas' (label bug, milestone 'release v1.0.1'). Ao modelar um schema com pelo menos 4 tabelas e relacionamentos (FK) entre elas, o grafo no editor desenha as linhas de relacionamento passando por cima de outras tabelas. A seta que indica o destino do relacionamento também aparece mal posicionada. Quando vários relacionamentos seguem o mesmo caminho, as linhas ficam uma em cima da outra e não dá para distinguir qual liga o quê."

## Clarifications

### Session 2026-10-08

- Q: Em layouts muito densos, onde pode não existir um corredor geometricamente livre entre origem e destino, o grafo deve garantir SEMPRE zero cruzamento (mesmo que isso exija reservar mais espaço/"pistas" entre tabelas), ou é aceitável, em casos extremos raros, haver um cruzamento residual como última alternativa? → A: Garantia forte — nunca cruzar tabelas; se o espaço atual entre tabelas não for suficiente para desviar uma linha, a correção MUST aumentar o espaçamento/reservar pistas adicionais entre tabelas na medida necessária para manter essa garantia.
- Q: Quando duas ou mais relações realmente compartilham o mesmo trecho de corredor, a correção precisa separar visualmente os traços em "pistas" paralelas distintas (cada linha num ponto diferente da tela), ou basta garantir que cada relação sempre mantenha sua própria cor visível (sem uma cor substituir a outra no mesmo ponto)? → A: Pistas paralelas — cada relação que compartilha um corredor MUST receber uma posição própria (offset), visível lado a lado, e não apenas uma cor preservada sobre um traço único compartilhado.
- Q: Um relacionamento onde a tabela de origem e a de destino são a mesma (uma chave estrangeira que referencia a própria tabela) está dentro do escopo desta correção? → A: Sim, dentro do escopo — auto-relacionamento (origem = destino) MUST seguir as mesmas garantias desta correção (não cruzar outras tabelas, seta no lugar correto).

## Causa Raiz Confirmada no Código _(mandatory)_

O desenho do grafo acontece em
`lib/src/components/editor/components/table/table_component.dart`; a
distribuição das tabelas em linhas/colunas acontece em
`.../table/graph_layout.dart`. As três hipóteses levantadas na issue foram
verificadas diretamente no código e **todas as três se confirmam**:

1. **Roteamento cego à posição de outras tabelas.** O cálculo de `midX` e o
   desenho dos trechos horizontal/vertical de cada relação não consultam, em
   nenhum momento, as coordenadas (x/y, largura/altura) das demais tabelas já
   posicionadas. A única defesa contra sobreposição é a lógica de mesclagem de
   caracteres em `drawAt` (que combina `-`/`|` em `+` quando já existe uma
   linha no mesmo ponto). Essa defesa não distingui "espaço vazio da tela" de
   "espaço em branco dentro de uma tabela" (o preenchimento interno das
   colunas usa `padRight`, que grava caracteres de espaço literais iguais ao
   fundo da tela) — por isso uma linha de relação atravessa livremente o
   interior de uma tabela sempre que o trecho horizontal ou vertical cruza sua
   área. Quando a linha cruza exatamente a borda de uma tabela (caractere `-`,
   `|` ou `+`), a mesclagem transforma esse ponto da borda em `+`, fazendo a
   borda parecer "rompida" pela linha.
2. **Decisão de lado baseada só no centro horizontal.** `sourceToRight` é
   calculado comparando apenas `target.centerX >= source.centerX`, sem
   considerar a posição vertical (linha/nível) das tabelas. Quando origem e
   destino caem na mesma coluna (mesmo `centerX`, em linhas/níveis diferentes
   do grafo), o código ainda escolhe um lado (direita) e sai/entra pelas
   laterais das tabelas, produzindo um caminho que se afasta
   desnecessariamente para o lado e pode cruzar tabelas vizinhas na mesma
   linha de origem ou de destino; a seta termina no lado lateral da tabela de
   destino, não no lado de onde a linha efetivamente chega.
3. **`midX` e corredor duplicados entre relações distintas.** `midX` é
   calculado de forma independente para cada relação, sem registrar quais
   colunas verticais já estão em uso por outras relações. Quando duas ou mais
   relações calculam o mesmo `midX` (ou passam pela mesma linha horizontal),
   `drawAt` sobrepõe os traços: ao encontrar o mesmo caractere (`-` ou `|`) já
   desenhado, ele apenas substitui a cor anterior pela cor da relação
   desenhada por último, fazendo duas ou mais relações se fundirem em um único
   traço com uma só cor — tornando impossível distinguir qual relação é qual.

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Ver o grafo sem linhas atravessando tabelas (Priority: P1)

Como usuário modelando um schema com várias tabelas relacionadas, quando eu
crio ou altero relacionamentos (`add fk`), quero que o grafo no editor desenhe
as linhas de relacionamento contornando as tabelas, para conseguir ler o
schema sem confusão visual, mesmo com 4 ou mais tabelas.

**Why this priority**: é o próprio bug relatado na issue e o que mais
compromete o propósito do grafo (mostrar o schema de forma clara a cada
comando). Sem isso, o grafo é a parte central do editor e fica inutilizável em
schemas não triviais.

**Independent Test**: criar um schema com 4+ tabelas e relacionamentos cujo
caminho mais curto entre origem e destino cruzaria uma tabela intermediária;
verificar visualmente que nenhuma linha atravessa o interior ou a borda de
nenhuma tabela.

**Acceptance Scenarios**:

1. **Given** um schema com 4 ou mais tabelas e relacionamentos cujo trajeto
   mais direto cruzaria outras tabelas, **When** o editor renderiza o grafo,
   **Then** nenhuma linha de relacionamento passa pelo interior, pela borda ou
   sobre o texto de qualquer tabela que não seja a de origem ou destino
   daquela relação.
2. **Given** um schema pequeno sem conflito de roteamento (por exemplo, 2
   tabelas lado a lado com uma relação entre elas), **When** o grafo é
   renderizado, **Then** o resultado é visualmente idêntico ao que já é
   produzido hoje (sem regressão).

---

### User Story 2 - Ver a seta de relacionamento no lugar certo (Priority: P1)

Como usuário, quando duas tabelas relacionadas ficam na mesma coluna do grafo
(uma acima da outra) ou em posições onde o lado de saída/entrada não é óbvio,
quero que a seta do relacionamento sempre apareça junto ao lado da tabela de
destino por onde a linha realmente chega, para identificar corretamente a
direção do relacionamento.

**Why this priority**: a seta mal posicionada é citada na issue como parte do
mesmo problema de legibilidade e tem o mesmo impacto de prioridade que a
User Story 1; ambas decorrem da mesma falha de roteamento geométrico.

**Independent Test**: criar duas tabelas posicionadas na mesma coluna do
grafo (uma em cada nível/linha) e relacioná-las; verificar que a seta aparece
exatamente onde a linha encontra a tabela de destino, e não em um lado lateral
desconectado do traço.

**Acceptance Scenarios**:

1. **Given** um relacionamento entre tabelas que ficam na mesma coluna do
   grafo (linhas/níveis diferentes), **When** o grafo é renderizado, **Then**
   a seta aparece adjacente ao lado correto da tabela de destino, no ponto
   exato de chegada da linha.
2. **Given** um relacionamento entre tabelas em linhas diferentes e colunas
   diferentes, **When** o grafo é renderizado, **Then** a seta aparece
   adjacente ao lado da tabela de destino por onde o traço chega, apontando
   para dentro dela.

---

### User Story 3 - Distinguir relacionamentos que share o mesmo corredor (Priority: P2)

Como usuário, quando dois ou mais relacionamentos passam perto um do outro
(mesmo corredor vertical ou horizontal), quero conseguir distinguir
visualmente cada um, para não confundir qual relação liga quais tabelas.

**Why this priority**: é consequência direta do mesmo bug relatado
("linhas ficam uma em cima da outra"), mas tem impacto um degrau abaixo das
User Stories 1 e 2 porque só se manifesta quando há múltiplos relacionamentos
próximos — é menos frequente que uma única linha cruzando uma tabela.

**Independent Test**: criar um schema onde duas relações diferentes
naturalmente calculariam a mesma coluna de roteamento (por exemplo, duas FKs
que saem de tabelas vizinhas em direção ao mesmo destino); verificar que as
duas linhas são desenhadas em pistas paralelas distintas, cada uma com sua
cor, sem ocupar o mesmo ponto da tela.

**Acceptance Scenarios**:

1. **Given** dois ou mais relacionamentos cujo roteamento calculado
   coincidiria no mesmo corredor, **When** o grafo é renderizado, **Then**
   cada relacionamento é desenhado em uma pista própria dentro do corredor,
   lado a lado, com sua cor preservada, sem que uma relação sobreponha ou
   substitua visualmente a outra.

---

### Edge Cases

- O que acontece quando a tabela de origem e a de destino estão na mesma linha
  (nível) do grafo, lado a lado, sem nenhuma tabela entre elas? (Já funciona
  hoje — deve continuar funcionando sem regressão.)
- O que acontece quando a tabela de origem e a de destino estão na mesma
  coluna (uma diretamente acima/abaixo da outra), sem nenhuma tabela ao lado?
- O que acontece quando existem múltiplas FKs entre o mesmo par de tabelas?
- O que acontece quando uma tabela tem uma FK que referencia a si mesma
  (auto-relacionamento, origem e destino são a mesma tabela)? Está dentro do
  escopo desta correção e MUST seguir as mesmas garantias (sem cruzar outras
  tabelas, seta no lado correto).
- O que acontece com um relacionamento que, para não cruzar tabelas, precisa
  contornar uma linha inteira de tabelas (schema largo)?
- O que acontece em um schema com dezenas de tabelas (desempenho e
  legibilidade continuam aceitáveis)?
- O que acontece ao abrir um projeto salvo antes desta correção, cujo arquivo
  JSON não tem nenhuma informação de layout (o layout é sempre recalculado)?

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: O grafo MUST desenhar cada linha de relacionamento sem passar
  pelo interior, pela borda ou pelo texto de qualquer tabela que não seja a
  origem ou o destino daquela relação específica, mesmo em schemas com 4 ou
  mais tabelas e relacionamentos cruzados. Essa garantia MUST valer sempre,
  sem exceção: quando o espaçamento atual entre tabelas não for suficiente
  para desviar uma linha, a correção MUST aumentar o espaçamento (reservar
  pistas/corredores adicionais) o quanto for necessário para manter zero
  cruzamentos — nunca é aceitável um cruzamento residual como solução final.
- **FR-002**: O grafo MUST posicionar a seta de cada relacionamento sempre
  adjacente ao lado da tabela de destino por onde a linha efetivamente chega,
  apontando para essa tabela, independentemente de origem e destino estarem
  na mesma linha, na mesma coluna, em posições diagonais do grafo, ou serem a
  mesma tabela (auto-relacionamento).
- **FR-003**: Quando dois ou mais relacionamentos ocupam o mesmo corredor
  (mesma coluna ou linha de roteamento), o grafo MUST atribuir a cada
  relação uma posição própria (pista/offset) dentro desse corredor, de modo
  que os traços fiquem visíveis lado a lado, cada um com sua cor, em vez de
  ocuparem exatamente o mesmo ponto da tela.
- **FR-004**: O grafo MUST continuar sendo recalculado e redesenhado a cada
  comando que altere tabelas, colunas ou relacionamentos, exatamente como
  acontece hoje.
- **FR-005**: O grafo MUST continuar respondendo de forma perceptivelmente
  instantânea em schemas grandes (dezenas de tabelas), sem introduzir atrasos
  perceptíveis em relação ao comportamento atual. Referência de validação: o
  redesenho do grafo após um comando MUST ficar abaixo de ~100ms (limiar de
  percepção humana de resposta instantânea), mesmo em schemas com dezenas de
  tabelas.
- **FR-006**: Para schemas sem conflito de roteamento (por exemplo, duas
  tabelas lado a lado com uma única relação entre elas), o grafo MUST
  continuar sendo desenhado exatamente como é hoje (sem regressão visual).
- **FR-007**: A correção MUST preservar a leitura de projetos salvos
  (`lazyforge_projects/`) anteriores a esta mudança; o grafo é recalculado a
  partir do schema do projeto, sem depender de nenhuma informação de layout
  persistida.
- **FR-008**: A correção MUST se limitar ao roteamento e desenho das linhas e
  setas de relacionamento; não MUST alterar o layout/ordenação das tabelas em
  linhas, a paleta de cores, os comandos, o parsing, o export de DDL ou a
  persistência, a menos que a causa raiz confirmada exija uma mudança pontual
  nesses pontos.

### Key Entities _(include if feature involves data)_

- **Relacionamento (FK) no grafo**: representação visual de uma chave
  estrangeira entre duas tabelas já modeladas; tem uma tabela/coluna de
  origem, uma tabela/coluna de destino, um trajeto de linhas no canvas de
  texto e uma seta indicando o destino.
- **Tabela posicionada no grafo**: retângulo de texto com posição (x, y),
  largura e altura, calculado a partir do schema e da distribuição em
  linhas/colunas; é o obstáculo que as linhas de relacionamento não podem
  atravessar.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: Em um schema com 4 ou mais tabelas e relacionamentos cruzados,
  nenhuma linha de relacionamento sobrepõe visualmente o interior, a borda ou
  o texto de uma tabela que não seja origem nem destino daquela relação.
- **SC-002**: Em qualquer relacionamento, a seta aparece sempre adjacente ao
  lado da tabela de destino por onde a linha chega, nunca desconectada do
  traço ou em um lado que não corresponde ao caminho desenhado.
- **SC-003**: Quando dois ou mais relacionamentos compartilham o mesmo
  corredor de roteamento, cada um é desenhado em uma pista própria, lado a
  lado, permitindo que um usuário identifique visualmente, sem ambiguidade,
  qual linha pertence a qual relacionamento.
- **SC-004**: Schemas que já eram desenhados corretamente antes da correção
  (sem conflito de roteamento) continuam sendo desenhados exatamente como
  antes.
- **SC-005**: Um projeto salvo antes desta correção abre normalmente e tem seu
  grafo exibido sem erros.

## Assumptions

- O layout de tabelas em linhas/colunas (quem fica em qual linha, em que
  ordem) é considerado correto hoje e não é o alvo desta correção; apenas o
  roteamento das linhas de relacionamento e o posicionamento da seta são
  corrigidos, a menos que a causa raiz confirmada exija um ajuste pontual. O
  espaçamento entre tabelas (gaps horizontal e vertical) é tratado de forma
  diferente da ordenação: ele PODE ser aumentado, quando necessário, para
  garantir que sempre exista corredor livre suficiente para desviar uma
  linha sem cruzar tabelas (ver Clarifications, Session 2026-10-08); isso não
  conta como mudança de "layout/ordenação" para efeito do Fora de Escopo.
- "Contornar as tabelas" significa que a linha pode usar segmentos
  horizontais e verticais adicionais (desviando por corredores livres entre
  tabelas) em vez do caminho mais curto, sempre que o caminho mais curto
  cruzaria uma tabela.
- A paleta de cores por relacionamento já existente continua sendo o
  mecanismo primário de distinção visual entre relações; esta correção pode
  reforçá-la (por exemplo, evitando que uma cor substitua outra no mesmo
  ponto) mas não introduz um mecanismo de cor novo.
- Esta correção não introduz interação do usuário com o grafo (não há
  zoom, rolagem ou arrastar tabelas); o grafo continua sendo somente leitura,
  recalculado a cada comando.

## Como Validar Manualmente

1. Rodar `dart --enable-vm-service bin/lazy_forge.dart` e criar um projeto.
2. Criar 4 ou mais tabelas com PK e colunas, e relacioná-las com `add fk` de
   modo que: (a) alguma relação precise cruzar uma linha intermediária de
   tabelas, e (b) outra relação una tabelas na mesma coluna do grafo.
3. Conferir visualmente que nenhuma linha atravessa o interior, a borda ou o
   texto de qualquer tabela; que as setas aparecem no lado correto da tabela
   de destino; e que relações próximas continuam distinguíveis (cores
   diferentes, traços não fundidos).
4. Criar um schema simples de 2 tabelas lado a lado com uma relação e
   confirmar que o desenho permanece igual ao comportamento atual (sem
   regressão).
5. Reabrir um projeto salvo antes desta correção (arquivo JSON existente em
   `lazyforge_projects/`) e confirmar que ele carrega normalmente e que o
   grafo é exibido.

## Execução das Tarefas

- Toda atividade/tarefa desta spec (planejamento técnico e implementação)
  MUST se apoiar nas skills de Dart já disponíveis no projeto, em
  `.agents/skills/` (ex.: `dart-fix-runtime-errors`, `dart-run-static-analysis`,
  `dart-use-pattern-matching`, `dart-add-unit-test`, entre outras), consultando
  a skill pertinente ao tipo de trabalho sendo feito, em vez de decidir a
  abordagem apenas por conta própria quando já existir uma skill equivalente.
- Ao final da execução de todas as tarefas desta spec, o subagente
  `test-manager-executer` (definido em `.github/agents/test-manager-executer.md`)
  MUST ser executado, para que a verificação/gestão de testes prevista por
  esse subagente rode sobre o resultado da correção antes de considerá-la
  concluída.

## Fora de Escopo

- Mudar o layout/ordenação das tabelas em linhas, a paleta de cores das
  relações, os comandos, o parsing, o export de DDL ou a persistência, exceto
  se a causa raiz confirmada exigir.
- Qualquer refatoração não necessária à correção deste bug.
- Novas funcionalidades de grafo (zoom, rolagem, arrastar tabelas).
- Criação de pastas ou arquivos que fujam da arquitetura de pastas existente
  do projeto.

## Restrições

- Não alterar comportamento existente fora deste bug (princípio de
  estabilidade da constituição — `.specify/memory/constitution.md`).
- Manter a leitura de projetos JSON já salvos em `lazyforge_projects/`.
- Respeitar a organização de pastas existente em `lib/src/`.
- Não adicionar dependências novas ao `pubspec.yaml`.
- Mensagens ao usuário (quando houver) em português, claras e sem stack
  trace.
- A execução das tarefas (ver "Execução das Tarefas") MUST se apoiar nas
  skills de Dart em `.agents/skills/` quando pertinentes, e MUST encerrar com
  a execução do subagente `test-manager-executer` (`.github/agents/`).
- O subagente é uma exceção sob demanda, não bloqueante
- A técnica de roteamento (algoritmo específico para contornar tabelas) não é
  decidida nesta spec; cabe ao `/speckit-plan` descrever o comportamento
  correto resultante, não a implementação.
