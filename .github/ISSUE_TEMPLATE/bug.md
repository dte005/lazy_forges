---
name: Bug
about: Report incorrect behavior in LazyForge
title: '[bug] '
labels: bug
assignees: ''
---

<!--
Title: [bug] + what is wrong. Ex.: [bug] Relationship lines overlap tables
This issue is the source of truth for an AI agent to create the fix spec, plan, tasks, and implementation.
Fill in the sections above the "Agent directives" line so they are self-contained. Do not edit the directives.
-->

## Bug description
<!-- What goes wrong and what effect it has on the user. -->

## Steps to reproduce
1.
2.
3.

**Command(s) run, if any:**
```
```

## Expected behavior
<!-- What should happen. -->

## Actual behavior
<!-- What actually happens. Paste the error message or terminal output, if any. -->

## Likely cause (if known)
<!-- Suspect file and function. Write N/A if unknown. -->

## Screenshots
<!-- Images or terminal recording. Write N/A if none. -->

## Environment
- Operating system (e.g. Windows 11, macOS 14, Ubuntu, WSL):
- Terminal (e.g. Windows Terminal, iTerm2, GNOME Terminal):
- LazyForge version (`pubspec.yaml` or pub.dev):
- Dart version:
- Project database (PostgreSQL, MySQL, or SQLite):

## Severity
- [ ] Crashes or quits the app / data loss
- [ ] Produces wrong result (DDL, schema, visualization)
- [ ] Visual or UX annoyance, no data loss

## Acceptance criteria
<!-- How to know the bug is fixed, in Given/When/Then format. -->
- [ ] Given ..., When ..., Then ...

## Out of scope
<!-- What must NOT be changed in this fix. -->

## How to validate manually
<!-- Steps the maintainer runs in the app to confirm the fix. -->
1.
2.

## Additional context
<!-- Write N/A if none. -->

---

## Agent directives (do not edit)

This issue is the starting point. The target version is this issue's **milestone**.

**1. Read before acting**
- This entire issue (`gh issue view <number>`).
- `.specify/memory/constitution.md` and `.github/copilot-instructions.md`.
- Existing code under `lib/` is the source of truth. If the constitution or `copilot-instructions.md` diverge
  from the code, the code wins: notify the maintainer.

**2. Before specifying**
- Reproduce or locate the root cause in code. Record the cause in the spec; do not fix symptoms.
- If the described behavior is actually the documented baseline behavior, stop and tell the
  maintainer: it may be an improvement (`[feature]`) rather than a bug.

**3. Spec Kit flow (in this order; hyphenated commands)**
1. `/speckit-specify` using this issue's content. The spec starts with `Status: Planned`, the line
   `Source issue: #<number>`, and describes the correct expected behavior and the root cause.
2. `/speckit-clarify` only if real ambiguity remains.
3. `/speckit-plan` with the minimum necessary fix and the Constitution Check.
4. `/speckit-tasks` with small tasks limited to the fix scope.
5. `/speckit-analyze` (read-only).
6. `/speckit-implement` only if the spec is `Planned` and the Constitution Check is PASS.

**4. Mandatory constraints**
- Minimum fix: do not refactor or change behavior outside this issue's scope.
- Do not change `specs/001-*`.
- Keep reading already-saved JSON projects in `lazyforge_projects/`.
- Respect the existing folder layout under `lib/src/`; use `ColumnDef`, never `Column`.
- Confirm the `nocterm` API in the installed code before using it.
- To quit the app, use nocterm's `shutdownApp()`, never `exit(0)`.
- Do not add a dependency to `pubspec.yaml` without asking the maintainer.
- Do not create or expand automated tests (the constitution does not require them).
- User-facing messages in Portuguese, clear, and without stack traces.

**5. Delivery**
- Work on your own branch, never directly on `master`.
- Do not commit, push, or open a PR without maintainer confirmation. The PR must include `Closes #<number>`.
- When done and manually validated, set the spec status to `Implemented`.
- If `pubspec.yaml` `version` and `CHANGELOG.md` do not match this issue's milestone, ask the
  maintainer before changing them.

**6. Spec Kit references**: skills under `.github/skills/speckit-*/SKILL.md` and templates under `.specify/templates/`.
