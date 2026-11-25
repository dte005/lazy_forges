---
name: "speckit-analyze-fix"
description: "Runs right after /speckit-analyze: auto-fixes mechanical findings (task order, [P], skill tags, wording), asks the owner about behavior/business-rule/visual findings, then prints a final report of what is still pending."
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "lazyforge"
---

## User Input

```text
$ARGUMENTS
```

Consider the user input (if any) before proceeding.

## Goal

Process the findings of the `/speckit-analyze` report that was just produced
(use the report in the conversation; if none is available, run the analysis
read-only first). Fix what is mechanical, ask about what changes product
behavior, and finish with a report of what remains.

Single pass only: no re-analysis loop.

## Language

- Tables and messages shown to the owner: **Portuguese**.
- Anything written into `spec.md` / `plan.md` / `tasks.md`: **English**.

## Scope

Edit only Spec Kit documents in the feature directory (`spec.md`, `plan.md`,
`tasks.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`).
**Never** edit `lib/`, `bin/`, `tests/`, `pubspec.yaml`, `CHANGELOG.md`, or the
constitution. No commit, push or PR.

## Step 1 — Classify every finding

**Mechanical (auto-fix, no question):** task order, `[P]` markers, missing
task dependencies or conditions, skill tags, referenced file paths,
renumbering, terminology alignment, duplicated text, wording, stale
cross-references. These do not change what the product does.

**Ask the owner:** keys/shortcuts, new or changed behavior, business rules,
layout/color/visual/UX, user-facing messages, scope changes, anything that
conflicts with the constitution, or any choice between product alternatives.

**Doubt:** if unsure which class a finding belongs to, treat it as "ask the
owner". Never decide product behavior silently.

## Step 2 — Apply mechanical fixes

Apply each mechanical recommendation. Keep `spec.md`, `plan.md` and `tasks.md`
consistent with each other. Then show:

### Aplicado automaticamente
| ID | Categoria | Local | O que foi feito |
|----|-----------|-------|-----------------|

## Step 3 — Ask the owner

Show one table with the findings that need a decision (include the "doubt"
ones, marked in the Categoria column), each with a recommendation:

### Preciso de você
| ID | Categoria | Local | Dúvida | Recomendação |
|----|-----------|-------|--------|--------------|

Then use the ask-user tool (or wait for the reply) and **stop**. Do not apply
these before the owner answers. When answered, apply the decisions (the
owner's choice; the recommendation if they say to follow it) to the artifacts.

If there are no such findings, skip this step.

## Step 4 — Final report (read-only)

After all edits, re-read the three core artifacts once and print:

### Relatório final
| ID | Categoria | Severidade | Local | Pendência | Próximo passo |
|----|-----------|------------|-------|-----------|---------------|

List only what is still open: unanswered questions, findings not applied,
tasks not ready for `/speckit-implement`. If nothing remains, say so and
confirm the feature is ready for `/speckit-implement`. Do not loop or re-run
analyze.

## Rules

- Never invent or alter a key, command, message, layout or business rule.
- Constitution conflicts are never auto-fixed; always ask.
- Respect repository rules: only specs with status `Planned` are implementable.
