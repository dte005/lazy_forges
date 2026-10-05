---
name: Feature
about: Propor uma nova funcionalidade ou melhoria para o LazyForge
title: '[feature] '
labels: enhancement
assignees: ''
---

<!--
Título: [feature] + verbo no infinitivo + o que muda. Ex.: [feature] Desenvolver tecla 'q' para sair
Esta issue é a fonte de verdade para um agente de IA criar a spec, o plan, as tasks e implementar.
Preencha as seções acima da linha "Diretivas para o agente" de forma autossuficiente: quem ler
só esta issue deve entender o pedido sem consultar mais nada. Não edite as diretivas.
Toda funcionalidade deve resolver um problema concreto de usabilidade; pedidos vagos não são aceitos.
-->

## Problema de usabilidade
<!-- Quem sofre, em que situação e qual o efeito concreto ao modelar schemas no terminal. -->

## Comportamento atual
<!-- O que o app faz hoje nessa situação. Cite arquivo e função quando souber
     (ex.: CommandsProvider._handleDeleteTable em lib/src/providers/editor/editor_provider.dart). -->

## Solução desejada
<!-- O que deve passar a acontecer. Se envolver comando, informe a sintaxe e a mensagem exibida. -->

**Sintaxe proposta (se houver comando):**
```
```

## Critérios de aceite
<!-- Verificáveis, em formato Given/When/Then. -->
- [ ] Given ..., When ..., Then ...
- [ ] Given ..., When ..., Then ...

## Impacto no comportamento atual
<!-- Marque uma opção. -->
- [ ] Aditivo: não altera nada que já funciona hoje
- [ ] Muda comportamento já liberado (justifique abaixo por que a mudança é aceitável)

**Justificativa (se muda comportamento):**

## Bancos afetados
- [ ] PostgreSQL
- [ ] MySQL
- [ ] SQLite
- [ ] Todos / não se aplica

## Fora de escopo
<!-- O que NÃO deve ser alterado nesta issue. -->

## Como validar manualmente
<!-- O projeto não exige testes automatizados. Passos que o mantenedor executa no app. -->
1.
2.

## Alternativas consideradas
<!-- Escreva N/A se não houver. -->

## Contexto adicional
<!-- Prints, links, issues relacionadas. Escreva N/A se não houver. -->

---

## Diretivas para o agente de IA (não editar)

Esta issue é o ponto de partida. A versão alvo é a do **milestone** desta issue.

**1. Leia antes de agir**
- Esta issue inteira (`gh issue view <número>`).
- `.specify/memory/constitution.md` (constituição; precedência máxima sobre práticas informais).
- `AGENTS.md` (convenções do projeto).
- `specs/002-v0-1-baseline/spec.md` e `plan.md` (baseline do que já está liberado; **somente leitura**).
- O código existente em `lib/` é a fonte da verdade sobre o comportamento atual.

**2. Fluxo Spec Kit (nesta ordem, comandos com hífen)**
1. `/speckit-specify` usando o conteúdo desta issue como descrição da feature.
   - A spec nasce com `Status: Planned` e a linha `Source issue: #<número>`.
   - Declara que estende a baseline `002-v0-1-baseline` e não altera comportamento fora do escopo.
2. `/speckit-clarify` somente se restar ambiguidade real; prefira registrar a decisão a perguntar o óbvio.
3. `/speckit-plan` seguindo a estrutura real do código e o Constitution Check.
4. `/speckit-tasks` com tarefas pequenas, ordenadas e só do escopo desta issue.
5. `/speckit-analyze` (somente leitura) e corrija inconsistências na documentação.
6. `/speckit-implement` apenas se a spec estiver `Planned` e o Constitution Check estiver PASS.

**3. Restrições obrigatórias**
- Não alterar `specs/001-*` nem `specs/002-*`, e não mudar comportamento liberado fora do escopo desta issue.
- Se esta issue marcar "Muda comportamento", a spec deve registrar a justificativa e a mudança deve ser exatamente a descrita.
- Manter a leitura de projetos JSON já salvos em `lazyforge_projects/` (campos novos são opcionais).
- Respeitar a estrutura: `lib/src/{components,providers,model,storage,services}`; parsing de comandos fora de `components/`; usar `ColumnDef`, nunca `Column`; sem `index.dart`.
- Confirmar a API do `nocterm` no código instalado localmente antes de usá-la. Não presumir de memória.
- Não adicionar dependência ao `pubspec.yaml` sem perguntar ao mantenedor.
- Não criar nem expandir testes automatizados (a constituição não os exige).
- Mensagens ao usuário em português, claras e acionáveis; nunca expor stack trace.
- Funcionalidade nova ou tela nova deve oferecer a tecla `q` para sair.
- Simplicidade: nada de abstração "para o futuro".

**4. Entrega**
- Trabalhe em uma branch própria, nunca direto na `master`.
- Não faça commit, push nem abra PR sem confirmação do mantenedor. O PR deve conter `Closes #<número>`.
- Atualize `README.md` se comandos ou comportamento visíveis mudarem.
- Ao concluir e validar manualmente, mude o status da spec para `Implemented`.
- Se a `version` do `pubspec.yaml` e o `CHANGELOG.md` não corresponderem ao milestone desta issue, pergunte ao mantenedor antes de alterá-los.

**5. Referências do Spec Kit**: skills em `.github/skills/speckit-*/SKILL.md` e templates em `.specify/templates/`.
