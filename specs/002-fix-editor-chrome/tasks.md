---

description: "Task list for fixing editor chrome (scroll, overlays, exit navigation)"
---

# Tasks: Fix editor chrome for dense schemas and exit navigation

**Input**: Design documents from `specs/002-fix-editor-chrome/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/ui-contract.md, quickstart.md

**Tests**: Not an acceptance criterion (constitution; copilot-instructions). Validation is manual via `quickstart.md`; the final task runs the `test-manager-executer` agent as required by the spec (informative only). Do NOT run the app from the repo clone; use `../dbs_schema_lazyforges`.

**Organization**: Grouped by user story from `spec.md` (US1–US4, all P1). Allowed edits: only the files listed below; do not touch `pubspec.yaml`, `CHANGELOG.md`, graph layout/routing files, or add barrels. Code comments in English; user-facing strings in Portuguese. Use nocterm APIs confirmed in `~/.pub-cache/hosted/pub.dev/nocterm-0.8.0/lib/` (`Scrollbar`, `BoxDecoration(color:)`, `Text(softWrap:)`).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Parallelizable (different files, no dependency on an incomplete task)
- **[Story]**: US1 graph scroll, US2 sidebar, US3 opaque overlays, US4 exit navigation

## Path Conventions

- `lib/src/components/editor/editor_component.dart`
- `lib/src/components/editor/components/sidebar/sidebar_component.dart`
- `lib/src/main.dart`
- `lib/src/components/init/components/init_component.dart`

---

## Phase 1: Setup

- [X] T001 Run `dart pub get` and `dart analyze` at repo root; record baseline warnings so new ones can be distinguished (skill: `dart-run-static-analysis`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared overlay state that US3 and US4 both depend on.

- [X] T002 In `lib/src/components/editor/editor_component.dart`, replace `_isHelpOpen`/`_isDbTypesOpen` with an ordered overlay list (private enum `_Overlay { help, dbTypes }`, no duplicates, last item = most recently opened) plus helpers `_openOverlay`, `_closeOverlay`, `_popTopOverlay`; update `_toggleHelpWindow`, `_toggleDbTypesWindow`, `_closeHelpWindow`, `_closeDbTypesWindow`, `_copyHelpCommandToInput`, the `[help]`/`BD types` highlight colors, and the Esc branches in `_handleCommandInputKeyEvent` so Esc pops only the most recently opened overlay (see research R6, data-model.md). Opening an already open overlay moves it to the top. Behavior with a single overlay must stay identical to today. (skill: `dart-use-pattern-matching` for the enum)

**Checkpoint**: Editor compiles; Help and BD types toggle as before.

---

## Phase 3: User Story 1 - Navigate the full graph on a dense schema (P1) 🎯 MVP

**Goal**: Every table and relationship line reachable by scroll; visible scrollbar per overflowing axis.

**Independent Test**: Quickstart scenario 1 and 6 (`schema_relacoes`; small schema unchanged).

- [X] T003 [US1] In `lib/src/components/editor/editor_component.dart` (graph `Positioned.fill` block in `build`), wrap the vertical `SingleChildScrollView` with a `Scrollbar(controller: _editorVerticalController)` and the inner horizontal one with a `Scrollbar(controller: _editorHorizontalController)` so a scrollbar is visible whenever that axis overflows and absent otherwise (research R1/R2). First read `~/.pub-cache/hosted/pub.dev/nocterm-0.8.0/lib/src/components/scrollbar.dart`: if `thumbVisibility: false` only shows the thumb while scrolling, set `thumbVisibility` from the controller's max scroll extent > 0. Keep Ctrl+arrow scrolling untouched. Owner decision: nocterm's `Scrollbar` is vertical-only, so the horizontal axis uses a one-line `◄▬▬░░░►` indicator (`_HorizontalScrollIndicator`) shown only while overflowing. (skill: `dart-run-static-analysis` after editing)
- [ ] T004 [US1] Verify on `schema_relacoes` (via `../dbs_schema_lazyforges`) that scroll extent reaches the last table and last relationship line on both axes and that the command input still spans the editor width; pass criterion: the last table and the last relationship line can be scrolled fully into view on both axes. If not, apply the smallest fix in `editor_component.dart` (e.g. constraining the scroll child) without modifying graph layout/routing files; only if that is impossible, report to the maintainer before touching `table_component.dart`/`graph_layout.dart` (FR-001, FR-011, FR-013). (skill: `dart-fix-runtime-errors` if a runtime error appears)

**Checkpoint**: US1 verifiable alone.

---

## Phase 4: User Story 2 - Read the full schema listing in the sidebar (P1)

**Goal**: Whole listing reachable by vertical scroll, long lines soft-wrapped, visible scrollbar.

**Independent Test**: Quickstart scenario 2.

- [X] T005 [P] [US2] In `lib/src/components/editor/components/sidebar/sidebar_component.dart`, make long rows soft-wrap within the sidebar width (explicit `softWrap: true` on column/FK/table `Text` rows; keep the existing `Container` width constraint) so no text is truncated and no horizontal scroll is needed (FR-003) (skill: `dart-write-documentation` only if public docs change).
- [X] T006 [US2] In `lib/src/components/editor/editor_component.dart` (`_buildSidebarPanel`), wrap the sidebar `SingleChildScrollView` in `Scrollbar(controller: _sidebarVerticalController)` (FR-002). (skill: `dart-run-static-analysis`)

**Checkpoint**: US2 verifiable alone.

---

## Phase 5: User Story 3 - Read Help and BD types without bleed-through (P1)

**Goal**: Both panels opaque, consistent, stackable (non-overlapping); most recent interactive.

**Independent Test**: Quickstart scenario 3.

- [X] T007 [US3] In `lib/src/components/editor/editor_component.dart`, add a shared `_buildOpaquePanel({required double width, required String title, required VoidCallback onClose, required List<Component> children})` using `Container` with `BoxDecoration(color: <solid color legible with cyan/yellow text>, border: BoxBorder.all(style: BoxBorderStyle.double))`; refactor `_buildHelpWindow` and `_buildDbTypesWindow` to use it while keeping their content, widths (70 / 32), `X` close button and "Esc fecha" hint (FR-004, FR-005, FR-006). (skill: `dart-write-documentation` for the helper's `///` doc)
- [X] T008 [US3] In `build` of `editor_component.dart`, keep each panel at its existing position (Help: right/bottom of the editor-pane `Stack`; BD types: left 1/bottom 2 of the root `Stack`); they sit in different screen areas and normally do not overlap (on narrow terminals of about 100 columns or fewer they may; BD types then paints above Help, accepted per spec edge cases), so only visibility changes: drive each from the overlay list. Ensure both can be open at once and closing one leaves no blanking (depends on T002, T007). (skill: `dart-run-static-analysis`)

**Checkpoint**: US3 verifiable alone.

---

## Phase 6: User Story 4 - Leave the editor without quitting; quit only from entry menu (P1)

**Goal**: Editor `sair`/Esc return to init; init has an explicit quit.

**Independent Test**: Quickstart scenarios 4 and 5.

- [X] T009 [US4] In `lib/src/components/editor/editor_component.dart`, add `final VoidCallback onExit` (required) to `EditorComponent`; header **sair** `onTap` calls `component.onExit()` instead of `shutdownApp()`; in `_handleCommandInputKeyEvent`, Esc, or `q` while `_commandController.text` is empty (`onKeyEvent` runs before text insertion and returning `true` consumes the key, verified in nocterm `text_field.dart` `_handleKeyEvent`; research R9), with an empty overlay list calls `component.onExit()` (return true); otherwise pops the most recently opened overlay (depends on T002). No extra save call: `EditorProvider.submitCommand` already persists synchronously (research R4). (skill: `dart-use-pattern-matching` for the key-event branches)
- [X] T010 [US4] In `lib/src/main.dart`, add `_exitEditor()` that does `setState` to `_screen = Screen.init` and `_activeProject = null`, and pass it as `onExit` to `EditorComponent` (depends on T009). Verify `InitComponent.initState` still calls `_reloadProjects()` when re-created (it does today) so the reopened project shows its last state. (skill: `dart-run-static-analysis`)
- [X] T011 [P] [US4] In `lib/src/components/init/components/init_component.dart`, add a visible **sair** control (Portuguese label with key hint) in browse mode that calls `shutdownApp()`; keep existing Esc-on-browse quit and all create/pick-database Esc behavior unchanged; add `q` as an additional quit key in `_handleBrowseKeyEvent` after the `_isCreating` guard so it never intercepts typing in the create-project text input or the database picker; show the hint (e.g. `Esc/q: sair`) in the browse help text (research R8, FR-009, FR-010) (skill: `dart-build-cli-app` for exit/shutdown conventions).

**Checkpoint**: All four stories work independently.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T012 Run `dart analyze` and `dart fix --apply` only for mechanical lint issues in touched files; ensure no new warnings versus T001 baseline (skill: `dart-run-static-analysis`).
- [X] T013 Confirm all new/edited comments are English and all TUI strings are Portuguese in touched files (copilot-instructions Language rule).
- [X] T014 Update `README.md` if it documents quitting from the editor or the init keys (editor **sair**/Esc now return to the entry menu; true quit on entry menu); skip if not documented.
- [ ] T015 Run the full `quickstart.md` manual validation from `../dbs_schema_lazyforges`, including small-schema regression, one project per engine (PostgreSQL, MySQL, SQLite; FR-014) and the five graphical layout rules; then ask the maintainer whether to set spec Status to `Implemented`. Do not commit/push without maintainer confirmation.
- [X] T016 Run the `test-manager-executer` agent (`.github/agents/test-manager-executer.md`) over the result as required by spec "Task Execution"; its output is informative and does not block delivery. Skip only if the maintainer waives it in writing (tests use temp dirs, never the app from the clone).

---

## Dependencies & Execution Order

- Phase 1 → Phase 2 (T002) → stories.
- US1 (T003–T004), US2 (T005–T006), US3 (T007–T008), US4 (T009–T011) are independent of each other after T002, but T003/T006/T007–T009 all edit `editor_component.dart`: execute those sequentially.
- T008 depends on T002 + T007; T009 depends on T002 and runs after T008 (same file); T010 depends on T009.
- Polish after all stories.

## Parallel Opportunities

- T005 (sidebar file), T011 (init file), and T010's `main.dart` edit (after T009) touch different files and can run in parallel with `editor_component.dart` work.

```text
Task: "Soft-wrap sidebar rows in sidebar_component.dart" (T005)
Task: "Add visible sair control in init_component.dart" (T011)
```

## Implementation Strategy

- **MVP**: Phase 1–2 + US1 (graph scroll with scrollbars), validate on `schema_relacoes`.
- **Incremental**: US2 → US3 → US4, validating each via its quickstart scenario. US4 is the only declared behavior change (editor **sair** no longer quits the process); call it out to the maintainer for release notes.

## Notes

- Graph layout/routing files stay unmodified; relationship-line guarantees must not regress.
- Commit only after maintainer confirmation.
