<!--
Sync Impact Report
- Version change: 1.1.0 → 1.2.0 (minor: amendment aligns governance text with
  the actual released v0.1 codebase; no principle removed/redefined, several
  clarified and corrected to match reality)
- Modified principles:
  - VI. Código Limpo e Estrutura Organizada (NON-NEGOTIABLE) — folder list
    corrected from `model/`, `commands/`, `ui/`, `export/` to the real
    structure `lib/src/components/`, `lib/src/providers/`, `lib/src/model/`,
    `lib/src/storage/`, `lib/src/services/`; dropped the mandatory
    per-folder-barrel and always-import-the-public-barrel rules (not how the
    codebase works); kept: no `index.dart`, public/private (`lib/` vs
    `lib/src/`) separation, and command parsing kept out of UI components.
  - II. Comandos Intuitivos e Previsíveis (NON-NEGOTIABLE) — removed the
    `export schema` / `export erd` command examples (not real commands); the
    real command is `export [nome]`.
  - IV. Performance como Critério Primário de Qualidade — removed the
    "Mermaid ERD" export example (out of scope in v0.1, not an existing
    feature).
  - III. Clareza Acima da Estética Vazia — clarified gruvbox as a preference,
    not an obligation; v0.1 actually ships with `nocterm`'s native dark theme.
  - VIII. Preservação do Código Liberado (NON-NEGOTIABLE) — extended the spec
    status gate language to also cover "Draft" and "Superseded" statuses
    (previously only "Implemented" was mentioned as blocking).
- Added sections/clarifications:
  - Padrões de Produto, UX e Qualidade: new bullet clarifying mouse-driven
    interactions already present in v0.1 (sair, fechar/copiar no Help) must
    not be removed without a new spec; keyboard remains the primary mode.
  - Padrões de Produto, UX e Qualidade: expanded "Sem suíte de testes
    automatizados" bullet to state the existing `test/` directory must not be
    expanded without explicit approval.
  - Fluxo de Desenvolvimento e Estrutura Técnica: clarified that the
    dedicated `q` exit key requirement applies to new work; v0.1 as released
    exits via `Esc` on the initial screen and a UI "sair" action in the
    editor — this is a recorded gap (see baseline spec), not something to be
    silently "fixed" outside of its own spec.
  - Governance: "Gate de status de spec" bullet reworded to explicitly list
    the only status that permits `/speckit.implement` ("Planned") and to
    explicitly name the statuses that must be refused ("Implemented",
    "Draft", "Superseded").
- Removed sections: none
- Deferred TODOs: none
- Templates requiring follow-up: none checked in this run (scope limited to
  constitution per skill instructions); dependent templates (plan/spec/tasks)
  read this file at runtime and were not modified here.
-->

# LazyForge Constitution

## Core Principles

### I. Usabilidade é o Objetivo de Toda Funcionalidade
Toda funcionalidade proposta DEVE declarar, antes de ser implementada, qual problema
concreto de usabilidade ela resolve para quem modela schemas de banco de dados no
terminal. Funcionalidades vagas, genéricas, ou justificadas apenas por "pode ser
útil algum dia" são REJEITADAS na revisão de design. Se uma funcionalidade não
reduz esforço, ambiguidade, ou tempo de tarefa do usuário, ela não é aceita.
Justificativa: um TUI de produtividade só tem valor se cada peça adicionada
melhorar mensuravelmente a experiência de uso; funcionalidades decorativas ou
especulativas diluem foco e aumentam superfície de manutenção sem retorno.

### II. Comandos Intuitivos e Previsíveis (NON-NEGOTIABLE)
Comandos de texto (`create table`, `add column ... type ...`, `export [nome]`)
DEVEM seguir uma gramática consistente, verbos previsíveis, e
mensagens de erro acionáveis que expliquem o que o usuário deve fazer a seguir.
Uma ferramenta de terminal cujo comportamento de comando confunde o usuário, exige
tentativa e erro, ou quebra expectativas estabelecidas por comandos anteriores é
considerada um FRACASSO de produto, independentemente de sua implementação técnica.
Toda nova sintaxe de comando DEVE ser validada contra a pergunta: "um usuário
experiente adivinharia isso sem documentação?".

### III. Clareza Acima da Estética Vazia
Decisões de UI (cores, layout, símbolos, espaçamento) DEVEM priorizar legibilidade
e comunicação de estado sobre efeitos visuais. Qualquer elemento visual que não
ajude o usuário a entender o estado do schema, a navegação atual, ou o resultado
de uma ação DEVE ser removido ou simplificado. O tema gruvbox é uma preferência
declarada, não uma obrigação: a v0.1 liberada usa o tema `dark` nativo do
`nocterm`. Qualquer tema usado (gruvbox ou outro tema nativo do `nocterm`) DEVE
reforçar hierarquia visual, nunca decoração gratuita.

### IV. Performance como Critério Primário de Qualidade
Toda interação do usuário (digitar comando, navegar telas, exportar schema) DEVE
responder de forma perceptivelmente instantânea. Operações de renderização,
parsing de comando, e exportação (DDL SQL) NÃO DEVEM introduzir bloqueios
perceptíveis na interface, mesmo com schemas grandes (dezenas de tabelas,
centenas de colunas). Performance é tratada como requisito funcional,
não como otimização posterior: qualquer funcionalidade que degrade a
responsividade do terminal DEVE ser revisada antes de ser aceita.

### V. Credibilidade e Confiança Imediata
A ferramenta DEVE parecer e se comportar como software comercial desde a primeira
execução: sem telas quebradas, sem mensagens de erro técnicas expostas ao usuário
final, sem comportamento inconsistente entre comandos semelhantes. Erros de
parsing ou de estado DEVEM ser comunicados em linguagem clara, nunca como stack
traces ou exceções brutas. A primeira impressão (tela inicial, primeiro comando,
primeira mensagem de erro) é tratada como superfície crítica de confiança do
produto.

### VI. Código Limpo e Estrutura Organizada (NON-NEGOTIABLE)
O código DEVE seguir a separação pública/privada do Dart (`lib/` vs `lib/src/`) e
a estrutura de pastas real do projeto: `lib/src/components/` (UI),
`lib/src/providers/` (estado da aplicação e parsing/despacho de comandos),
`lib/src/model/` (entidades de domínio), `lib/src/storage/` (persistência de
projeto e exportação do DDL) e `lib/src/services/`. Nenhuma pasta DEVE usar
`index.dart` como arquivo de barrel. Parsing de comandos do usuário DEVE viver
fora de `lib/src/components/`, nunca embutido em um componente de UI. Nomes de
classe e arquivo DEVEM seguir o guia de estilo oficial do Dart, incluindo o uso
de `ColumnDef` (não `Column`) para evitar colisão com o widget de layout do
`nocterm`. Código desorganizado, duplicado, ou com responsabilidades misturadas
DEVE ser corrigido antes de ser mesclado.

### VII. Simplicidade Deliberada, Sem Improviso
Implementações DEVEM resolver o problema declarado da forma mais direta possível.
Abstrações genéricas, camadas extras, ou padrões de design introduzidos "para o
futuro" sem necessidade comprovada no presente são REJEITADOS. Soluções
improvisadas (gambiarras, atalhos que ignoram a estrutura de pastas, ou código
copiado sem entendimento da API real do `nocterm`) NÃO SÃO ACEITÁVEIS. Antes de
usar qualquer API do `nocterm`, sua sintaxe DEVE ser confirmada no código-fonte
instalado localmente — nunca assumida por memória ou suposição.

### VIII. Preservação do Código Liberado (NON-NEGOTIABLE)
A v0.1 está em produção; o código existente é a fonte da verdade sobre o
comportamento real do sistema, e tem precedência sobre qualquer spec, plano ou
tarefa escrita antes da liberação. Specs, plans e tasks da baseline (v0.1) são
documentação de referência histórica — elas registram o que foi decidido e por
quê, mas NUNCA DEVEM ser reinterpretadas como instruções para recriar, reescrever
ou "corrigir" código já liberado. Nenhuma mudança de comportamento já liberado
DEVE ser aplicada sem uma spec nova, específica, que declare e justifique
exatamente essa mudança. `/speckit.implement` DEVE atuar somente sobre specs
marcadas com status "Planned"; specs marcadas como "Implemented", "Draft" ou
"Superseded" NUNCA DEVEM ser usadas como entrada para `/speckit.implement`.
Justificativa: sem essa barreira, cada novo ciclo de spec/plan/tasks arrisca
reexecutar ou regredir funcionalidade já validada em produção, corrompendo um
sistema que usuários reais já dependem.

## Padrões de Produto, UX e Qualidade

Esta seção define padrões obrigatórios de produto que complementam os princípios
centrais:

- **Sem suíte de testes automatizados**: este projeto NÃO exige testes
  automatizados (unitários, de integração, ou end-to-end) como critério de
  aceite. A validação de qualidade é feita por revisão manual de código, revisão
  de UX (comandos e telas) e verificação funcional direta durante o
  desenvolvimento (hot reload). Isso é uma decisão deliberada de escopo, não uma
  lacuna a ser preenchida futuramente sem aprovação explícita do time. O
  diretório `test/` já existente no projeto NÃO DEVE ser expandido com novos
  testes sem aprovação explícita do time, para evitar recriar por acidente uma
  exigência de suíte automatizada.
- **Teclado como modo primário, mouse existente não é removido sem spec**: a
  interface é primariamente operável pelo teclado. A v0.1 liberada já possui
  interações acionadas por clique (ex.: ação de sair, e fechar/copiar na tela de
  Help); essas interações existentes NÃO DEVEM ser removidas sem uma spec nova
  que justifique a remoção — conforme o Princípio VIII (Preservação do Código
  Liberado).
- **Consistência visual**: todas as telas DEVEM usar o mesmo tema ativo, a mesma
  paleta de cores para o mesmo tipo de estado (sucesso, erro, aviso, neutro), e o
  mesmo padrão de navegação por foco (`Focusable`) em toda a aplicação.
- **Feedback imediato**: toda ação do usuário (comando aceito, comando rejeitado,
  exportação concluída) DEVE produzir feedback visual imediato e inequívoco na
  tela ativa.
- **Dependências**: nenhuma dependência nova DEVE ser adicionada ao
  `pubspec.yaml` sem antes perguntar ao usuário e justificar por que a
  funcionalidade não pode ser resolvida com o que já está disponível.

## Fluxo de Desenvolvimento e Estrutura Técnica

- **Hot reload obrigatório**: o desenvolvimento DEVE rodar com
  `dart --enable-vm-service bin/lazy_forge.dart`, aproveitando o hot reload do
  `nocterm`/`hotreloader` para mudanças em `build()`. Mudanças em `initState()`
  ou `main()` exigem reinício manual do processo.
- **Saída explícita (trabalho novo)**: para qualquer funcionalidade nova ou tela
  nova, a aplicação DEVE oferecer uma tecla explícita (`q`) que chama `exit(0)`
  de `dart:io`, sem depender apenas de `Ctrl+C`. A v0.1 liberada, como ficou
  implementada, sai pela tecla `Esc` na tela inicial e por uma ação de "sair" na
  interface do editor — isso é uma lacuna conhecida e registrada (ver spec de
  baseline da v0.1), não uma falha a ser corrigida silenciosamente fora de uma
  spec própria para essa mudança.
- **Revisão de arquitetura antes de aplicar**: qualquer mudança que toque
  `lib/src/model/` ou `lib/src/components/` DEVE ser acompanhada de uma
  explicação do motivo da escolha de arquitetura antes da aplicação do código.

## Governance

Esta constituição tem precedência sobre qualquer outra prática, convenção informal,
ou preferência individual de implementação dentro do projeto LazyForge.

- **Emendas**: qualquer alteração a esta constituição DEVE ser proposta
  explicitamente, documentada com justificativa, e registrada no Sync Impact
  Report da emenda correspondente. Não há aprovação silenciosa de mudanças de
  princípio.
- **Versionamento semântico**: a versão da constituição segue MAJOR.MINOR.PATCH:
  MAJOR para remoção ou redefinição incompatível de princípios; MINOR para
  adição de novo princípio ou expansão material de orientação existente; PATCH
  para esclarecimentos, correções de texto, ou refinamentos não semânticos.
- **Conformidade**: toda proposta de funcionalidade, plano técnico, ou revisão de
  código DEVE ser verificada contra os princípios desta constituição antes de ser
  aceita. Complexidade adicional DEVE ser justificada explicitamente por escrito;
  a ausência de justificativa é motivo suficiente para rejeição.
- **Guia de execução**: para orientação operacional do dia a dia (convenções de
  nomenclatura, armadilhas de API já identificadas, fluxo de hot reload), usar as
  instruções do agente registradas no repositório, que DEVEM permanecer
  consistentes com esta constituição.
- **Gate de status de spec**: toda spec DEVE declarar um status ("Planned",
  "Draft", "Implemented" ou "Superseded"). `/speckit.implement` DEVE atuar
  **somente** sobre specs com status "Planned", e DEVE recusar-se a atuar
  sobre qualquer spec cujo status seja "Implemented", "Draft" ou "Superseded";
  essa verificação é obrigatória antes de qualquer geração ou alteração de
  código a partir de uma spec existente.

**Version**: 1.2.0 | **Ratified**: 2026-10-03 | **Last Amended**: 2026-10-04
