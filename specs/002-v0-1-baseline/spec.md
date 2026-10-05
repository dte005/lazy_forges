# Feature Specification: LazyForge 1.0.0 — Baseline (as-built)

**Feature Branch**: `002-v0-1-baseline`

**Created**: 2026-10-03

**Status**: Implemented (baseline, somente leitura)

**Input**: User description: "LazyForge 1.0.0 — Especificação Baseline (as-built). IDE de terminal (TUI), operada pelo teclado, para modelar schemas de banco relacional (PostgreSQL, MySQL e SQLite) e exportar o DDL SQL, com visualização da estrutura e dos relacionamentos em tempo real. Esta spec documenta o comportamento já implementado e liberado; não propõe mudanças."

> **Nota de governança (Princípio VIII da Constituição — Preservação do Código Liberado)**: este documento é
> referência histórica do comportamento já liberado na versão 1.0.0. O código existente é a fonte da verdade.
> `/speckit.implement` NÃO DEVE atuar sobre esta spec, pois seu status é `Implemented`. Divergências entre a
> intenção original e o comportamento real estão registradas apenas na seção "Lacunas Conhecidas" e não
> constituem trabalho pendente desta spec.

## Clarifications

### Session 2026-10-04

- Q: Como a documentação deve descrever o suporte a mouse da versão liberada? → A: substituir "sem suporte a mouse" por "a interface é primariamente operada pelo teclado; a v0.1 possui interações por clique (botão 'sair', fechar e copiar comandos na janela Help, janela de tipos do banco)".
- Q: Como a saída do editor e o atalho `Ctrl+C` devem ser documentados? → A: a única forma de sair do editor é o clique no botão "sair"; `Ctrl+C` no editor copia o input para a área de transferência (não encerra a aplicação); somente a tela inicial sai por `Esc`; a tecla `q` não existe na v1.0.0.
- Q: Qual versão deve nomear esta spec baseline? → A: a versão realmente liberada conforme `pubspec.yaml` (`1.0.0`), mantendo "baseline" no título.
- Q: O que deve ser registrado sobre o comando `history`? → A: lista apenas os 15 comandos mais recentes da sessão e não registra a execução do próprio `history` no histórico.
- Q: Como abrir a janela Help e a janela de tipos do banco, e como fechá-las? → A: abrir qualquer uma das duas só é possível por clique (não há atalho de teclado para abrir); fechar é possível por clique no "X" ou pressionando `Esc` enquanto a janela está aberta.
- Q: Qual é o `Given` correto do cenário 2 de User Story 1 (`create table clientes --autoincrement`)? → A: "um projeto que ainda não possui a tabela `clientes`", para refletir que `create table` cria uma tabela nova (RF04 rejeita nomes duplicados).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Modelar um schema do zero e exportar o DDL (Priority: P1)

Um desenvolvedor executa `lazy_forge`, cria um projeto escolhendo o banco de dados alvo (PostgreSQL, MySQL ou
SQLite), monta a estrutura digitando comandos de texto para criar tabelas, colunas, chaves primárias e chaves
estrangeiras, acompanha a estrutura e os relacionamentos sendo atualizados em tempo real na visualização em
grafo, e exporta o schema completo como um arquivo DDL SQL.

**Why this priority**: É o fluxo central já entregue pela versão 1.0.0 e validado em uso real.

**Independent Test**: Criar um projeto novo, executar `create table`, `add column`, `set pk` e `add fk` para
montar 3 tabelas relacionadas, e confirmar que `export` gera um arquivo `.sql` com o DDL completo.

**Acceptance Scenarios**:

1. **Given** um projeto novo sem tabelas, **When** o usuário executa `create table clientes`, **Then** a tabela
   aparece imediatamente na visualização de estrutura.
2. **Given** um projeto que ainda não possui a tabela `clientes`, **When** o usuário executa
   `create table clientes --autoincrement`, **Then** uma coluna `id` é criada como chave primária com descrição
   "auto increment", usando o tipo `serial` (postgres), `int` (mysql) ou `integer` (sqlite).
3. **Given** duas tabelas existentes, **When** o usuário executa
   `add fk pedidos cliente_id references clientes id`, **Then** o sistema aceita o comando somente se `clientes.id`
   existir e for chave primária, e o relacionamento aparece na visualização em grafo.
4. **Given** um schema com tabelas, colunas e ao menos uma FK, **When** o usuário executa `export schema`,
   **Then** um arquivo `schema.sql` é gerado no diretório atual, com um `CREATE TABLE` por tabela na ordem em
   que as tabelas foram criadas (não reordenada por dependência de FK — ver Lacuna Conhecida 6).
5. **Given** uma sequência de comandos encadeados com ` - ` (ex.: `create table t - add column t id int`),
   **When** um dos comandos da cadeia falha, **Then** a execução para na primeira falha e os comandos anteriores
   da cadeia já aplicados permanecem no schema.

---

### User Story 2 - Ajustar a estrutura com segurança (Priority: P2)

Um desenvolvedor com um schema em andamento renomeia tabelas e colunas, altera o tipo de uma coluna, e corrige
comandos digitados incorretamente, sem que a aplicação encerre ou o projeto seja corrompido.

**Why this priority**: Suporta o uso iterativo do fluxo principal.

**Independent Test**: Renomear uma tabela referenciada por uma FK e confirmar que a FK passa a apontar para o
novo nome; digitar um comando inválido e confirmar que o schema permanece inalterado e a aplicação continua
rodando.

**Acceptance Scenarios**:

1. **Given** uma tabela `cliente` referenciada por uma FK em `pedidos`, **When** o usuário executa
   `rename table cliente to clientes` (ou o alias `change table`), **Then** a FK em `pedidos` passa a referenciar
   `clientes` automaticamente.
2. **Given** uma coluna existente, **When** o usuário executa `alter column pedidos valor type decimal` (ou o
   alias `change column ... type`), **Then** o tipo da coluna é atualizado e refletido na visualização.
3. **Given** qualquer estado do schema, **When** o usuário digita um comando com sintaxe inválida ou
   referenciando uma tabela/coluna/tipo inexistente, **Then** o sistema mostra uma mensagem de erro clara, o
   schema permanece inalterado, e a aplicação não encerra.
4. **Given** um projeto com alterações aplicadas com sucesso, **When** o comando termina de ser processado,
   **Then** o projeto é salvo automaticamente em `./lazyforge_projects/<nome>.json`; se o salvamento falhar, o
   sistema informa "Comandos aplicados, mas falhou ao salvar projeto".
5. **Given** um projeto em andamento, **When** o usuário executa `history`, **Then** vê a lista dos comandos
   executados na sessão atual.

---

### User Story 3 - Consultar o dialeto e reabrir um projeto (Priority: P3)

Um desenvolvedor confirma quais tipos de coluna são válidos para o banco escolhido, consulta o estado atual do
schema, e reabre um projeto salvo anteriormente.

**Why this priority**: Aumenta a confiança no resultado e a conveniência de retomar trabalho, mas não bloqueia
o uso do fluxo principal.

**Independent Test**: Executar `show types` em um projeto SQLite e confirmar que `enum` não aparece na lista
(SQLite não suporta esse tipo); fechar e reabrir um projeto salvo e confirmar que a estrutura é restaurada.

**Acceptance Scenarios**:

1. **Given** um projeto com banco definido, **When** o usuário executa `show types`, **Then** vê somente os
   tipos de coluna aceitos para esse banco (o tipo `string` aparece como sinônimo de `text`).
2. **Given** um projeto salvo em `./lazyforge_projects`, **When** o usuário reabre esse projeto ao iniciar o
   LazyForge, **Then** todas as tabelas, colunas e relacionamentos são restaurados como estavam.
3. **Given** um projeto em andamento, **When** o usuário executa `show database`, `show tables` ou `help`,
   **Then** vê, respectivamente, o banco configurado, a lista de tabelas atuais, ou a lista de comandos
   disponíveis.
4. **Given** um projeto em andamento, **When** o usuário executa mais de 15 comandos e em seguida executa
   `history`, **Then** vê apenas os 15 comandos mais recentes da sessão, sem incluir a própria execução de
   `history` na lista.
5. **Given** a tela inicial do LazyForge, **When** o usuário pressiona `Esc`, **Then** a aplicação encerra.
   Dentro do editor de schema, a única forma de sair é clicar no botão "sair" da interface; não existe tecla
   dedicada (`q` ou outra) para encerrar a partir do editor (ver Lacuna Conhecida 8).

---

### Edge Cases (comportamento observado)

- Tabela, coluna ou tipo inexistente referenciado em um comando → mensagem de erro clara; schema inalterado.
- Remover uma tabela referenciada por uma FK → a tabela é removida e as FKs de outras tabelas que apontavam
  para ela são removidas automaticamente, sem bloqueio nem confirmação.
- Não existe comando para remover uma coluna individualmente (`delete column`) nem para remover uma FK
  individualmente na versão 1.0.0.
- Trocar o banco do projeto (`set database`) com colunas de tipos que não existem no novo dialeto → a troca é
  aceita sem validar os tipos já existentes no schema atual.
- Usar `options(...)` em um tipo que não é `enum` → comando rejeitado. `enum` sem `options(...)` → também
  rejeitado. Valores de `options(...)` duplicados → rejeitados.
- Criar uma FK entre colunas de tipos incompatíveis → não há validação de compatibilidade de tipos.
- Nomes de tabela/coluna/arquivo de export aceitam apenas `[a-zA-Z_][a-zA-Z0-9_]*` (identificadores) ou letras,
  números, `_` e `-` (nome de projeto e de arquivo de export); espaços, caracteres especiais e palavras
  reservadas do SQL não recebem tratamento especial (não são escapados nem citados no DDL).
- Exportar com o schema vazio → gera um arquivo contendo apenas o cabeçalho (`-- LazyForge SQL DDL`,
  `-- Database: <engine>`).
- Exportar para um nome de arquivo já existente → sobrescreve o arquivo silenciosamente, sem confirmação.
- Terminal pequeno demais para a visualização → não há tratamento específico implementado.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema DEVE permitir criar um novo projeto escolhendo o banco de dados alvo entre PostgreSQL,
  MySQL ou SQLite, ou reabrir um projeto salvo anteriormente. Nome de projeto aceita apenas letras, números,
  `_` e `-`; criar um projeto com nome já existente é rejeitado.
- **FR-002**: O sistema DEVE salvar os projetos em `./lazyforge_projects/<nome>.json` e permitir reabri-los,
  restaurando toda a estrutura (tabelas, colunas, chaves e relacionamentos).
- **FR-003**: O sistema DEVE validar os tipos de coluna de acordo com o banco ativo do projeto, e disponibilizar
  o comando `show types` para listar os tipos aceitos (o tipo `string` é aceito como sinônimo de `text`).
- **FR-004**: O sistema DEVE impedir a existência de duas tabelas com o mesmo nome no mesmo projeto, e de duas
  colunas com o mesmo nome na mesma tabela, usando comparação sem diferenciar maiúsculas/minúsculas.
- **FR-005**: O sistema DEVE permitir criar, remover e renomear tabelas via comando de texto (`create table`,
  `delete table`/`drop table`, `rename table`/`change table`), incluindo encadeamento de múltiplos comandos na
  mesma linha usando o separador ` - `.
- **FR-006**: O sistema DEVE permitir adicionar uma ou várias colunas a uma tabela (`add column`, `add columns`,
  e a forma verbosa `add column <coluna> type <tipo> to <tabela>`), especificando nome, tipo, indicação de
  chave primária (`as pk`), valores permitidos (`options(...)`, exclusivo para o tipo `enum`) e descrição
  (`description(...)`).
- **FR-007**: O sistema DEVE permitir alterar o tipo de uma coluna existente (`alter column`/`change column ...
  type`) e renomear colunas (`rename column`/`change column ... to`).
- **FR-008**: O sistema DEVE permitir definir qual coluna de uma tabela é a chave primária (`set pk`).
- **FR-009**: O sistema DEVE permitir criar uma chave estrangeira (`add fk ... references ...`) somente quando a
  tabela e a coluna de origem existirem, a tabela e a coluna referenciadas existirem, a coluna referenciada for
  chave primária, e a mesma FK ainda não existir.
- **FR-010**: O sistema DEVE atualizar automaticamente qualquer chave estrangeira que aponte para uma tabela ou
  coluna renomeada, e DEVE remover automaticamente as chaves estrangeiras de outras tabelas que apontavam para
  uma tabela removida.
- **FR-011**: O sistema DEVE permitir trocar o banco de dados alvo do projeto (`set database`) em qualquer
  momento.
- **FR-012**: O sistema DEVE incluir no DDL exportado a descrição de uma coluna como comentário SQL em linha
  (`-- coluna: descrição`) acima da definição da coluna.
- **FR-013**: O sistema DEVE criar, ao usar `--autoincrement` em `create table`, uma coluna `id` como chave
  primária com descrição "auto increment", usando o tipo `serial` (postgres), `int` (mysql) ou `integer`
  (sqlite).
- **FR-014**: O sistema DEVE rejeitar comandos inválidos (sintaxe incorreta, referência a elemento inexistente,
  tipos incompatíveis) exibindo uma mensagem clara, sem encerrar a aplicação e sem alterar o schema; em uma
  cadeia de comandos (`-`), a execução para no primeiro comando que falhar.
- **FR-015**: O sistema DEVE exibir, via comando, o banco ativo do projeto (`show database`), a lista de tabelas
  (`show tables`), o histórico de comandos da sessão (`history`) e a lista de comandos disponíveis (`help`). O
  comando `history` lista apenas os 15 comandos mais recentes da sessão e não registra a própria execução de
  `history` no histórico.
- **FR-016**: O sistema DEVE refletir qualquer alteração de schema na visualização em grafo (tabelas, colunas,
  chaves e relacionamentos) imediatamente após o comando ser aplicado com sucesso.
- **FR-017**: O sistema DEVE permitir exportar o schema completo como um arquivo DDL SQL (`export
  [nome_arquivo]`) no diretório atual, com extensão `.sql` adicionada automaticamente quando ausente; sem nome
  informado, usa o nome do projeto; se o arquivo já existir, o sistema o sobrescreve sem solicitar confirmação.
- **FR-018**: O sistema DEVE salvar o projeto em disco automaticamente após cada comando (ou cadeia de
  comandos) aplicado com sucesso que altere o schema; não existe comando explícito de salvar.
- **FR-019**: O sistema DEVE ser operável primariamente pelo teclado; a tela inicial DEVE encerrar a aplicação
  ao pressionar `Esc`. Dentro do editor de schema, a única forma de sair é o clique no botão "sair" da
  interface; não existe tecla dedicada (`q` ou outra) para encerrar a partir do editor. `Ctrl+C` dentro do
  editor copia o comando digitado (input) para a área de transferência e NÃO encerra a aplicação. A janela
  Help e a janela de tipos do banco só podem ser abertas por clique (não há atalho de teclado para abri-las);
  uma vez abertas, podem ser fechadas por clique no "X" ou pressionando `Esc`.

### Key Entities *(include if feature involves data)*

- **Projeto**: Schema em edição; possui um banco de dados alvo (PostgreSQL, MySQL ou SQLite), um conjunto de
  tabelas, e um histórico de comandos da sessão. Persistido como `./lazyforge_projects/<nome>.json`.
- **Tabela**: Elemento nomeado do schema que agrupa colunas; nome único dentro do projeto (comparação
  case-insensitive).
- **Coluna**: Pertence a uma tabela; possui nome (único dentro da tabela, case-insensitive), tipo (validado
  conforme o banco do projeto), indicação de chave primária, valores permitidos opcionais (`options`, somente
  para tipo `enum`) e descrição opcional.
- **Relacionamento (Chave Estrangeira)**: Liga uma coluna de uma tabela a uma coluna (chave primária) de outra
  tabela; é removida automaticamente quando a tabela/coluna referenciada é removida, e atualizada
  automaticamente quando é renomeada.
- **Banco de Dados Alvo**: Dialeto do projeto (PostgreSQL, MySQL ou SQLite); determina os tipos de coluna
  válidos e o formato do DDL exportado.

## Formato do DDL Exportado *(comportamento observado)*

- Cabeçalho fixo: `-- LazyForge SQL DDL` e `-- Database: <engine>`.
- Um `CREATE TABLE` por tabela, na ordem em que as tabelas foram criadas no projeto (não reordenada por
  dependência de FK).
- O tipo `enum` é emitido como `TEXT` com `CHECK (coluna IN ('v1','v2'))`.
- A chave primária é emitida inline como `PRIMARY KEY` na definição da coluna.
- Chaves estrangeiras são emitidas como `FOREIGN KEY (coluna) REFERENCES tabela(coluna)`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um usuário novo consegue criar 3 tabelas relacionadas por chave primária e chave estrangeira, e
  exportar o DDL correspondente, em menos de 5 minutos.
- **SC-002**: Nenhum comando inválido encerra a aplicação ou corrompe o projeto salvo.
- **SC-003**: Toda alteração de schema aplicada com sucesso é refletida na visualização imediatamente após o
  comando.
- **SC-004**: Um usuário consegue reabrir um projeto salvo e retomar o trabalho sem perder nenhuma tabela,
  coluna ou relacionamento previamente criado.

> **Nota**: estas metas não são verificadas por suíte de testes automatizados (a constituição do projeto
> dispensa testes automatizados como critério de aceite); a execução do DDL exportado nos três bancos é
> conferida manualmente.

## Fora de Escopo (versão 1.0.0)

- Conectar a um banco real para ler ou aplicar o schema.
- Interface gráfica completa (a interface é primariamente operada pelo teclado; a versão 1.0.0 possui
  interações por clique — botão "sair", fechar e copiar comandos na janela Help, janela de tipos do banco —
  ver "Assumptions").
- Export de diagrama Mermaid ER (candidato a versão futura).
- Comando para remover uma coluna ou uma FK individualmente.

## Lacunas Conhecidas

<!--
  Estas lacunas são divergências observadas entre a intenção original do produto e o comportamento
  efetivamente implementado na versão 1.0.0. São registradas apenas como candidatas a especificações futuras
  independentes; NÃO representam trabalho pendente desta spec e NÃO devem ser usadas como entrada para
  /speckit.implement nesta spec (cujo status é "Implemented").
-->

1. `delete table` remove as FKs dependentes de outras tabelas silenciosamente, sem aviso nem confirmação.
2. `export` sobrescreve um arquivo existente sem solicitar confirmação.
3. `set database` não valida os tipos das colunas já existentes contra o novo dialeto escolhido.
4. A criação de uma FK não valida a compatibilidade de tipo entre a coluna de origem e a coluna referenciada.
5. `--autoincrement` apenas define um tipo inteiro/serial como chave primária; o DDL exportado não emite a
   cláusula `AUTO_INCREMENT` (MySQL) nem `AUTOINCREMENT` (SQLite).
6. O DDL exportado não reordena as tabelas por dependência de chave estrangeira (usa a ordem de criação), e não
   escapa nem cita (quote) identificadores ou palavras reservadas do SQL.
7. A descrição de uma coluna (`description(...)`) é emitida como comentário SQL em linha, não como comentário
   nativo do mecanismo de metadados do banco (ex.: `COMMENT ON COLUMN` no PostgreSQL).
8. Não existe um atalho de tecla dedicado (`q`, ou qualquer outra tecla) para sair de dentro do editor de
   schema; a única forma de sair do editor é o clique no botão "sair" da interface. `Ctrl+C` dentro do editor
   copia o comando digitado (input) para a área de transferência e não encerra a aplicação. Somente a tela
   inicial do LazyForge sai por `Esc`.
9. Não há comando para remover uma coluna ou uma chave estrangeira individualmente — somente a tabela inteira.
10. Não há tratamento específico implementado para quando o terminal é pequeno demais para a visualização.

## Assumptions

- Este documento descreve o comportamento observado no código-fonte da versão 1.0.0 já liberada; qualquer
  divergência entre esta spec e o código real deve ser resolvida a favor do código, conforme o Princípio VIII
  da constituição do projeto.
- O LazyForge opera inteiramente offline, sem se conectar a uma instância real de banco de dados.
- A interface é primariamente operada pelo teclado; a versão 1.0.0 possui interações por clique (botão
  "sair", fechar e copiar comandos na janela Help, janela de tipos do banco). Abrir a janela Help e a janela
  de tipos do banco só é possível por clique, sem atalho de teclado equivalente; fechar qualquer uma delas é
  possível tanto por clique no "X" quanto pela tecla `Esc`.
