# Feature Specification: Fix editor chrome for dense schemas and exit navigation

**Feature Branch**: `002-fix-editor-chrome`

**Created**: 2026-11-24

**Status**: Implemented

**Input**: User description: "Fix LazyForge editor chrome so dense schemas remain fully navigable, overlays stay readable, and exit navigation returns to the entry menu instead of killing the process from the editor. Problems: graph canvas clips content and scroll is unreliable; left schema sidebar clips long listings; Help overlay is transparent; BD types floating panel is transparent; editor \"sair\" quits the whole process instead of returning to entry menu; entry menu needs an explicit quit control. Validation target: workspace project schema_relacoes (13 tables, many FKs) under dbs_schema_lazyforges. Product graphical rules from copilot-instructions; relationship lines must not invade table boxes."

## Clarifications

### Session 2026-11-25

- Q: When a schema sidebar line is longer than the panel width, how must the user be able to read the full text? → A: Soft-wrap long lines within the sidebar width (vertical scroll only).

- Q: When the user activates **sair** in the editor, what must happen to the open project’s saved state before returning to the entry menu? → A: Always flush pending auto-save to disk, then return to init (no confirm dialog).
- Q: While the editor is open, may the Help overlay and the BD types panel be visible at the same time? → A: Both may be open at once (stacked; topmost panel receives interaction focus).
- Q: Must the graph canvas and schema sidebar show a visible scroll indicator (for example a scrollbar or position marker), or is it enough that existing keyboard/input scroll reaches all content? → A: Visible scroll affordance required on graph and sidebar whenever content overflows.
- Q: In the editor, what should the Escape key do when no floating panel is open? → A: Esc with no overlay open returns to init like **sair** (flush auto-save; process stays alive); Esc with an overlay open closes the topmost overlay first.
- Q: Should the term "editor chrome" be kept or replaced with a clearer term? → A: Keep "editor chrome" (UI around the graph: header, sidebar, scrollbars, floating panels, exit controls).
- Q: Which keys leave the editor and which quit the app? → A: In the editor, Esc and **q** (empty input only) and **sair** return to the entry menu; on the entry menu, **sair**, Esc (browse) and **q** (browse) quit the whole app.
## User Scenarios & Testing *(mandatory)*

### User Story 1 - Navigate the full graph on a dense schema (Priority: P1)

As a developer modeling a large schema (many tables and relationships), when I open the project in the editor, I want to scroll the graph canvas vertically and horizontally as needed so every table and relationship line remains reachable, even when content extends beyond the visible pane.

**Why this priority**: On dense schemas the graph is the primary way to understand structure. If content is clipped and scroll does not reach the edges, the editor fails its core purpose for non-trivial projects.

**Independent Test**: Open a project with 12+ tables and many foreign keys (e.g. `schema_relacoes`). Confirm off-screen tables can be brought fully into view by scrolling vertically and horizontally. Open a small 2–3 table schema and confirm prior usable behavior is unchanged.

**Acceptance Scenarios**:

1. **Given** a dense project with 12+ tables and FKs (e.g. `schema_relacoes`), **When** the editor opens and the user scrolls the graph canvas vertically and horizontally as needed, **Then** every table drawing and relationship line that belongs to the schema can be brought fully into view (no permanent clipping at the edges of the reachable canvas), and a visible scroll affordance appears on each axis that overflows.
2. **Given** a small schema (2–3 tables) that previously fit or scrolled acceptably, **When** the editor opens, **Then** graph navigation remains usable and does not regress relative to prior behavior on that size of schema.

---

### User Story 2 - Read the full schema listing in the sidebar (Priority: P1)

As a developer inspecting tables, columns, keys, and references in the left schema sidebar, I want reliable vertical scrolling (and no silent loss of long line content at the edge) so the entire listing is reachable on dense schemas.

**Why this priority**: The sidebar is the structured inventory of the model. Clipping the bottom of a long listing hides tables/columns/FKs the user needs while editing.

**Independent Test**: Open the same dense project; scroll the left sidebar from top to bottom; confirm every table/column/PK/FK/reference line can be brought into view. Spot-check long lines soft-wrap within the sidebar width and remain fully readable via vertical scroll only.

**Acceptance Scenarios**:

1. **Given** a dense project whose sidebar listing exceeds the visible height, **When** the user scrolls the sidebar vertically, **Then** every listed table, column, PK/FK, and reference line can be brought into view (no inaccessible tail of the list), and a visible scroll affordance is shown while the listing overflows.
2. **Given** sidebar rows with long text, **When** the listing is viewed, **Then** long lines soft-wrap within the sidebar width and remain fully readable via vertical scroll only (no silent truncation at the panel edge; no separate horizontal scroll required to read them).

---

### User Story 3 - Read Help and BD types overlays without bleed-through (Priority: P1)

As a developer using the Help overlay or the BD types panel while the graph or sidebar is painted behind them, I want those floating panels fully opaque so only the panel content is readable and nothing from behind shows through.

**Why this priority**: Transparent overlays violate product graphical readability rules and make command help and type lists hard or impossible to use over a dense graph.

**Independent Test**: Open Help over a painted graph; open BD types over sidebar/graph content (including with Help still open); confirm no underlying drawing is visible through either panel background. Prefer one consistent opaque-panel pattern for both; when open together, most recently opened panel is interactive.

**Acceptance Scenarios**:

1. **Given** Help is open over a painted graph, **When** the user reads the help content, **Then** no graph tables or relationship lines are visible through the help background (fully opaque), and help text remains legible.
2. **Given** the BD types panel is open, **When** the user reads the type list, **Then** no sidebar or graph content is visible through that panel background (fully opaque), and the type list alone is readable.
3. **Given** Help is already open, **When** the user also opens the BD types panel (or the reverse), **Then** both panels may remain visible together, each fully opaque over what is behind it, with the most recently opened panel receiving interaction focus.

---

### User Story 4 - Leave the editor without quitting; quit only from entry menu (Priority: P1)

As a developer who finished or wants to switch projects, when I activate **sair** in the editor I want to return to the entry/init menu with the process still running so I can open or create another project. When I am on the entry menu and want to leave LazyForge entirely, I want an explicit **sair** (visible, and keyboard if consistent with existing init UX) that exits the application cleanly.

**Why this priority**: Quitting the whole process from the editor forces a restart to switch projects and confuses “leave editor” with “leave app”. True quit belongs on the entry screen.

**Independent Test**: From the editor, activate **sair** and confirm the entry menu appears and the process stays alive. Repeat with Escape, and with **q** on an empty command input, when no overlay is open. With Help or BD types open, confirm Escape (or **q** on an empty input) closes the most recently opened overlay first. Confirm typing a **q** inside a command is not intercepted. From the entry menu, activate the explicit quit control, press **q**, or press Escape, and confirm the application exits cleanly (**q** typed in the create-project name input must just type). Confirm Esc-on-browse quit behavior is not broken, and that editor no longer shuts down the process.

**Acceptance Scenarios**:

1. **Given** the user is in the editor with a project open, **When** they activate **sair** in the editor chrome, **Then** they return to the init/entry menu, LazyForge keeps running, and they can open or create another project without restarting the process.
2. **Given** the user is on the entry/init menu, **When** they activate the explicit **sair** control (new or existing user-visible control), **Then** the application exits cleanly (process ends via the product’s normal shutdown path).
3. **Given** the user leaves the editor via **sair**, **When** they land on the entry menu, **Then** the editor session is left cleanly (no stuck editor-only state blocking init flows), and any pending auto-save has been flushed so the project on disk matches the last editor state (no save/discard prompt on **sair**).
4. **Given** the user is in the editor with no floating panel open, **When** they press Escape, or press **q** while the command input is empty, **Then** they return to the entry/init menu with the same guarantees as editor **sair** (auto-save flush, process still running).
5. **Given** the user is in the editor and the command input contains text, **When** they type the letter **q**, **Then** it is inserted as text and the editor is not left.
6. **Given** Help and/or BD types are open, **When** the user presses Escape (or **q** with an empty input), **Then** the most recently opened panel closes first; the editor session remains active until the key is pressed again with no overlay open or **sair** is activated.
7. **Given** the user is on the entry menu browsing projects, **When** they press **q**, **Then** the application exits cleanly; **Given** the create-project name input or database picker is active, **When** they press **q**, **Then** it is typed or ignored and the app does not exit.

---

### Edge Cases

- What happens when the graph content fits entirely in the visible pane (no overflow)? Scroll should not break layout or hide content; small schemas must remain usable. Visible scroll affordances are required only while content overflows; they need not appear when content fully fits.
- What happens when only one axis overflows (very tall but narrow, or very wide but short)? The overflowing axis must still be fully reachable.
- What happens when Help and BD types are both open at once (open together) or opened in sequence (open one after the other, or close and reopen)? Each open panel must remain fully opaque over content behind it; the most recently opened panel has interaction focus; on narrow terminals (about 100 columns or fewer) the two panels may overlap, in which case BD types is painted above Help and both remain opaque; closing a panel restores what was under it without leftover blanking artifacts that hide the graph permanently.
- What happens when the user activates editor **sair** with Help or BD types still open? User returns to init; process must not exit; transient overlay state must not leak into the next editor open in a broken way.
- What happens when the user presses Escape (or **q** on an empty input) in the editor? If a floating panel is open, close the most recently opened panel only; if no floating panel is open, behave like editor **sair** (flush auto-save, return to init, do not exit the process).
- What happens to project data on editor **sair**? Pending auto-save MUST be flushed to disk before returning to init; no confirm dialog; reopening the project MUST reflect the last editor state.
- What happens if an explicit **sair** already exists on init in some mode? Prefer clarifying and wiring the visible quit path rather than duplicating confusing controls; at least one clear user-visible quit action must exist on the entry menu.
- What happens on engines PostgreSQL, MySQL, and SQLite? UI/navigation only — behavior must be the same for all engines.
- Relationship lines must still never invade table box interiors after scroll/chrome changes (no regression of graph routing guarantees).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The editor graph canvas MUST allow the user to scroll vertically and horizontally as needed so that, on dense schemas (12+ tables with FKs), every table drawing and relationship line can be brought fully into view. Scroll MUST feel effectively unlimited for content that exists in the layout (no silent hard stop that leaves remaining content unreachable). Whenever graph content overflows the visible viewport on an axis, the graph canvas MUST show a visible scroll affordance (scrollbar or equivalent position marker) for that axis.
- **FR-002**: The left schema sidebar MUST allow the user to scroll vertically through the entire listing of tables, columns, keys, and references so no part of the listing remains inaccessible on dense schemas. Whenever the sidebar listing overflows the visible height, the sidebar MUST show a visible scroll affordance (scrollbar or equivalent position marker).
- **FR-003**: Long sidebar lines MUST soft-wrap within the sidebar width so the full text remains readable via vertical scroll only; content MUST NOT be silently truncated at the panel edge, and the sidebar MUST NOT require a separate horizontal scroll axis to read long lines.
- **FR-004**: The Help overlay MUST render with a fully opaque solid background so no graph or other underlying content shows through while Help is open.
- **FR-005**: The BD types floating panel MUST render with a fully opaque solid background so no sidebar or graph content shows through while it is open.
- **FR-006**: Help and BD types SHOULD share one consistent opaque floating-panel presentation pattern so both meet the same readability standard. The two panels MAY be open at the same time (open together). When both are open, each MUST remain fully opaque over whatever is behind it; the most recently opened panel MUST receive interaction focus until closed or replaced as most recently opened.
- **FR-007**: Activating **sair** in the editor MUST return the user to the entry/init menu and MUST NOT terminate the LazyForge process. Escape in the editor MUST follow the same leave-editor path when no floating panel is open (return to init, flush pending auto-save, process stays alive). The key **q** MUST behave exactly like Escape in the editor, but only while the command input is empty (so typing commands is never intercepted). When one or more floating panels are open, Escape (or **q** on an empty input) MUST close the topmost panel first, where topmost means the most recently opened panel, and MUST NOT leave the editor until no overlay remains and the key is pressed again (or **sair** is activated). Help (bottom right of the editor pane) and BD types (bottom left of the screen) occupy different screen areas and do not overlap, so they MAY be open at the same time without any paint-order dependency.
- **FR-008**: Leaving the editor via **sair** MUST leave the editor session cleanly so the user can open or create another project from init without restarting the process. Before returning to init, the product MUST flush any pending auto-save so the project on disk matches the last editor state; **sair** MUST NOT show a save/discard confirm dialog.
- **FR-009**: The entry/init menu MUST expose an explicit user-visible **sair** (or equivalent labeled quit control). If none exists today, one MUST be added. That control MUST quit the application via the product’s normal clean shutdown path.
- **FR-010**: Keyboard quit on the entry menu MUST remain consistent with existing init UX where applicable (Esc on browse quits today and MUST keep quitting; the key **q** MUST also quit while browsing projects, but MUST NOT act while the create-project name input or database picker is active); the explicit visible control and any keyboard quit MUST both end the process cleanly, never via a raw forced process kill outside the product shutdown path.
- **FR-011**: The command input MUST continue to span the full width of the editor pane (no regression of input layout).
- **FR-012**: User-facing strings for these controls and related messages MUST remain in Portuguese, clear and actionable.
- **FR-013**: Graph relationship lines MUST continue to respect the rule that lines do not invade table box interiors (no regression of existing routing guarantees).
- **FR-014**: Changes MUST apply equally for all supported engines (PostgreSQL, MySQL, SQLite); this feature is UI and navigation only.
- **FR-015**: Small schemas (2–3 tables) MUST remain usable after scroll, overlay, and navigation changes (no regression of prior acceptable behavior).

### Key Entities

- **Editor session**: The active modeling view for one opened project (graph, sidebar, command input, overlays). Leaving via **sair** flushes pending auto-save, ends this session, and returns to init without ending the process.
- **Entry / init menu**: The first screen for listing, opening, and creating projects; owns true application quit.
- **Graph canvas**: The visual area showing table boxes and relationship lines; may extend beyond the visible viewport on dense schemas.
- **Schema sidebar**: The structured listing of tables, columns, keys, and references for the open project.
- **Floating panels (Help, BD types)**: Temporary overlays that must fully obscure underlying UI while open so their content stays readable.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On a dense reference project (12+ tables with FKs, e.g. `schema_relacoes`), a user can bring every table and relationship line into view using graph scroll within a single editor session without restarting the app, and a visible scroll affordance is present on each overflowing graph axis.
- **SC-002**: On the same dense project, a user can bring every sidebar listing line into view using vertical scroll within a single editor session, including full text of long lines that soft-wrap within the sidebar width, and a visible scroll affordance is present while the listing overflows.
- **SC-003**: With Help open over a painted graph, a reviewer confirms zero visible bleed-through of underlying graph content through the help background.
- **SC-004**: With BD types open, a reviewer confirms zero visible bleed-through of underlying sidebar/graph content through the panel background.
- **SC-005**: Activating editor **sair** returns to the entry menu in 100% of trials, leaves the process running so another project can be opened or created without a process restart, and persists the last editor state via auto-save flush (reopen shows that state; no save prompt on **sair**).
- **SC-006**: Activating entry-menu **sair**, pressing **q** or Esc while browsing, ends the application cleanly in 100% of trials (process exits via normal shutdown).
- **SC-007**: On a small schema (2–3 tables), graph, sidebar, overlays, and navigation remain usable with no reported regression versus prior behavior for that schema size.
- **SC-008**: After the change, relationship lines still do not invade table box interiors on schemas used for manual validation (including dense FK layouts).
- **SC-009**: With Help and BD types open together, a reviewer confirms both remain usable (each opaque, most recently opened receives focus) and closing them restores the underlying editor view without permanent blanking.
- **SC-010**: Escape (or **q** on an empty input) with no editor overlay open returns to init without ending the process in 100% of trials; Escape with overlays open closes only the most recently opened overlay per press.

## Assumptions

- Manual validation will use the workspace project `schema_relacoes` under `dbs_schema_lazyforges` (or an equivalent 12+ table schema with many FKs) as the primary dense-schema fixture.
- “Effectively unlimited” scroll means the user can reach all content that the layout produces for the open schema; it does not require infinite empty canvas beyond content bounds, but MUST NOT stop short of existing content. Visible scroll affordances (scrollbar or equivalent marker) are required on graph and sidebar whenever that pane’s content overflows; they are not required when content fully fits.
- Opaque floating panels use a solid background consistent with product graphical rules; exact color tokens are a planning/implementation detail as long as opacity and readability hold. Help and BD types may be open simultaneously (open together); the most recently opened has focus.
- Editor **sair** is a deliberate behavior change from “quit process” to “return to init”; this change is in scope and must be called out in planning and release notes if any. On **sair**, pending auto-save is flushed with no confirm dialog (constitution automatic-save rule).
- True process exit remains solely an entry-menu responsibility (explicit **sair** and the Esc-on-browse and **q**-on-browse quits). In the editor, Escape and **q** never quit the process: it closes the topmost overlay if any, otherwise it leaves the editor like **sair**.
- No new modeling commands, DDL changes, MCP TUI tools, or graph-routing rewrites are required unless a minimal routing/layout adjustment is strictly necessary for correct scroll extent; prefer chrome and navigation fixes.
- Automated graphical emulation tests are optional and only with maintainer approval; default validation is manual in the running TUI.
- Portuguese labels **sair**, Help, and BD types remain the user-facing names unless product copy already uses a fixed synonym on init.

## How to Validate Manually

1. From the workspace, open LazyForge and load `schema_relacoes` (or equivalent dense project).
2. Scroll the graph vertically and horizontally; confirm off-screen tables and lines become fully visible and a visible scroll affordance is present on overflowing axes.
3. Scroll the left sidebar top-to-bottom; confirm every table/column/FK/reference line is reachable; confirm a visible scroll affordance while the list overflows; check long lines soft-wrap within the sidebar width and remain fully readable via vertical scroll only.
4. Open Help over the painted graph; confirm opaque background and readable text with no bleed-through; close Help.
5. Open BD types (also try with Help still open, and with a narrow terminal); confirm each open panel is opaque with no bleed-through; the most recently opened is interactive; close panels and confirm the graph/sidebar restore without permanent blanking.
6. Activate editor **sair**; confirm return to entry/init menu and that the process is still running; confirm no save/discard prompt; reopen the same project and confirm last editor state was persisted; open or create another project. Also verify Escape with no overlay open matches **sair**, and Escape with Help/BD types open closes the most recently opened overlay first.
7. From the entry menu, activate explicit **sair**; confirm the application exits cleanly.
8. Repeat graph/sidebar/overlay checks on a small 2–3 table schema; confirm no regression.
9. Spot-check that relationship lines still do not cross into table box interiors.

## Task Execution

- Every activity/task for this spec (technical planning and implementation) MUST rely on the Dart skills already available in the project under `.github/skills/` when a relevant skill exists (tasks name the skill where one applies), consulting the skill appropriate to the work instead of inventing an approach when an equivalent skill already exists.
- At the end of executing all tasks for this spec, the `test-manager-executer` subagent (defined in `.github/agents/test-manager-executer.md`) MUST be run so planned test verification runs over the result before considering the work complete, unless the maintainer explicitly waives automated tests for this UI-only change in favor of documented manual validation only.

## Out of Scope

- New modeling commands, command-parser changes, or DDL export changes.
- MCP TUI tools.
- Rewriting graph relationship routing except if strictly required to establish correct scrollable content extent.
- New dependencies without explicit maintainer approval.
- Automated nocterm/graphical emulation tests unless the maintainer approves them for this feature.
- Changing engine-specific type catalogs beyond display of the existing BD types panel chrome.

## Constraints

- Do not change released behavior outside the bugs and the declared navigation change in this spec (constitution stability principle — `.specify/memory/constitution.md`). Editor **sair** changing from process quit to back-to-init is an explicit, justified behavior change documented here.
- Preserve loading of existing saved projects.
- Respect existing folder organization under `lib/src/`.
- Do not add new dependencies to `pubspec.yaml` without asking.
- User-facing messages in Portuguese, clear and without stack traces.
- Spec Kit artifacts remain in English; UI strings remain in Portuguese.
- Command input full width of the editor pane must be preserved.
- Product graphical layout rules (opaque overlays; lines must not invade table boxes) remain binding.
