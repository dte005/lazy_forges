<!--
Sync Impact Report
- Version change: 2.0.0 → 2.0.0 (documentation language only: full body
  translated Portuguese → English; no principle meaning change).
- Clerical: all project Spec Kit / agent docs standardized on English.
- Operational guidance remains `.github/copilot-instructions.md`.
- Follow-up TODOs: TODO(MULTI_USER_SCOPE) unchanged (see "What LazyForge Is Not").
-->

# LazyForge Constitution

## Purpose and audience

LazyForge is a keyboard-driven terminal IDE (TUI) for modeling relational
database schemas (PostgreSQL, MySQL, and SQLite) and exporting the matching
SQL DDL. It is inspired by LazyGit and LazyVim: fast, memorable terminal
tools developers do not want to leave. The project is already in production on
pub.dev; what ships today is the base everything builds on.

The user is a developer who already lives in the terminal and does not want to
switch UI — browser, desktop app, visual diagrammer — only to design a schema.
LazyForge lets that user go from a model idea to ready DDL without leaving the
terminal.

This constitution is the document against which every future spec, plan, task,
and implementation is judged. It does not cover language, framework, folder
layout, or coding conventions — that operational guidance lives in
`.github/copilot-instructions.md`. Here live product values, principles, and
the criteria that decide whether a feature idea belongs in LazyForge.

## Language of project artifacts

All Spec Kit artifacts (`specs/**`, constitution amendments, plans, tasks,
checklists), GitHub issue agent directives, Copilot instructions, and agent
definitions **MUST** be written in **English**. All source comments and doc
comments (`//`, `///`) in application and test code **MUST** be in **English**.
End-user UI strings shown inside the running TUI remain in **Portuguese**
(clear, actionable; never raw stack traces).

## Core Principles

### I. Interface in service of decisions
Every on-screen element MUST exist to communicate state or help the user decide.
Purely decorative elements, visual noise, or redundant information MUST be
removed. Every user action MUST produce immediate, unambiguous feedback. Every
error message MUST be human language, clear and actionable — never a stack
trace or raw exception.
Rationale: in a productivity tool used repeatedly, every non-functional element
is cognitive cost paid every session.

### II. Commands that speak SQL
The command language MUST feel familiar to anyone who already knows SQL (for
example create/alter/drop tables and columns, rename, declare foreign keys). An
experienced SQL user MUST be able to guess a new command’s shape without
reading docs. Grammar MUST stay consistent: a new command MUST NEVER contradict
the pattern set by earlier commands. Shortcuts and synonyms ARE allowed when
they reduce effort, as long as they do not make the action ambiguous.
Rationale: SQL familiarity is mental shortcut the user already has; inventing an
arbitrary syntax throws away the point of a tool “for people who think in SQL”.

### III. Portable output, never lock-in
What LazyForge produces MUST be usable outside it. Exported DDL MUST be pure
SQL for the chosen engine. Project files MUST stay simple, readable files in
the working directory, git-friendly. Product evolution MUST prefer open,
readable formats over proprietary or opaque ones. Product direction includes
integrations that carry LazyForge output into other dev tools (migrations,
versioning, other clients); that is direction, not a capability already
delivered beyond SQL export and readable project files.
Rationale: a schema modeler that traps the user inside itself fights the
workflow it should serve.

### IV. Terminal end to end
The keyboard MUST be the primary mode of operation; no essential flow MUST
require a mouse. No feature MUST force the user to switch context (browser,
external app) to finish a modeling task. Every proposed feature MUST state, in
concrete terms, which real usability problem it solves for people modeling
schemas in the terminal; vague, generic, or “might be useful someday” ideas
MUST be rejected.
Rationale: LazyForge’s value is saving time for people who already live in the
terminal; any break of that promise returns the cost the tool exists to remove.

### V. Perceived speed as a requirement
The UI MUST respond to every command in a way that feels instant, including on
large schemas (many tables and columns). The table/relationship graph MUST
reflect each command’s result immediately. Performance is NOT a later
optimization: it is a product requirement evaluated with any new feature, and a
proposal that risks freezing the UI MUST be redesigned before acceptance.
Rationale: the user’s comparison is typing a command in their own terminal, not
another schema tool; any perceptible lag breaks that expectation.

### VI. Trust from the first command
The tool MUST feel solid on first run: initial screen, first command, first
error. User work MUST be saved automatically and MUST NEVER be lost
unexpectedly. The user MUST be able to inspect command history and get in-app
help without leaving the flow. The same command mental model MUST work equally
for PostgreSQL, MySQL, and SQLite — the user picks the engine and the tool
adapts (valid types, correct DDL) without a different flow per database.
Rationale: trust is built or destroyed in the first seconds; treating three
engines as three workflows loads the user with work the tool should absorb.

### VII. Deliberate simplicity
Every solution MUST solve the stated problem in the most direct way;
abstractions or complexity added “for the future” without proven present need
MUST be refused.
Rationale: simplicity keeps the product fast to understand and evolve.

### VIII. Stability of what already ships (NON-NEGOTIABLE)
LazyForge is in production and people use it today. No change MAY cause any
kind of behavior regression: commands that work today MUST keep being accepted
with the same meaning and result; what the user already modeled, saved, or
exported MUST keep opening and producing the same result; existing shortcuts,
interactions, and flows MUST NOT be removed or changed silently. Released code
is the source of truth for what the product does; old specs, plans, and tasks
are history only and MUST NEVER justify rewriting or “fixing” what already
works. Changing or removing existing behavior is only acceptable with a new
spec that states that change exactly and justifies impact for current users.
Rationale: users who trust current behavior must not be surprised by unannounced
change; without this barrier every evolution cycle risks regressing production-
validated functionality.

## How to evaluate a proposal

Every feature spec, plan, or review MUST be able to answer “yes” to the
questions below before acceptance. A “no” requires redesign or rejection:

1. Does the feature solve a concrete usability problem for people modeling
   schemas in the terminal — not something vague or “maybe useful someday”?
2. Does the flow stay fully on keyboard and terminal, with no mouse and no
   context switch to another tool?
3. If it involves a command, is the syntax guessable for someone who knows SQL
   and consistent with existing commands?
4. Does the produced result (project file, exported DDL) remain usable outside
   LazyForge in an open, readable format?
5. Does UI response to this feature stay perceptibly instant, even on large
   schemas?
6. If the proposal changes released behavior, does it state explicitly what
   changes and why — instead of silently altering what already works?
7. Does it fully preserve behavior already in production (or explicitly declare
   and justify the change)?

## What LazyForge is not

- Not a graphical or web schema diagrammer; it is a terminal TUI.
- It does not execute DDL against a live database or manage active connections;
  it models and exports SQL, does not apply migrations or manage instances.
- Not a general-purpose SQL client (no arbitrary queries, no browsing table
  data); scope is schema modeling and matching DDL generation.

TODO(MULTI_USER_SCOPE): there is no evidence today in code or project docs of
collaborative/multi-user use of the same project; this limit stays deliberately
open until an explicit decision.

## Governance

This constitution takes precedence over any informal practice or individual
implementation preference inside LazyForge, and is the highest-precedence
document after released production code itself.

- **Amendments**: any change to this constitution MUST be proposed explicitly,
  with rationale recorded in that amendment’s Sync Impact Report. No silent
  principle change.
- **Semantic versioning**: MAJOR.MINOR.PATCH — MAJOR for removing or
  incompatibly redefining principles (including full rewrites); MINOR for adding
  a principle or materially expanding one; PATCH for clarifications and wording
  fixes with no meaning change.
- **Compliance**: every feature spec, technical plan, or feature review MUST be
  checked against these principles and checklist before acceptance. Missing that
  check is enough grounds for rejection.
- **Relation to other documents**: technical and operational guidance (language,
  folder layout, coding conventions, test policy, development flow) does not
  belong here and lives in `.github/copilot-instructions.md`; on conflict,
  released code prevails over this constitution, which in turn prevails over
  `.github/copilot-instructions.md`.

**Version**: 2.0.0 | **Ratified**: 2026-10-03 | **Last Amended**: 2026-11-24
