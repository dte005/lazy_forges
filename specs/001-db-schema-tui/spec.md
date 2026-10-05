# Feature Specification: Modelagem de Schema de Banco via TUI (LazyForge)

**Feature Branch**: `001-db-schema-tui`

**Created**: 2026-10-03

**Status**: Superseded by 002-v0-1-baseline (histórico; não usar em /speckit-implement)

**Input**: User description: "LazyForge: IDE de terminal (TUI), operada pelo teclado, para modelar schemas de banco de dados relacional (PostgreSQL, MySQL e SQLite) e exportar o DDL SQL, com visualização da estrutura e dos relacionamentos em tempo real. Inspirada em LazyGit e LazyVim."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Modelar um schema do zero e exportar o DDL (Priority: P1)

Um desenvolvedor abre o LazyForge, cria um novo projeto escolhendo o banco de dados alvo (PostgreSQL, MySQL ou SQLite), monta a estrutura digitando comandos de texto para criar tabelas, colunas, chaves primárias e chaves estrangeiras, acompanha a estrutura e os relacionamentos sendo atualizados em tempo real na visualização, e por fim exporta o schema completo como um arquivo DDL SQL pronto para uso.

**Why this priority**: É o fluxo central que entrega o valor principal do produto — substituir uma ferramenta gráfica externa por uma experiência de terminal. Sem ele não há produto utilizável.

**Independent Test**: Pode ser testado integralmente criando um projeto novo, executando comandos de `create table`, `add column`, `set pk` e `add fk` para montar 3 tabelas relacionadas, e verificando que `export` gera um arquivo `.sql` que cria as tabelas no banco escolhido sem erros, respeitando a ordem exigida pelas FKs.

**Acceptance Scenarios**:

1. **Given** um projeto novo sem tabelas, **When** o usuário executa `create table clientes`, **Then** a tabela aparece imediatamente na visualização de estrutura.
2. **Given** uma tabela existente, **When** o usuário executa `add column clientes id integer as pk --autoincrement`, **Then** a coluna é criada como chave primária com autoincremento no formato nativo do banco do projeto.
3. **Given** duas tabelas existentes (`pedidos` e `clientes`), **When** o usuário executa `add fk pedidos cliente_id references clientes id`, **Then** o relacionamento aparece na visualização em grafo e passa a conectar as duas tabelas.
4. **Given** um schema com tabelas, colunas e ao menos uma FK, **When** o usuário executa `export schema.sql`, **Then** um arquivo `schema.sql` é gerado no diretório atual contendo o DDL completo, na ordem de criação correta (tabelas referenciadas antes das que as referenciam).
5. **Given** um DDL exportado a partir de um schema válido, **When** esse DDL é executado no banco escolhido (PostgreSQL, MySQL ou SQLite), **Then** ele roda do início ao fim sem erros.

---

### User Story 2 - Ajustar e corrigir a estrutura com segurança (Priority: P2)

Um desenvolvedor que já tem um schema em andamento precisa renomear tabelas e colunas, alterar o tipo de uma coluna, e corrigir enganos — sem que comandos inválidos ou ajustes estruturais corrompam o projeto ou derrubem a aplicação.

**Why this priority**: Modelagem de schema é iterativa por natureza; o usuário raramente acerta a estrutura na primeira tentativa. Sem edição seria preciso recomeçar o projeto a cada ajuste.

**Independent Test**: Pode ser testado renomeando uma tabela referenciada por uma FK e confirmando que a FK continua apontando corretamente para o novo nome, e também digitando um comando malformado e confirmando que o schema permanece inalterado e a aplicação continua rodando.

**Acceptance Scenarios**:

1. **Given** uma tabela `cliente` referenciada por uma FK em `pedidos`, **When** o usuário executa `rename table cliente to clientes`, **Then** a tabela é renomeada e a FK em `pedidos` passa a referenciar `clientes` automaticamente.
2. **Given** uma coluna existente, **When** o usuário executa `alter column pedidos valor type decimal`, **Then** o tipo da coluna é atualizado e refletido na visualização.
3. **Given** qualquer estado do schema, **When** o usuário digita um comando com sintaxe inválida ou referenciando uma tabela/coluna inexistente, **Then** o sistema mostra uma mensagem explicando o erro e a sintaxe correta, sem alterar o schema e sem encerrar a aplicação.
4. **Given** um projeto em andamento, **When** o usuário executa `history`, **Then** vê a lista dos comandos executados na sessão atual.

---

### User Story 3 - Trabalhar com o dialeto certo do banco (Priority: P3)

Um desenvolvedor quer confirmar quais tipos de coluna são válidos para o banco escolhido, consultar o estado atual do schema, e retomar um projeto salvo anteriormente em vez de recomeçar do zero.

**Why this priority**: Aumenta a confiança do usuário no resultado final (evita erros de tipo por banco) e a conveniência de reabrir trabalho anterior, mas o produto já é utilizável sem isso no primeiro uso.

**Independent Test**: Pode ser testado executando `show types` em um projeto PostgreSQL e confirmando que a lista reflete os tipos daquele dialeto, fechando o LazyForge e reabrindo o mesmo projeto salvo, confirmando que a estrutura é restaurada integralmente.

**Acceptance Scenarios**:

1. **Given** um projeto com banco definido como PostgreSQL, **When** o usuário executa `show types`, **Then** vê somente os tipos de coluna válidos para PostgreSQL.
2. **Given** um projeto salvo anteriormente em `./lazyforge_projects`, **When** o usuário reabre esse projeto ao iniciar o LazyForge, **Then** todas as tabelas, colunas e relacionamentos são restaurados exatamente como estavam.
3. **Given** um projeto em andamento, **When** o usuário executa `show database` ou `show tables`, **Then** vê respectivamente o banco configurado e a lista de tabelas atuais.

---

### Edge Cases

- Comando referencia uma tabela, coluna ou tipo inexistente → mensagem de erro clara, schema inalterado.
- Usuário tenta remover uma tabela ou coluna referenciada por uma chave estrangeira (ver FR-013 para a regra exata de bloqueio/confirmação/cascata).
- Usuário troca o banco do projeto (`set database`) e colunas existentes usam tipos que não existem no novo dialeto → sistema deve recusar a troca ou listar as colunas em conflito, sem aplicar uma troca parcial.
- Usuário usa `options(...)` em um tipo de coluna que não suporta enumeração → comando rejeitado com explicação.
- Usuário tenta criar uma FK entre colunas de tipos incompatíveis → comando rejeitado.
- Nome de tabela/coluna contém espaços, caracteres especiais ou é uma palavra reservada do SQL → comando rejeitado com orientação de nomes válidos.
- Usuário executa `export` com o schema vazio → sistema avisa que não há nada para exportar, sem gerar arquivo.
- Usuário executa `export` para um arquivo já existente (ver FR-014 para a regra exata de sobrescrita/confirmação).
- Terminal é pequeno demais para exibir a visualização em grafo → sistema ajusta a visualização (rolagem/resumo) em vez de travar ou cortar informação crítica silenciosamente.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST permitir criar um novo projeto escolhendo o banco de dados alvo entre PostgreSQL, MySQL ou SQLite.
- **FR-002**: O sistema MUST permitir reabrir um projeto salvo anteriormente, restaurando toda a estrutura (tabelas, colunas, chaves e relacionamentos).
- **FR-003**: O sistema MUST salvar os projetos em `./lazyforge_projects`.
- **FR-004**: O sistema MUST permitir criar, remover e renomear tabelas via comando de texto (`create table`, `delete table`/`drop table`, `rename table`/`change table`).
- **FR-005**: O sistema MUST permitir adicionar colunas a uma tabela, especificando nome, tipo, se é chave primária (`as pk`), valores permitidos (`options(...)`) e descrição (`description(...)`).
- **FR-006**: O sistema MUST permitir alterar o tipo de uma coluna existente e renomear colunas via comando de texto.
- **FR-007**: O sistema MUST permitir definir qual coluna de uma tabela é a chave primária (`set pk`).
- **FR-008**: O sistema MUST permitir criar uma chave estrangeira entre uma coluna de uma tabela e a coluna de outra tabela (`add fk ... references ...`), aceitando o comando somente se a tabela e a coluna referenciadas existirem.
- **FR-009**: O sistema MUST permitir trocar o banco de dados alvo do projeto (`set database`) em qualquer momento.
- **FR-010**: O sistema MUST validar os tipos de coluna de acordo com o banco de dados ativo do projeto, e disponibilizar um comando (`show types`) que lista os tipos aceitos para esse banco.
- **FR-011**: O sistema MUST impedir a existência de duas tabelas com o mesmo nome no mesmo projeto, e de duas colunas com o mesmo nome na mesma tabela.
- **FR-012**: O sistema MUST atualizar automaticamente qualquer chave estrangeira que aponte para uma tabela ou coluna renomeada, para que ela continue referenciando o elemento correto.
- **FR-013**: O sistema MUST [NEEDS CLARIFICATION: ao remover uma tabela ou coluna referenciada por uma FK, o sistema deve bloquear a remoção, pedir confirmação explícita, ou remover a FK junto automaticamente?]
- **FR-014**: O sistema MUST [NEEDS CLARIFICATION: ao exportar para um nome de arquivo que já existe, o sistema deve sobrescrever automaticamente ou pedir confirmação antes?]
- **FR-015**: O sistema MUST [NEEDS CLARIFICATION: o projeto deve ser salvo em disco automaticamente a cada comando aplicado com sucesso, ou somente quando o usuário executa um comando explícito de salvar?]
- **FR-016**: O sistema MUST exibir qualquer alteração de schema na visualização de estrutura e relacionamentos imediatamente após o comando ser aplicado com sucesso.
- **FR-017**: O sistema MUST exibir, via comando, o banco ativo do projeto (`show database`), a lista de tabelas (`show tables`) e o histórico de comandos executados na sessão (`history`).
- **FR-018**: O sistema MUST rejeitar comandos inválidos (sintaxe incorreta, referência a elemento inexistente, tipos incompatíveis) exibindo uma mensagem clara com a sintaxe correta, sem encerrar a aplicação e sem alterar o schema.
- **FR-019**: O sistema MUST permitir exportar o schema completo do projeto como um arquivo DDL SQL, no dialeto do banco ativo do projeto, no diretório atual, respeitando a ordem de criação exigida pelas chaves estrangeiras.
- **FR-020**: O sistema MUST incluir no DDL exportado a descrição de uma coluna como comentário, quando o banco ativo do projeto suportar esse recurso.
- **FR-021**: O sistema MUST criar a chave primária com autoincremento no formato nativo do banco ativo (serial/identity para PostgreSQL, AUTO_INCREMENT para MySQL, AUTOINCREMENT para SQLite) quando a opção `--autoincrement` for usada.
- **FR-022**: O sistema MUST ser totalmente operável usando apenas o teclado, sem exigir uso de mouse em nenhum fluxo.
- **FR-023**: O sistema MUST permitir sair da aplicação por meio de uma tecla dedicada (`q`), sem depender exclusivamente de `Ctrl+C`.

### Key Entities *(include if feature involves data)*

- **Projeto**: Representa um schema em edição; possui um banco de dados alvo (PostgreSQL, MySQL ou SQLite), um conjunto de tabelas, e um histórico de comandos da sessão. É salvo e reaberto a partir de `./lazyforge_projects`.
- **Tabela**: Elemento nomeado do schema que agrupa colunas; possui um nome único dentro do projeto e pode ser origem ou destino de relacionamentos (chaves estrangeiras).
- **Coluna**: Pertence a uma tabela; possui nome (único dentro da tabela), tipo (validado conforme o banco do projeto), indicação de chave primária, valores permitidos opcionais (enum) e descrição opcional.
- **Relacionamento (Chave Estrangeira)**: Liga uma coluna de uma tabela a uma coluna de outra tabela; exige que ambas existam e sejam de tipos compatíveis; é atualizado automaticamente quando a tabela/coluna referenciada é renomeada.
- **Banco de Dados Alvo**: Dialeto escolhido para o projeto (PostgreSQL, MySQL ou SQLite); determina os tipos de coluna válidos e o formato do DDL exportado.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um usuário novo consegue criar 3 tabelas relacionadas por chave primária e chave estrangeira, e exportar o DDL correspondente, em menos de 5 minutos.
- **SC-002**: 100% dos arquivos DDL gerados a partir de schemas válidos executam sem erro no banco de dados escolhido (PostgreSQL, MySQL ou SQLite).
- **SC-003**: Nenhum comando inválido encerra a aplicação ou deixa o projeto em um estado inconsistente.
- **SC-004**: Toda alteração de schema aplicada com sucesso é refletida na visualização em menos de 1 segundo.
- **SC-005**: Um usuário consegue reabrir um projeto salvo e retomar o trabalho sem perder nenhuma tabela, coluna ou relacionamento previamente criado.

## Assumptions

- O LazyForge opera inteiramente offline, sem se conectar a uma instância real de banco de dados para ler ou aplicar o schema (fora de escopo nesta versão).
- A interface é somente de texto/teclado; não há suporte a mouse ou interface gráfica.
- O export de diagrama Mermaid ER não faz parte desta versão (candidato a versão futura).
- O usuário tem conhecimento básico de modelagem relacional (tabelas, colunas, chaves primárias e estrangeiras) e dos três bancos suportados.
- Cada projeto corresponde a um único schema e a um único banco de dados alvo por vez; trocar o banco (`set database`) afeta o projeto inteiro, não tabelas individuais.
- O terminal do usuário suporta cores e navegação interativa (compatível com os temas nativos do framework de TUI utilizado).
