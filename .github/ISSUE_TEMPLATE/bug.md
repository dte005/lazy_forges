---
name: Bug
about: Reportar um comportamento incorreto no LazyForge
title: '[bug] '
labels: bug
assignees: ''
---

<!--
Título: [bug] + o que está errado. Ex.: [bug] Linhas de relacionamento estão transpassando tabelas
Esta issue é a fonte de verdade para um agente de IA criar a spec da correção, o plan, as tasks e implementar.
Preencha as seções acima da linha "Diretivas para o agente" de forma autossuficiente. Não edite as diretivas.
-->

## Descrição do bug
<!-- O que acontece de errado e qual o efeito para o usuário. -->

## Como reproduzir
1.
2.
3.

**Comando(s) executado(s), se houver:**
```
```

## Comportamento esperado
<!-- O que deveria acontecer. -->

## Comportamento atual
<!-- O que acontece de fato. Cole a mensagem de erro ou a saída do terminal, se houver. -->

## Causa provável (se souber)
<!-- Arquivo e função suspeitos. Escreva N/A se não souber. -->

## Screenshots
<!-- Imagens ou gravação do terminal. Escreva N/A se não houver. -->

## Ambiente
- Sistema operacional (ex.: Windows 11, macOS 14, Ubuntu, WSL):
- Terminal (ex.: Windows Terminal, iTerm2, GNOME Terminal):
- Versão do LazyForge (`pubspec.yaml` ou pub.dev):
- Versão do Dart:
- Banco do projeto (PostgreSQL, MySQL ou SQLite):

## Gravidade
- [ ] Trava ou encerra a aplicação / perde dados
- [ ] Gera resultado errado (DDL, schema, visualização)
- [ ] Incômodo visual ou de uso, sem perda de dados

## Critérios de aceite
<!-- Como saber que o bug foi corrigido, em formato Given/When/Then. -->
- [ ] Given ..., When ..., Then ...

## Fora de escopo
<!-- O que NÃO deve ser alterado nesta correção. -->

## Como validar manualmente
<!-- Passos que o mantenedor executa no app para confirmar a correção. -->
1.
2.

## Contexto adicional
<!-- Escreva N/A se não houver. -->

---

## Diretivas para o agente de IA (não editar)

Esta issue é o ponto de partida. A versão alvo é a do **milestone** desta issue.

**1. Leia antes de agir**
- Esta issue inteira (`gh issue view <número>`).
- `.specify/memory/constitution.md` e `AGENTS.md`.
- `specs/002-v0-1-baseline/spec.md` e `plan.md` (baseline liberado; **somente leitura**). Verifique se o
  comportamento reportado consta nas "Lacunas Conhecidas" da baseline.
- O código existente em `lib/` é a fonte da verdade.

**2. Antes de especificar**
- Reproduza ou localize a causa raiz no código. Registre a causa na spec; não corrija sintomas.
- Se o comportamento descrito for, na verdade, o comportamento documentado na baseline, pare e informe o
  mantenedor: pode ser uma melhoria (`[feature]`) e não um bug.

**3. Fluxo Spec Kit (nesta ordem, comandos com hífen)**
1. `/speckit-specify` usando o conteúdo desta issue. A spec nasce com `Status: Planned`, a linha
   `Source issue: #<número>`, e descreve o comportamento correto esperado e a causa raiz.
2. `/speckit-clarify` somente se restar ambiguidade real.
3. `/speckit-plan` com a correção mínima necessária e o Constitution Check.
4. `/speckit-tasks` com tarefas pequenas e só do escopo da correção.
5. `/speckit-analyze` (somente leitura).
6. `/speckit-implement` apenas se a spec estiver `Planned` e o Constitution Check estiver PASS.

**4. Restrições obrigatórias**
- Correção mínima: não refatore nem mude comportamento fora do escopo desta issue.
- Não alterar `specs/001-*` nem `specs/002-*`.
- Manter a leitura de projetos JSON já salvos em `lazyforge_projects/`.
- Respeitar a estrutura `lib/src/{components,providers,model,storage,services}`; usar `ColumnDef`, nunca `Column`.
- Confirmar a API do `nocterm` no código instalado antes de usá-la.
- Não adicionar dependência ao `pubspec.yaml` sem perguntar ao mantenedor.
- Não criar nem expandir testes automatizados (a constituição não os exige).
- Mensagens ao usuário em português, claras e sem stack trace.

**5. Entrega**
- Trabalhe em uma branch própria, nunca direto na `master`.
- Não faça commit, push nem abra PR sem confirmação do mantenedor. O PR deve conter `Closes #<número>`.
- Ao concluir e validar manualmente, mude o status da spec para `Implemented`.
- Se a `version` do `pubspec.yaml` e o `CHANGELOG.md` não corresponderem ao milestone desta issue, pergunte ao
  mantenedor antes de alterá-los.

**6. Referências do Spec Kit**: skills em `.github/skills/speckit-*/SKILL.md` e templates em `.specify/templates/`.
