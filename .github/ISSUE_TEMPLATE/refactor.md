---
name: Refactor
about: Propose code reorganization or cleanup without changing behavior
title: '[refactor] '
labels: refactor
assignees: ''
---

<!--
Title: [refactor] + what will be reorganized. Ex.: [refactor] Reorganize provider structure
A refactor does not change user-visible behavior. If it would, open a [feature] issue.
This issue is the source of truth for an AI agent to create the spec, plan, tasks, and implementation.
Fill in the sections above the "Agent directives" line so they are self-contained. Do not edit the directives.
-->

## Motivation
<!-- What code problem today justifies the change? (maintainability, file size,
     mixed responsibilities, duplication). -->

## Scope
<!-- What will be reorganized? Cite files, folders, and classes, with code snippets if helpful. -->

**Target structure (if applicable):**
```text
```

**Out of scope:**
<!-- What will NOT be touched in this issue. -->

## Impact
<!-- What current difficulty this solves and what improves afterward? -->

## Behavior guarantee
- [ ] No command, message, or file format changes for the user
- [ ] Projects already saved in `lazyforge_projects/` still open normally
- [ ] The resulting folder layout is consistent with the constitution and `.github/copilot-instructions.md` (or the needed amendment was proposed)

## Acceptance criteria
<!-- Verifiable. Ex.: class X lives in its own file; no file exceeds N lines. -->
- [ ]
- [ ]

## How to validate manually
<!-- The project does not require automated tests. Describe the steps to confirm
     behavior remains identical (commands to run, screens to open). -->
1.
2.

## Additional context
<!-- Links, prior decisions. Write N/A if none. -->

---

## Agent directives (do not edit)

This issue is the starting point. The target version is this issue's **milestone**.

**1. Read before acting**
- This entire issue (`gh issue view <number>`).
- `.specify/memory/constitution.md` and `.github/copilot-instructions.md`.
- Existing code under `lib/` is the source of truth; shipped behavior must remain identical after the refactor.

**2. Spec Kit flow (in this order; hyphenated commands)**
1. `/speckit-specify` using this issue's content. The spec starts with `Status: Planned`, the line
   `Source issue: #<number>`, and explicitly states that **there is no behavior change**.
2. `/speckit-clarify` only if real ambiguity remains.
3. `/speckit-plan` with the target structure and the Constitution Check (especially Principles VI, VII, and VIII).
4. `/speckit-tasks` in small, reversible steps, each leaving the app working.
5. `/speckit-analyze` (read-only).
6. `/speckit-implement` only if the spec is `Planned` and the Constitution Check is PASS.

**3. Mandatory constraints**
- Zero behavior change: same commands, messages, DDL outputs, and JSON format.
- Do not change `specs/001-*`.
- Structure: start from the real layout of `lib/src/`; command parsing outside UI components;
  use `ColumnDef`, never `Column`; no `index.dart`. If the constitution or `copilot-instructions.md` diverge from
  the code, the code wins: notify the maintainer.
- If reorganization requires changing the folder structure described in the constitution, **stop** and propose the
  amendment to the maintainer (`/speckit-constitution`) before continuing.
- To quit the app, use nocterm's `shutdownApp()`, never `exit(0)`.
- Confirm the `nocterm` API in the installed code before using it.
- Do not add a dependency to `pubspec.yaml` without asking the maintainer.
- Do not create or expand automated tests (the constitution does not require them).
- Simplicity: do not introduce abstractions beyond what this issue needs.
- Explain the architecture choice before changing `lib/src/model/` or `lib/src/components/`.

**4. Delivery**
- Work on your own branch, never directly on `master`.
- Do not commit, push, or open a PR without maintainer confirmation. The PR must include `Closes #<number>`.
- Run the manual validation described above and report the result.
- When done, set the spec status to `Implemented`.
- If `pubspec.yaml` `version` and `CHANGELOG.md` do not match this issue's milestone, ask the
  maintainer before changing them.

**5. Spec Kit references**: skills under `.github/skills/speckit-*/SKILL.md` and templates under `.specify/templates/`.
