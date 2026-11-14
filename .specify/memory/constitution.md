<!--
Sync Impact Report
- Version change: 2.0.0 → 2.0.0 (constituição 2.0.0 ainda não commitada neste
  repositório; esta emenda é aplicada sobre o rascunho em working tree, sem
  bump de versão além de atualizar a data de última emenda, conforme
  instrução explícita do usuário).
- Princípio adicionado: VIII. Estabilidade do que Já Existe (NON-NEGOTIABLE).
- Princípio modificado: VII. Simplicidade e Respeito ao que Já Funciona → VII.
  Simplicidade Deliberada — a parte sobre "respeito ao que já foi entregue /
  não mudar comportamento liberado sem justificativa" foi fundida e movida
  para o novo princípio VIII, para não haver duplicidade; o princípio VII
  manteve apenas a regra de simplicidade.
- Seção modificada: "Como Avaliar uma Proposta" — adicionada a pergunta 7
  sobre preservação integral do comportamento em produção.
- Seções removidas: nenhuma.
- Correção clerical (sem impacto de versão): as duas referências a um arquivo
  `AGENTS.md` (que não existe no repositório) foram corrigidas para apontar
  ao arquivo real de orientação operacional, `.github/docs/context-tech.md`,
  identificado como inconsistência (finding I2) na análise do
  `/speckit-analyze` da spec 001-fix-graph-relation-lines.
- Follow-up TODOs: TODO(ESCOPO_SUPORTE_MULTIUSUARIO) mantido sem alteração
  (ver seção "O que o LazyForge Não É").
- Templates dependentes (plan/spec/tasks) leem este arquivo em tempo de
  execução e não foram alterados nesta corrida, conforme o escopo do skill.
-->

# LazyForge Constitution

## Propósito e Público

O LazyForge é uma IDE de terminal (TUI), operada pelo teclado, para modelar
schemas de banco de dados relacional (PostgreSQL, MySQL e SQLite) e exportar o
DDL SQL correspondente. É inspirado no espírito do LazyGit e do LazyVim:
ferramentas de terminal rápidas, memorizáveis, que o desenvolvedor não quer
abandonar. O projeto já está em produção, publicado no pub.dev; o que existe
hoje é a base sobre a qual tudo evolui.

O usuário é o desenvolvedor que já vive no terminal e não quer trocar de
interface — navegador, app desktop, diagramador visual — só para desenhar um
schema. O problema que o LazyForge resolve é permitir que esse usuário vá de
uma ideia de modelo a um DDL pronto sem sair do terminal.

Esta constituição é o documento contra o qual toda spec, plano, tarefa e
implementação futuras são avaliadas. Ela não trata de linguagem, framework,
estrutura de pastas ou convenções de código — isso é orientação operacional e
vive em `.github/docs/context-tech.md`. Aqui vivem os valores, os princípios de produto e os
critérios que decidem se uma ideia de funcionalidade pertence ao LazyForge.

## Core Principles

### I. Interface a Serviço da Decisão
Cada elemento na tela DEVE existir para comunicar um estado ou ajudar o usuário
a tomar uma decisão. Elementos puramente decorativos, ruído visual, ou
informação redundante DEVEM ser removidos. Toda ação do usuário DEVE produzir
feedback imediato e inequívoco. Toda mensagem de erro DEVE ser escrita em
linguagem humana, clara e acionável — nunca stack trace ou exceção bruta.
Justificativa: numa ferramenta de produtividade usada repetidamente, cada
elemento sem propósito funcional é custo cognitivo pago a cada sessão de uso.

### II. Comandos que Falam SQL
A linguagem de comandos DEVE soar familiar para quem já conhece SQL (por
exemplo, criar/alterar/remover tabelas e colunas, renomear, declarar chaves
estrangeiras). Um usuário experiente em SQL DEVE conseguir adivinhar a forma de
um comando novo sem consultar documentação. A gramática DEVE ser consistente:
um comando novo NUNCA deve contradizer o padrão estabelecido por comandos
anteriores. Atalhos e sinônimos SÃO permitidos quando reduzem esforço, desde
que não introduzam ambiguidade sobre qual ação será executada.
Justificativa: a familiaridade com SQL é o atalho mental que o usuário já tem;
desperdiçá-la com uma sintaxe própria e arbitrária anula a vantagem de ser uma
ferramenta "para quem já pensa em SQL".

### III. Resultado Portável, Nunca Aprisionado
O que o LazyForge produz DEVE poder ser usado fora dele. O DDL exportado DEVE
ser SQL puro e padrão do engine escolhido. Os arquivos de projeto DEVEM
permanecer arquivos simples e legíveis no diretório de trabalho, versionáveis
em git. Toda evolução do produto DEVE preferir formatos abertos e legíveis a
formatos proprietários ou opacos. A direção de produto é buscar integrações
que levem o resultado do LazyForge para outras ferramentas de apoio ao
desenvolvimento (migrations, versionamento, outros clientes); isso é direção,
não uma capacidade já entregue além de exportar SQL e salvar arquivos legíveis.
Justificativa: um modelador de schema que prende o usuário dentro de si mesmo
compete com o próprio fluxo de trabalho que deveria servir.

### IV. Terminal do Início ao Fim
O teclado DEVE ser o modo primário de operação; nenhum fluxo essencial DEVE
exigir o mouse. Nenhuma funcionalidade DEVE exigir que o usuário troque de
contexto (navegador, app externo) para completar uma tarefa de modelagem.
Toda funcionalidade proposta DEVE declarar, de forma concreta, qual problema
real de usabilidade ela resolve para quem modela schemas no terminal; ideias
vagas, genéricas ou justificadas apenas por "pode ser útil algum dia" DEVEM ser
recusadas.
Justificativa: o valor do LazyForge é poupar tempo e esforço de quem já vive
no terminal; qualquer desvio desse compromisso devolve o custo que a ferramenta
existe para eliminar.

### V. Velocidade Percebida como Requisito
A interface DEVE responder a cada comando de forma perceptivelmente instantânea,
inclusive com schemas grandes (muitas tabelas e colunas). O grafo de tabelas e
relacionamentos DEVE refletir o resultado de cada comando imediatamente.
Performance NÃO é uma otimização a ser feita depois: é um requisito de produto
avaliado junto com qualquer funcionalidade nova, e uma proposta que arrisque
travar a interface DEVE ser redesenhada antes de ser aceita.
Justificativa: a comparação do usuário não é com outro modelador de schema, é
com a velocidade de digitar um comando no próprio terminal; qualquer lentidão
perceptível quebra essa expectativa.

### VI. Confiança Desde o Primeiro Comando
A ferramenta DEVE parecer sólida já na primeira execução: tela inicial,
primeiro comando, primeira mensagem de erro. O trabalho do usuário DEVE ser
salvo automaticamente e NUNCA deve se perder de forma inesperada. O usuário
DEVE poder consultar o histórico de comandos e obter ajuda embutida sem sair
do fluxo. O mesmo modelo mental de comandos DEVE servir igualmente a
PostgreSQL, MySQL e SQLite — o usuário escolhe o engine e a ferramenta se
adapta (tipos válidos, DDL correto), sem exigir que ele aprenda um fluxo
diferente por banco.
Justificativa: confiança é construída ou destruída nos primeiros segundos de
uso; e um modelador que trata os três engines como fluxos distintos impõe ao
usuário uma carga que a ferramenta deveria absorver.

### VII. Simplicidade Deliberada
Toda solução DEVE resolver o problema declarado da forma mais direta possível;
abstrações ou complexidade adicionadas "para o futuro" sem necessidade
comprovada no presente DEVEM ser recusadas.
Justificativa: simplicidade mantém o produto rápido de entender e de evoluir.

### VIII. Estabilidade do que Já Existe (NON-NEGOTIABLE)
O LazyForge está em produção e há pessoas usando-o hoje. Nenhuma mudança PODE
causar regressão de comportamento de nenhuma espécie: comandos que funcionam
hoje DEVEM continuar aceitos, com o mesmo significado e o mesmo resultado; o
que o usuário já modelou, salvou ou exportou DEVE continuar abrindo e
produzindo o mesmo resultado; atalhos, interações e fluxos existentes NÃO
PODEM ser removidos ou alterados silenciosamente. O código liberado é a fonte
da verdade sobre o que o produto faz; specs, planos e tarefas antigos são só
histórico e NUNCA são motivo para reescrever ou "corrigir" o que já funciona.
Mudar ou remover um comportamento existente só é aceitável com uma spec nova
que declare exatamente essa mudança e justifique o impacto para quem já usa.
Justificativa: um usuário que confia no comportamento atual não deve ser
surpreendido por uma mudança não anunciada; sem essa barreira, cada novo ciclo
de evolução arrisca regredir funcionalidade já validada em produção.

## Como Avaliar uma Proposta

Toda spec, plano ou revisão de funcionalidade DEVE poder responder "sim" às
perguntas abaixo antes de ser aceita. Uma resposta "não" exige redesenho ou
recusa da proposta:

1. A funcionalidade resolve um problema concreto de usabilidade para quem
   modela schemas no terminal — e não algo vago ou "pode ser útil um dia"?
2. O fluxo permanece inteiramente no teclado e no terminal, sem exigir mouse
   nem troca de contexto para outra ferramenta?
3. Se envolve comando, sua sintaxe é adivinhável por alguém que já conhece SQL,
   e é consistente com os comandos que já existem?
4. O resultado produzido (arquivo de projeto, DDL exportado) continua
   aproveitável fora do LazyForge, em formato aberto e legível?
5. A resposta da interface a essa funcionalidade continua perceptivelmente
   instantânea, mesmo em schemas grandes?
6. Se a proposta muda comportamento já liberado, ela declara explicitamente o
   quê muda e por quê — em vez de alterar silenciosamente o que já funciona?
7. Isso preserva integralmente o comportamento que já está em produção (ou
   declara e justifica explicitamente a mudança)?

## O que o LazyForge Não É

- Não é uma ferramenta gráfica ou web de diagramação de schema; é um TUI de
  terminal.
- Não executa o DDL contra um banco de dados nem administra conexões ativas;
  ele modela e exporta SQL, não aplica migrations nem gerencia instâncias.
- Não é um cliente SQL de uso geral (não roda queries arbitrárias, não navega
  dados de tabelas existentes); seu escopo é a modelagem do schema e a geração
  do DDL correspondente.

TODO(ESCOPO_SUPORTE_MULTIUSUARIO): não há, hoje, evidência no código ou nos
documentos do projeto sobre uso colaborativo/multiusuário do mesmo projeto;
este limite fica propositalmente em aberto até haver uma decisão explícita.

## Governance

Esta constituição tem precedência sobre qualquer prática informal ou
preferência individual de implementação dentro do LazyForge, e é o documento
de maior precedência depois do próprio código já liberado em produção.

- **Emendas**: qualquer alteração a esta constituição DEVE ser proposta
  explicitamente, com justificativa registrada no Sync Impact Report da
  emenda correspondente. Não há alteração silenciosa de princípio.
- **Versionamento semântico**: a versão segue MAJOR.MINOR.PATCH — MAJOR para
  remoção ou redefinição incompatível de princípios (incluindo reescritas
  completas como esta); MINOR para adição de novo princípio ou expansão
  material de um princípio existente; PATCH para esclarecimentos e correções
  de texto sem mudança de sentido.
- **Conformidade**: toda spec, plano técnico ou revisão de funcionalidade DEVE
  ser verificada contra os princípios e o checklist desta constituição antes de
  ser aceita. A ausência dessa verificação é motivo suficiente para recusa.
- **Relação com outros documentos**: orientação técnica e operacional
  (linguagem, estrutura de pastas, convenções de código, política de testes,
  fluxo de desenvolvimento) não pertence a este documento e vive em
  `.github/docs/context-tech.md`; em caso de conflito, o código liberado prevalece sobre esta
  constituição, que por sua vez prevalece sobre `.github/docs/context-tech.md`.

**Version**: 2.0.0 | **Ratified**: 2026-10-03 | **Last Amended**: 2026-10-08
