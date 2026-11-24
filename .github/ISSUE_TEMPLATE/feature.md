---
name: Feature
about: Propose a new feature or improvement for LazyForge
title: '[feature] '
labels: enhancement
assignees: ''
---

<!--
Title: [feature] + infinitive verb + what changes. Ex.: [feature] Add 'q' key to quit
This issue is the source of truth for an AI agent to create the spec, plan, tasks, and implementation.
Fill in the sections above the "Agent directives" line so they are self-contained: anyone reading
only this issue should understand the request without looking elsewhere. Do not edit the directives.
Every feature must solve a concrete usability problem; vague requests are not accepted.
-->

## Usability problem
<!-- Who is affected, in what situation, and what concrete effect it has when modeling schemas in the terminal. -->

## Current behavior
<!-- What the app does today in this situation. Cite file and function when known
     (e.g. _handleDeleteTable in lib/src/components/editor/providers/commands_provider.dart). -->

## Desired solution
<!-- What should happen instead. If it involves a command, state the syntax and the message shown. -->

**Proposed syntax (if there is a command):**
```
```

## Acceptance criteria
<!-- Verifiable, in Given/When/Then format. -->
- [ ] Given ..., When ..., Then ...
- [ ] Given ..., When ..., Then ...

## Impact on current behavior
<!-- Check one option. -->
- [ ] Additive: does not change anything that already works today
- [ ] Changes already shipped behavior (justify below why the change is acceptable)

**Justification (if behavior changes):**

## Affected databases
- [ ] PostgreSQL
- [ ] MySQL
- [ ] SQLite
- [ ] All / not applicable

## Out of scope
<!-- What must NOT be changed in this issue. -->

## How to validate manually
<!-- The project does not require automated tests. Steps the maintainer runs in the app. -->
1.
2.

## Alternatives considered
<!-- Write N/A if none. -->

## Additional context
<!-- Screenshots, links, related issues. Write N/A if none. -->

---

## Agent directives (do not edit)

This issue is the starting point. The target version is this issue's **milestone**.

**1. Read before acting**
- This entire issue (`gh issue view <number>`).
- `.specify/memory/constitution.md` (constitution; highest precedence over informal practices).
- `.github/copilot-instructions.md` (operational guidance and skills).
- Existing code under `lib/` is the source of truth for current behavior and layout. If the
  constitution or `copilot-instructions.md` diverge from the code, the code wins: notify the maintainer.

**2. Spec Kit flow (in this order; hyphenated commands)**
1. `/speckit-specify` using this issue's content as the feature description.
   - The spec starts with `Status: Planned` and the line `Source issue: #<number>`.
   - It states what is already shipped in code and does not change out-of-scope behavior.
2. `/speckit-clarify` only if real ambiguity remains; prefer recording the decision over asking the obvious.
3. `/speckit-plan` following the real code layout and the Constitution Check.
4. `/speckit-tasks` with small, ordered tasks limited to this issue's scope.
5. `/speckit-analyze` (read-only) and fix inconsistencies in the documentation.
6. `/speckit-implement` only if the spec is `Planned` and the Constitution Check is PASS.

**3. Mandatory constraints**
- Do not change `specs/001-*`, and do not change shipped behavior outside this issue's scope.
- If this issue marks "Changes already shipped behavior", the spec must record the justification and the
  change must match exactly what is described.
- Keep reading already-saved JSON projects in `lazyforge_projects/` (new fields are optional).
- Respect the existing folder layout under `lib/src/`; command parsing outside UI components;
  use `ColumnDef`, never `Column`; no `index.dart`.
- Confirm the `nocterm` API in the locally installed code before using it. Do not assume from memory.
- To quit the app, use nocterm's `shutdownApp()`, never `exit(0)`.
- Do not add a dependency to `pubspec.yaml` without asking the maintainer.
- Do not create or expand automated tests (the constitution does not require them).
- User-facing messages in Portuguese, clear and actionable; never expose stack traces.
- New features or screens must offer the `q` key to quit.
- Simplicity: no abstraction "for the future".

**4. Delivery**
- Work on your own branch, never directly on `master`.
- Do not commit, push, or open a PR without maintainer confirmation. The PR must include `Closes #<number>`.
- Update `README.md` if visible commands or behavior change.
- When done and manually validated, set the spec status to `Implemented`.
- If `pubspec.yaml` `version` and `CHANGELOG.md` do not match this issue's milestone, ask the
  maintainer before changing them.

**5. Spec Kit references**: skills under `.github/skills/speckit-*/SKILL.md` and templates under `.specify/templates/`.
