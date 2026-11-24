# LazyForge — Copilot instructions

Operational guidance for agents and Copilot in this repository.

**Conflict precedence:** released code in `lib/` / `bin/` >
`.specify/memory/constitution.md` > this file.
Product details: `README.md` and specs under `specs/`.

## Language (mandatory)

- **All** Spec Kit artifacts, issue agent directives, this file, custom agents,
  and project documentation **MUST** be written in **English**.
- **All code comments and doc comments** in logic (`//`, `///`, block comments)
  under `lib/`, `bin/`, and `tests/` **MUST** be in **English**. No Portuguese
  in comments—including TODOs, section banners, and inline explanations.
- **End-user TUI strings** (feedback, errors, help text shown in the running
  app) stay in **Portuguese**: clear and actionable; never expose stack traces.
- Spec Kit templates under `.specify/templates/` are English; keep generated
  `spec.md` / `plan.md` / `tasks.md` / checklists in English.

## What it is

LazyForge is a keyboard-driven terminal IDE (TUI) for modeling relational
schemas (PostgreSQL, MySQL, SQLite) and exporting SQL DDL, with a graph
updated on every command. Inspired by LazyGit and LazyVim.

- **Language:** Dart (SDK ^3.11.4)
- **TUI:** **`nocterm` only** (`StatefulComponent`, `State`, `setState`,
  `Focusable`, `Column` / `Row` / `Expanded`). Confirm the API in the local
  cache (`~/.pub-cache/hosted/pub.dev/nocterm-*/lib/`); do not assume from memory.
- **Distribution:** pub.dev — `dart pub global activate lazy_forge`
- **Repo / issues:** `dte005/lazy_forges`

Do not use other TUI frameworks (React/Solid/Bun/etc.) in this product.

## Project status

- In production; published version is in `pubspec.yaml` (currently **1.0.1**).
- Official version for each delivery = the GitHub issue **milestone**.
- Do not change `pubspec.yaml` or `CHANGELOG.md` without asking the maintainer.
- Existing code is the source of truth for behavior and layout.
- Backlog: GitHub issues with templates in `.github/ISSUE_TEMPLATE/`. On `#N`
  or a URL, run `gh issue view N` and follow the issue directives.

## Real code layout

```
bin/lazy_forge.dart              # entry point
lib/lazy_forge.dart              # public barrel
lib/src/
├── main.dart
├── components/
│   ├── init/components/init_component.dart   # create/open project
│   └── editor/
│       ├── editor_component.dart             # editor, shortcuts, Help
│       ├── components/
│       │   ├── sidebar/
│       │   ├── table/                        # graph: table_component,
│       │   │                                 # graph_layout, graph_routing,
│       │   │                                 # table_box_component
│       │   └── vertical_divider/
│       ├── models/                           # schema_model (SchemaState,
│       │                                     # TableDef, ColumnDef, DDL),
│       │                                     # editor_model, graph_model
│       └── providers/                        # commands_provider (parse/handlers),
│                                             # editor_provider (history)
├── services/
│   ├── clipboard_service.dart
│   └── storage/                              # project_storage, project_model
└── shared/models/enums.dart                  # DatabaseEngine
specs/                           # Spec Kit (only Planned is implementable)
tests/                           # on-demand tests (features/ + unit/)
.github/ISSUE_TEMPLATE/
.github/skills/                  # versioned skills (see Skills)
.specify/                        # constitution, templates, workflows
```

Do not move files without a spec. If docs diverge from code, **code wins** —
tell the maintainer.

## Hard rules (non-negotiable)

- Do not rewrite, reorganize, or “fix” released code without a new spec that
  justifies the change.
- Only implement specs with status **Planned**, and only their scope.
  **Implemented**, **Draft**, or **Superseded** specs are reference only —
  never input to `/speckit-implement`.
- Command parsing lives in providers, outside UI components.
- Use `ColumnDef`, never `Column`.
- Do not add extra `index.dart` / barrels beyond the existing public barrel.
- Exit the app with nocterm `shutdownApp()` — never `exit(0)`.
- User-facing messages in the TUI: **Portuguese**, clear and actionable; never
  stack traces. All docs/specs/agent text **and all code comments**: **English**.
- New feature or screen: `q` key to quit.
- JSON projects in `lazyforge_projects/`: keep reading older files (new fields
  optional).
- Do not add a `pubspec.yaml` dependency without approval.
- Automated tests are **not** an acceptance criterion in the constitution. Do
  not create or expand tests in the main flow unless the maintainer asks — use
  custom agent `test-manager-executer` (see Agents).
- Deliberate simplicity: no “for the future” abstraction.
- Own branch; never commit straight to `master`.
- No commit, push, or PR without maintainer confirmation. PR with `Closes #N`.
- Update `README.md` if visible commands or behavior change.

## Skills (must consult)

Versioned skills live in `.github/skills/<name>/SKILL.md`.
**Read the `SKILL.md` before** the matching step and follow its flow.

### 1. Brainstorming — ideas, features, questions

- **Path:** `.github/skills/brainstorming/SKILL.md`
- Use **before** creative work: new feature, behavior change, redesign, scope
  debate, or product questions.
- Do not jump straight to code: align what/why; then how.

### 2. Dart — primary for this repo

| Situation | Skill | Path |
| --- | --- | --- |
| CLI: entrypoint, exit codes, args, executables | `dart-build-cli-app` | `.github/skills/dart-build-cli-app/SKILL.md` |
| Quality before delivery (`dart analyze` / fix) | `dart-run-static-analysis` | `.github/skills/dart-run-static-analysis/SKILL.md` |
| Parsing, switch/patterns, JSON, sealed/ADTs | `dart-use-pattern-matching` | `.github/skills/dart-use-pattern-matching/SKILL.md` |
| Tests (only if maintainer asks; folder `tests/`) | `dart-add-unit-test` | `.github/skills/dart-add-unit-test/SKILL.md` |
| `///` doc comments (Effective Dart) | `dart-write-documentation` | `.github/skills/dart-write-documentation/SKILL.md` |

### 3. Dart — on demand

| Situation | Skill | Path |
| --- | --- | --- |
| File paths (`project_storage`, export) | `dart-use-path-package` | `.github/skills/dart-use-path-package/SKILL.md` |
| Runtime / stack / hot reload | `dart-fix-runtime-errors` | `.github/skills/dart-fix-runtime-errors/SKILL.md` |
| `pub get` version conflicts | `dart-resolve-package-conflicts` | `.github/skills/dart-resolve-package-conflicts/SKILL.md` |
| Primary constructors (new syntax) | `dart-use-primary-constructors` | `.github/skills/dart-use-primary-constructors/SKILL.md` |
| Dartdoc examples (`{@example}`) | `dart-use-doc-examples` | `.github/skills/dart-use-doc-examples/SKILL.md` |

### 4. Dart — explicit request + dependency approval only

These skills usually need packages **outside** the current `pubspec`
(`nocterm`, `lints`, `test`):

| Skill | Path | Note |
| --- | --- | --- |
| `dart-collect-coverage` | `.github/skills/dart-collect-coverage/SKILL.md` | `coverage` package |
| `dart-generate-test-mocks` | `.github/skills/dart-generate-test-mocks/SKILL.md` | mockito + build_runner |
| `dart-migrate-to-checks-package` | `.github/skills/dart-migrate-to-checks-package/SKILL.md` | matcher → checks |
| `dart-setup-ffi-assets` | `.github/skills/dart-setup-ffi-assets/SKILL.md` | native C/C++ assets |
| `dart-use-ffigen` | `.github/skills/dart-use-ffigen/SKILL.md` | FFI bindings |

### 5. Spec Kit (issue flow)

| Step | Skill | Path |
| --- | --- | --- |
| Spec from issue | `speckit-specify` | `.github/skills/speckit-specify/SKILL.md` |
| Clarify ambiguity | `speckit-clarify` | `.github/skills/speckit-clarify/SKILL.md` |
| Technical plan | `speckit-plan` | `.github/skills/speckit-plan/SKILL.md` |
| Tasks | `speckit-tasks` | `.github/skills/speckit-tasks/SKILL.md` |
| Cross-artifact analysis | `speckit-analyze` | `.github/skills/speckit-analyze/SKILL.md` |
| Implement tasks | `speckit-implement` | `.github/skills/speckit-implement/SKILL.md` |
| Converge gaps vs code | `speckit-converge` | `.github/skills/speckit-converge/SKILL.md` |
| Checklist | `speckit-checklist` | `.github/skills/speckit-checklist/SKILL.md` |
| Constitution | `speckit-constitution` | `.github/skills/speckit-constitution/SKILL.md` |
| Tasks → GitHub issues | `speckit-taskstoissues` | `.github/skills/speckit-taskstoissues/SKILL.md` |

Spec Kit templates: `.specify/templates/` (English). Write all generated
artifacts in **English**.

### UI / TUI in this product

- Graphical implementation = **nocterm** + code under `lib/src/components/`.
- Mirror patterns from `editor_component`, sidebar, `table_component`,
  `graph_layout`, `graph_routing`.
- Do not introduce another TUI toolkit.

### Graphical layout rules (product UI — non-negotiable)

These describe how the editor **must** look and behave. Do not regress them.

1. **Editor canvas scrolls (feels infinite)**  
   The main editor area where tables are drawn **must** support scroll
   navigation (vertical and horizontal as needed). The canvas must *feel*
   effectively unlimited so large schemas remain reachable without clipping
   the workspace into a fixed non-scrollable box.

2. **Left table descriptor scrolls vertically**  
   The left sidebar lists tables, columns, relationships, etc. It **must**
   have a **vertical** scroll so long listings remain usable.

3. **Command input spans the editor width**  
   The bottom command input **must** occupy the full horizontal span of the
   **editor** region: from the right edge of the left sidebar to the right
   edge of the window (not under the sidebar; full width of the graph/editor
   pane).

4. **Command help / dropdown is opaque**  
   The suspended/dropdown menu that lists available commands **must** use a
   **non-transparent** background so command text stays readable over the
   graph/editor behind it.

5. **Relationship lines never invade table drawings**  
   FK/relationship lines **must not** cross, traverse, or draw over the
   interior/border of any table box. Lines stay on the **outer layer** in the
   free space **between** table drawings only (see `graph_routing` / issue #2
   and `tests/features/graph_visual_nocterm_test.dart` when graphical checks
   are authorized).

When changing editor chrome or the graph, preserve these five rules. Specs
that alter them must declare the change explicitly and get maintainer buy-in.

## Agents (Copilot custom agents)

### `test-manager-executer` — Dart Test Creator

- **Path:** `.github/agents/test-manager-executer.md`
- **Purpose:** create/update tests under `tests/features/` (user flows) and
  `tests/unit/` (line coverage), inventory in `tests/features/FEATURES.md`,
  report in `tests/REPORT.md`.
- **Fit:** yes. Suite already exists under `tests/`; agent must not change
  `lib/`, `bin/`, or `pubspec.yaml`; tests **inform**, they do not block
  delivery.
- **When to use (in parallel):**
  - Alongside feature/bug implementation (another agent or product session) to
    cover new/changed behavior **without** mixing production edits in the same
    step.
  - At the end of a spec (e.g. T025 on 001) for a coverage report.
  - When the maintainer asks for tests, coverage, or a feature inventory.
- **Do not** use as an acceptance gate or to “fix” production via tests.
- Skills the agent should read: `dart-add-unit-test`,
  `dart-run-static-analysis`; `dart-collect-coverage` /
  `dart-generate-test-mocks` only with dependency approval.
- Run tests: `dart test tests`.
- Agent docs and reports: **English**.

### Test rules (mandatory)

- Tests **cover code** (`lib/` via public API / providers / models), not a
  manual app session on the repository disk.
- **Forbidden** to start the LazyForge TUI (`bin/lazy_forge.dart`, `lazy_forge`,
  `dart run ...`) with cwd inside `lazy_forges/` during tests or test scripts.
  That writes `lazyforge_projects/`, `.sql` exports, and session junk into the
  repo.
- Persistence in tests: **always** a temporary directory
  (`Directory.systemTemp` / temp path) + `IOOverrides.runZoned` (or equivalent)
  for `getCurrentDirectory`. Delete the temp dir in `tearDown`.
- Manual app runs stay **only** in `../dbs_schema_lazyforges` (Development) —
  never as part of the test suite.
- Suite goal: regression and behavior/code coverage; do not pollute the git
  working tree.

### Graphical TUI emulation (nocterm_test) — gated

Use **in-process** nocterm testing only (`package:nocterm/nocterm_test.dart`:
`testNocterm`, `NoctermTester`). Do **not** use external TUI MCP servers
(mcp-tuikit, etc.).

**Hard gates (both required before running graphical emulation):**

1. The change is a **significant graphical** change (layout, graph drawing,
   sidebar/editor chrome, visible paint/focus) **and** the maintainer gave
   **express approval** to run graphical emulation/tests for that change.
2. To **observe table relationships** on the graph and judge whether the
   drawing makes sense, the agent may pump graph UI and print/assert the
   terminal buffer **only with explicit maintainer authorization in the
   terminal/session** for that observation run.

Without both conditions, stick to unit/feature logic tests. Graphical
nocterm runs are **not** an acceptance gate unless the maintainer says so.

**How to emulate (when authorized):**

- Prefer focused components (e.g. `TableGraphLayoutComponent`) with a built
  `SchemaState` over the full app when that validates the change.
- Full `EditorComponent` only if needed; isolate disk via temp `IOOverrides`
  whenever `ProjectStorage` is involved.
- Inspect with `tester.terminalState.getText()`, `containsText`,
  `toSnapshot()` / `renderToString()` — no real OS window required.
- Reference: `tests/features/graph_visual_nocterm_test.dart`.

## Issue flow (Spec Kit)

Order:

1. `/speckit-specify` — `Status: Planned`, `Source issue: #N` (English spec)
2. `/speckit-clarify` — only if real ambiguity remains
3. `/speckit-plan` — real code layout + Constitution Check (English)
4. `/speckit-tasks` — small tasks, scope only (English)
5. `/speckit-analyze` — read-only; fix docs if needed
6. `/speckit-implement` — only if Planned and Constitution Check PASS

When done and manually validated, set the spec status to `Implemented`.

## Development

**Do not run the app from the repository clone** (`lazy_forges/`).
Local development/use runs **only** from the schema workspace (sibling of
`lazy_forges` under `projetos/`):

`../dbs_schema_lazyforges`

So `lazyforge_projects/` and exported `.sql` stay outside the repo.

```bash
# in the repository (deps / analysis / tests)
dart pub get
dart analyze

# run the TUI — required cwd: dbs_schema_lazyforges
cd ../dbs_schema_lazyforges
dart --enable-vm-service ../lazy_forges/bin/lazy_forge.dart   # hot reload
# or, if the package is globally activated: lazy_forge
```

- Execution CWD: `projetos/dbs_schema_lazyforges` (never `projetos/lazy_forges`).
- Changes in `build()` → hot reload.
- Changes in `initState()` or `main()` → restart the process.
- Tests (if requested): in the repo, `dart test tests` (folder `tests/`, not
  `test/`). Never run the LazyForge binary from the clone “to test”; use the
  suite and temp dirs (see Agents → Test rules).

## What LazyForge is not

- Not a web/graphical diagrammer; it is a terminal TUI.
- Does not connect to or execute DDL on a real database; it models and exports
  SQL.
- Not a general SQL client (no arbitrary queries, no table data browsing).

Product principles: `.specify/memory/constitution.md` (v2.0.0).
