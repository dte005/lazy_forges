---
name: Refactor
about: Propor reorganização ou limpeza de código sem mudar o comportamento
title: '[refactor] '
labels: refactor
assignees: ''
---

<!--
Título: [refactor] + o que será reorganizado. Ex.: [refactor] Reorganização da estrutura do provider
Refactor não muda o comportamento visível ao usuário. Se mudar, abra uma issue [feature].
Esta issue é a fonte de verdade para um agente de IA criar a spec, o plan, as tasks e implementar.
Preencha as seções acima da linha "Diretivas para o agente" de forma autossuficiente. Não edite as diretivas.
-->

## Motivação
<!-- Que problema do código hoje justifica a mudança? (manutenção, tamanho de arquivo,
     responsabilidades misturadas, duplicação). -->

## Escopo
<!-- O que será reorganizado? Cite arquivos, pastas e classes, com trechos de código se ajudar. -->

**Estrutura alvo (se aplicável):**
```text
```

**Fora do escopo:**
<!-- O que NÃO será mexido nesta issue. -->

## Impacto
<!-- Que dificuldade atual isso resolve e o que melhora depois? -->

## Garantia de comportamento
- [ ] Nenhum comando, mensagem ou formato de arquivo muda para o usuário
- [ ] Projetos já salvos em `lazyforge_projects/` continuam abrindo normalmente
- [ ] A organização de pastas resultante é coerente com a constituição e o `AGENTS.md` (ou a emenda necessária foi proposta)

## Critérios de aceite
<!-- Verificáveis. Ex.: a classe X fica em arquivo próprio; nenhum arquivo passa de N linhas. -->
- [ ]
- [ ]

## Como validar manualmente
<!-- O projeto não exige testes automatizados. Descreva os passos de conferência de que o
     comportamento permanece idêntico (comandos a rodar, telas a abrir). -->
1.
2.

## Contexto adicional
<!-- Links, decisões anteriores. Escreva N/A se não houver. -->

---

## Diretivas para o agente de IA (não editar)

Esta issue é o ponto de partida. A versão alvo é a do **milestone** desta issue.

**1. Leia antes de agir**
- Esta issue inteira (`gh issue view <número>`).
- `.specify/memory/constitution.md` e `AGENTS.md`.
- `specs/002-v0-1-baseline/spec.md` e `plan.md` (baseline liberado; **somente leitura**). O comportamento
  descrito ali deve permanecer idêntico após o refactor.
- O código existente em `lib/` é a fonte da verdade.

**2. Fluxo Spec Kit (nesta ordem, comandos com hífen)**
1. `/speckit-specify` usando o conteúdo desta issue. A spec nasce com `Status: Planned`, a linha
   `Source issue: #<número>`, e declara explicitamente que **não há mudança de comportamento**.
2. `/speckit-clarify` somente se restar ambiguidade real.
3. `/speckit-plan` com a estrutura alvo e o Constitution Check (principalmente Princípios VI, VII e VIII).
4. `/speckit-tasks` em passos pequenos e reversíveis, cada um deixando o app funcionando.
5. `/speckit-analyze` (somente leitura).
6. `/speckit-implement` apenas se a spec estiver `Planned` e o Constitution Check estiver PASS.

**3. Restrições obrigatórias**
- Zero mudança de comportamento: mesmos comandos, mensagens, saídas de DDL e formato JSON.
- Não alterar `specs/001-*` nem `specs/002-*`.
- Estrutura: parte da organização real de `lib/src/`; parsing de comandos fora dos componentes de UI;
  usar `ColumnDef`, nunca `Column`; sem `index.dart`. Se a constituição ou o `AGENTS.md` divergirem do
  código, vale o código: avise o mantenedor.
- Se a reorganização exigir mudar a estrutura de pastas descrita na constituição, **pare** e proponha a
  emenda ao mantenedor (`/speckit-constitution`) antes de continuar.
- Para encerrar o app, usar `shutdownApp()` do nocterm, nunca `exit(0)`.
- Confirmar a API do `nocterm` no código instalado antes de usá-la.
- Não adicionar dependência ao `pubspec.yaml` sem perguntar ao mantenedor.
- Não criar nem expandir testes automatizados (a constituição não os exige).
- Simplicidade: não introduza abstrações além das necessárias para o objetivo desta issue.
- Explique o motivo da escolha de arquitetura antes de alterar `lib/src/model/` ou `lib/src/components/`.

**4. Entrega**
- Trabalhe em uma branch própria, nunca direto na `master`.
- Não faça commit, push nem abra PR sem confirmação do mantenedor. O PR deve conter `Closes #<número>`.
- Execute a validação manual descrita acima e informe o resultado.
- Ao concluir, mude o status da spec para `Implemented`.
- Se a `version` do `pubspec.yaml` e o `CHANGELOG.md` não corresponderem ao milestone desta issue, pergunte ao
  mantenedor antes de alterá-los.

**5. Referências do Spec Kit**: skills em `.github/skills/speckit-*/SKILL.md` e templates em `.specify/templates/`.
