---

description: "Task list for fixing navigation of the editor canvas (mouse and keyboard)"
---

# Tasks: Fix navigation of the editor canvas (mouse and keyboard)

**Input**: Design documents from `specs/003-fix-mouse-navigation/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/ui-contract.md, quickstart.md

**Tests**: Not an acceptance criterion (constitution; copilot-instructions). No test tasks were requested; validation is manual via `quickstart.md`. Do NOT run the app from the repo clone; use `../dbs_schema_lazyforges`. Tests only if the maintainer asks (agent `test-manager-executer`).

**Organization**: Grouped by user story from `spec.md` (US1–US4). Allowed edits: `lib/src/components/editor/editor_component.dart` and `README.md` only. Do not touch `pubspec.yaml`, `CHANGELOG.md`, the sidebar, graph layout/routing files, or add barrels. Code comments in English; user-facing strings in Portuguese. Use nocterm 0.8.0 APIs confirmed in `~/.pub-cache/hosted/pub.dev/nocterm-0.8.0/lib/` (`GestureDetector`, `MouseRegion`, `MouseEvent.buttons`, `ScrollController`).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Parallelizable (different files, no dependency on an incomplete task)
- **[Story]**: US1 arrow buttons, US2 right-button pan, US3 keyboard, US4 remove Ctrl+arrows and keep the rest intact

## Path Conventions

- `lib/src/components/editor/editor_component.dart`
- `README.md`

All code tasks touch the same file, so they are sequential (no `[P]`); only the README task is parallel.

---

## Phase 1: Setup

- [X] T001 Run `dart pub get` and `dart analyze` at repo root; record baseline warnings so new ones can be distinguished (skill: `dart-run-static-analysis`)

---

## Phase 2: Foundational (Blocking Prerequisites)

None. Every story builds on the existing `_editorVerticalController` and `_editorHorizontalController` in `editor_component.dart`.

---

## Phase 3: User Story 1 - Move the graph with scrollbar arrow buttons (Priority: P1) 🎯 MVP

**Goal**: Clickable arrows at both ends of each scrollbar, hidden when the axis does not overflow.

**Independent Test**: On an overflowing graph, click `▲ ▼ ◄ ►`; each click moves 3 lines/columns and stops at the edges; clicking the track does nothing; on a small schema no bars appear.

- [X] T002 [US1] In `lib/src/components/editor/editor_component.dart`, change `_HorizontalScrollIndicator.build` to render `Row[GestureDetector(◄), track/thumb Text, GestureDetector(►)]` with the existing glyphs and cyan style; `◄` calls `controller.scrollUp(3)` and `►` calls `controller.scrollDown(3)` (step 3 columns, clamped by the controller); the track/thumb Text has no tap handler; keep returning `SizedBox(height: 0)` while `maxScrollExtent <= 0` or when the track is shorter than 2 cells (existing guard) (FR-001, FR-004, FR-007, FR-014)
- [X] T003 [US1] In `lib/src/components/editor/editor_component.dart`, add `_VerticalScrollIndicator` (StatefulComponent mirroring `_HorizontalScrollIndicator`: same listener + post-frame `setState`): `Column[GestureDetector(▲), Expanded(track/thumb lines), GestureDetector(▼)]`; `▲` calls `scrollUp(3)`, `▼` calls `scrollDown(3)` (step 3 lines); thumb size/position computed from `viewportDimension` and `maxScrollExtent` with the same formula and glyphs (`▬` thumb, `░` track, cyan) as the horizontal one; renders an empty 1-column `SizedBox` while `maxScrollExtent <= 0`, and also when the track would be shorter than 2 cells (`viewportDimension.floor() - 2 < 2`, same guard as the horizontal indicator) so tiny terminals never break layout; clicking track/thumb does nothing (FR-002, FR-003, FR-004, FR-014)
- [X] T004 [US1] In `lib/src/components/editor/editor_component.dart` `build()`, remove the nocterm `Scrollbar` wrapper around the vertical `SingleChildScrollView` and place `_VerticalScrollIndicator(controller: _editorVerticalController)` in a fixed 1-column gutter to the right of the canvas (a `Row` with `Expanded(canvas Stack)` and the indicator), leaving the bottom-right corner where the two bars meet empty (the horizontal bar spans only the canvas area), replacing only the `right: 1` part of the current `EdgeInsets.only(top: 1, right: 1)` padding (keep `top: 1`) so the gutter does not reflow when the bar hides; do not change the horizontal indicator placement, the command input width, or the sidebar (FR-009)

**Checkpoint**: Arrows work on both axes; bars hide when content fits.

---

## Phase 4: User Story 2 - Pan the graph by dragging with the right mouse button (Priority: P1)

**Goal**: Holding the right button and moving pans the canvas, content following the pointer.

**Independent Test**: Hold the right button and drag in all directions; content follows 1:1 until the edges; release inside/outside the canvas; later pointer movement leaves the canvas still; left-button drag does not pan.

- [X] T005 [US2] In `lib/src/components/editor/editor_component.dart`, add a nullable pan anchor field (last pointer x,y; `null` when no drag, see data-model.md) to `_EditorComponentState` and a handler `_handleCanvasPointer(MouseEvent event)`: if `event.buttons.contains(MouseButton.right)` then, when an anchor exists, apply `_editorHorizontalController.jumpTo((offset - dx).clamp(0, maxScrollExtent))` and the same for vertical with `dy` (content follows the pointer), then store the new anchor; otherwise set the anchor to `null` (ends the drag on the first event without `right`, including after a release outside the canvas) (FR-005, FR-006, FR-007). Import `MouseButton`/`MouseEvent` from nocterm as needed
- [X] T006 [US2] In `lib/src/components/editor/editor_component.dart` `build()`, wrap the canvas (`Positioned.fill` scroll view) in a `MouseRegion(onHover: _handleCanvasPointer, child: ...)`; ensure only the right button pans (left-button events must not move the canvas) and that `onExit` clears the anchor only if the right button is no longer in `event.buttons`; verify wheel handling and the Help overlay are unaffected

**Checkpoint**: Right-drag pans both axes; arrows still work.

---

## Phase 5: User Story 3 - Navigate the canvas by keyboard on any system (Priority: P1)

**Goal**: Modifier-free keyboard navigation.

**Independent Test**: With an empty input, `PageUp`/`PageDown` move one page vertically and `Left`/`Right` move 3 columns horizontally; with text in the input, `Left`/`Right`/`Home`/`End` move the cursor and `Up`/`Down` browse history.

- [X] T007 [US3] In `_handleCommandInputKeyEvent` of `lib/src/components/editor/editor_component.dart`, add: `LogicalKey.pageUp` → `_editorVerticalController.pageUp()` and `LogicalKey.pageDown` → `_editorVerticalController.pageDown()` (one page = `viewportDimension`, clamped), each returning `true`; `LogicalKey.arrowLeft` → `_editorHorizontalController.scrollUp(3)` and `LogicalKey.arrowRight` → `_editorHorizontalController.scrollDown(3)` returning `true` ONLY when `_commandController.text.isEmpty` (otherwise return `false` so the text field keeps moving the cursor); do not use any modifier key and do not touch `Home`, `End`, `Up`, `Down` (FR-013). Place the empty-input guard before the `q`/Esc leave logic and keep that logic untouched

**Checkpoint**: Full keyboard path available; typing and history unchanged.

---

## Phase 6: User Story 4 - Replace Ctrl+arrows and keep the rest intact (Priority: P2)

**Goal**: Remove the unreliable shortcut, update Help/README, confirm no regression.

**Independent Test**: `Ctrl`+arrows do not scroll; Help lists the new controls and not Ctrl+arrows; sidebar scroll and the five layout rules unchanged.

- [X] T008 [US4] In `_handleCommandInputKeyEvent` of `lib/src/components/editor/editor_component.dart`, delete the four `event.isControlPressed && LogicalKey.arrow*` scroll branches (FR-008); keep `Ctrl+C` and `Ctrl+E` and the unmodified `arrowUp`/`arrowDown` history branches exactly as they are
- [X] T009 [US4] In `_buildHelpWindow` of `lib/src/components/editor/editor_component.dart`, replace `Scroll editor: Ctrl + setas` with two Portuguese lines: `Navegar: PageUp/PageDown, setas esq/dir (input vazio)` and `Mouse: setas nas barras, botao direito arrasta` (ASCII-only to match neighbouring lines); keep the Help window within its current width (FR-011)
- [X] T010 [P] [US4] In `README.md`, update the navigation/shortcuts section: remove any mention of Ctrl+arrows and describe the arrow buttons, right-button drag, PageUp/PageDown, and Left/Right with an empty input (FR-011)

---

## Phase 7: Polish & Cross-Cutting

- [X] T011 Run `dart analyze` and `dart fix --apply` only for mechanical lints in `lib/src/components/editor/editor_component.dart`; confirm no new warnings versus T001 and that `grep -n "Ctrl + setas\|isControlPressed && event.logicalKey == LogicalKey.arrow"` in `lib/` returns nothing (skill: `dart-run-static-analysis`)
- [ ] T012 Manual validation per `specs/003-fix-mouse-navigation/quickstart.md` in `../dbs_schema_lazyforges` on `schema_relacoes` (never from the clone): arrows, track no-op, right-drag (record the terminal name if the drag is not forwarded), keyboard, Ctrl+arrows removed, sidebar and the five layout rules intact (SC-001 to SC-006; also confirms FR-012, cross-platform behavior)

---

## Dependencies & Execution Order

- T001 first. T002 → T003 → T004 (same file, US1). T005 → T006 (US2) depends on T004 only for a stable `build()`. T007 → T008 (same handler). T009 after T008. T010 is independent of code. T011 after T009; T012 last.
- Stories are independently testable: US1 alone is the MVP.

## Parallel Opportunities

- T010 (`README.md`) can run alongside any code task.
- Code tasks are sequential because they all edit `editor_component.dart`.

## Implementation Strategy

- MVP: Phase 1 + US1 (T001–T004), then validate arrows.
- Incremental: add US2 (pan), US3 (keyboard), then US4 (removal, Help, README), then polish and manual validation.
