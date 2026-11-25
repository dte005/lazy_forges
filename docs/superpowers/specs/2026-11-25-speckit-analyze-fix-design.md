# Design: `speckit-analyze-fix` skill + automatic hook (short)

## Intent and why
After `/speckit-analyze`, the owner currently answers every finding with
"follow the recommendation", including purely mechanical ones. Business-rule
decisions (e.g. the `q` key) were also made by the agent instead of being asked.
The skill separates the two: fix mechanical findings automatically, ask the
owner about everything that changes product behavior, and report what remains.

## Goals
- Run **automatically** right after `/speckit-analyze` (no manual call).
- Apply mechanical findings from the analyze report without asking.
- Ask the owner about behavior / business-rule / visual / UX findings.
- Finish with a **new report** listing the tasks/findings that remain.
- Show results on screen as categorized tables.

## Non-goals
- No catalog extension. No product code, `pubspec.yaml` or `CHANGELOG.md` changes.
- No endless loop: one fix pass, one new report, then stop.

## Anti-goals
- The agent must never add or change a key, command, layout, color, message
  or business rule on its own.

## Classification
- **Mechanical (auto):** task order, `[P]` markers, skill tags, referenced
  files, renumbering, terminology alignment, duplicated text, missing
  conditions/dependencies in tasks, wording.
- **Ask owner:** shortcuts/keys, new or changed behavior, business rules,
  layout/visual/UX, scope changes, constitution conflicts.
- **Doubt:** treated as "ask owner".

## Output (on screen, Portuguese)
1. `Aplicado automaticamente`: ID, category, location, what changed.
2. `Preciso de você` (and `Em dúvida`): ID, category, location, question,
   recommendation. Asked after the auto-fixes are applied.
3. After the owner answers and those edits are applied, `Relatório final`:
   what is still pending (open questions, unresolved findings, tasks not
   ready), in a table. Read-only re-check of the three artifacts, no loop.

## Mechanism
- New skill `.github/skills/speckit-analyze-fix/SKILL.md` (English text).
- New `.specify/extensions.yml` with `hooks.after_analyze`, one entry,
  `optional: false` (mandatory = runs automatically), command pointing to
  the skill (`speckit-analyze-fix`). The existing `speckit-analyze` skill
  already reads this key (its step 9), so no change to Spec Kit skills.
- Risk (my call, to validate): the hook is executed by the agent following
  the analyze skill's instructions, not by a runtime. After building, I will
  verify it fires by running `/speckit-analyze` once.

## Constraints
- Edits only `spec.md`, `plan.md`, `tasks.md` and sibling Spec Kit docs in the
  feature dir. Never `lib/`, `bin/`, `tests/`.
- Constitution conflicts are never auto-fixed.
- No commit, push or PR.
- Registering the skill in `.github/copilot-instructions.md` only with
  maintainer confirmation.

## Approaches
1. Skill, manual call. Rejected by owner: wants automatic.
2. **Skill + `after_analyze` hook (picked by owner).** Automatic; extra YAML
   file; relies on the agent honoring the hook.
3. Catalog extension. Not confirmed to exist.

## Left to the builder
Exact skill wording; YAML field values (`extension` name, `description`,
`prompt`).
