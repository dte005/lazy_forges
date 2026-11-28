# Feature Specification: Fix navigation of the editor canvas (mouse and keyboard)

**Feature Branch**: `003-fix-mouse-navigation`

**Created**: 2026-11-28

**Status**: Planned

**Constitution note**: Principle IV (keyboard primary) is satisfied by the keyboard paging shortcuts in User Story 3; Principle VIII is satisfied because the removal of Ctrl+arrows is declared and justified here.

**Source issue**: To be created (fix: navegação por mouse no editor)

**Input**: User description: "Fix: mouse navigation of the editor canvas (graph) in large schemas. With large schemas the user gets stuck and cannot move around the graph. Keyboard scrolling exists only as Ctrl+arrows, which macOS often captures. The mouse wheel is consumed by the inner horizontal scroll, so the vertical axis never receives it. The scrollbars are visual only. Desired (mouse-only): clickable arrow buttons at both ends of each scrollbar (left/right on the horizontal bar, up/down on the vertical bar), each click moving the canvas by the same step as Ctrl+arrows; the vertical scrollbar must offer the same look and arrows as the horizontal one; clicking the track between the arrows does nothing; holding the right mouse button and dragging pans the canvas in both axes with the content following the mouse, ending as soon as the button is released, even outside the canvas. Out of scope: dragging the scrollbar thumb, wheel/Shift+wheel changes, new keyboard shortcuts, sidebar scroll changes, and any change to the five graphical layout rules. A cross-platform keyboard alternative is required (PageUp/PageDown vertical; Left/Right horizontal while the command input is empty), because the constitution requires every essential flow to be reachable by keyboard. Ctrl+arrows do not work reliably (for example on macOS) and must be replaced, not kept. The solution must work on any computer and operating system with a standard terminal, not only on macOS or Windows."

## Clarifications

### Session 2026-11-28

- Q: When the graph fits entirely on an axis, should that axis scrollbar hide or stay visible with inactive arrows? → A: It hides (arrows, track, and thumb) while there is no overflow on that axis.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Move the graph with scrollbar arrow buttons (Priority: P1)

As a developer working on a large schema, I want clickable arrow buttons at both ends of the graph's scrollbars so that I can move the canvas up, down, left, and right using only the mouse, without relying on keyboard shortcuts that my operating system may intercept.

**Why this priority**: This is the reliable, discoverable way out of the "stuck" state. It works even where the mouse wheel and Ctrl+arrows do not reach the canvas.

**Independent Test**: Open a project whose graph overflows in both axes. Click each of the four arrow buttons and confirm the canvas moves one step in the matching direction each time and stops at the edges.

**Acceptance Scenarios**:

1. **Given** a graph that overflows vertically, **When** the user clicks the down arrow at the end of the vertical scrollbar, **Then** the canvas content moves down by one step (3 lines) so lower content becomes visible; the up arrow does the reverse.
2. **Given** a graph that overflows horizontally, **When** the user clicks the right arrow at the end of the horizontal scrollbar, **Then** the canvas moves by one step (3 columns) so content further right becomes visible; the left arrow does the reverse.
3. **Given** the canvas is already at an edge, **When** the user clicks the arrow pointing past that edge, **Then** nothing changes and nothing breaks.
4. **Given** the vertical scrollbar, **When** it is shown, **Then** it looks consistent with the horizontal one (arrows at both ends, a track, and a thumb showing the current position and size).
5. **Given** the user clicks on the scrollbar track between the arrows, **When** the click is processed, **Then** nothing happens.

---

### User Story 2 - Pan the graph by dragging with the right mouse button (Priority: P1)

As a developer exploring a large graph, I want to hold the right mouse button and drag so the canvas follows my pointer, like panning a map, so I can reach any region quickly in both axes at once.

**Why this priority**: Arrow buttons are precise but slow over long distances. Right-button drag is the fast way to cover large schemas.

**Independent Test**: With an overflowing graph, hold the right button, move the pointer, and confirm the content follows the pointer in both axes; release inside and outside the canvas and confirm the drag always ends.

**Acceptance Scenarios**:

1. **Given** an overflowing graph, **When** the user holds the right button and moves the pointer left and up, **Then** the content moves left and up by the same distance (content follows the pointer) until the edges of the canvas are reached.
2. **Given** a drag in progress, **When** the user releases the right button inside the canvas, **Then** the drag ends and further pointer movement does not move the canvas.
3. **Given** a drag in progress, **When** the user releases the right button outside the canvas (or the release is not received), **Then** the drag still ends no later than the next pointer event that shows the right button is no longer held.
4. **Given** the user presses and drags with the left button, **When** moving the pointer, **Then** the canvas does not pan (only the right button pans).

---

### User Story 3 - Navigate the canvas by keyboard on any system (Priority: P1)

As a keyboard-first developer on any operating system, I want keys that scroll the canvas and are not intercepted by the OS, so I never need the mouse to reach any part of the graph.

**Why this priority**: The constitution requires every essential flow to work from the keyboard; the old Ctrl+arrows were the only keyboard path and fail on some systems.

**Independent Test**: With the command input focused and an overflowing graph, press PageUp/PageDown and confirm the canvas moves one page vertically per press; with an empty input press Left/Right and confirm it moves one step (3 columns) horizontally; both stop at the edges; typing commands, cursor movement in a non-empty input, and history navigation still work.

**Acceptance Scenarios**:

1. **Given** a graph that overflows vertically, **When** the user presses PageDown (or PageUp), **Then** the canvas moves one page (the visible height) down (or up), clamped at the edges.
2. **Given** a graph that overflows horizontally and an empty command input, **When** the user presses Right (or Left), **Then** the canvas moves one step (3 columns) right (or left), clamped at the edges.
3. **Given** text in the command input, **When** the user presses Left, Right, Home, End, Up, or Down, **Then** the cursor and command history keep behaving as before (Left/Right scroll the canvas only while the input is empty).

---

### User Story 4 - Replace the unreliable Ctrl+arrow scrolling and keep the rest intact (Priority: P2)

As a user on any operating system, I want canvas navigation that works everywhere, so the Ctrl+arrow scrolling that is intercepted on some systems is removed and replaced by the mouse navigation above, while the sidebar scroll and the five graphical layout rules stay as they are.

**Why this priority**: A control that works only on some computers is a defect, not a feature. Keeping it would leave a dead shortcut and misleading Help text.

**Independent Test**: Press Ctrl+arrows on the canvas and confirm they no longer scroll it and are no longer listed in Help; scroll the sidebar and review the layout rules after the change.

**Acceptance Scenarios**:

1. **Given** the editor is open, **When** the user opens Help, **Then** it no longer advertises Ctrl+arrows and instead describes the arrow buttons and the right-button drag; pressing Ctrl+arrows no longer scrolls the canvas.
2. **Given** the editor is open, **When** the user scrolls the left sidebar, **Then** it behaves as before.
3. **Given** the editor is open, **When** the user reviews the layout, **Then** the five graphical layout rules still hold (canvas scrolls, sidebar scrolls vertically, command input spans the editor width, dropdown is opaque, relationship lines do not cross table boxes).

---

### Edge Cases

- The graph does not overflow on an axis: that axis scrollbar (arrows, track, and thumb) is hidden, and a right-button drag does not move the canvas on that axis.
- A schema that grows or shrinks while the user is dragging: the canvas stays within its valid range.
- The terminal does not report right-button drag events: the arrow buttons remain fully usable, so the canvas is always reachable.
- Very small terminal windows: arrows must not overlap the thumb in a way that makes the bar unreadable; at minimum the arrows remain clickable.
- The user right-clicks without moving: nothing changes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The horizontal scrollbar MUST show a left arrow and a right arrow at its two ends; clicking one MUST scroll the canvas one step (3 columns) in that direction.
- **FR-002**: The vertical scrollbar MUST show an up arrow and a down arrow at its two ends; clicking one MUST scroll the canvas one step (3 lines) in that direction.
- **FR-003**: The vertical scrollbar MUST be visually consistent with the horizontal one (arrows at both ends, track, and a thumb reflecting position and size).
- **FR-004**: Clicking on the scrollbar track between the arrows MUST NOT scroll the canvas.
- **FR-005**: Holding the right mouse button and moving the pointer over the canvas MUST pan the canvas in both axes so that the content follows the pointer.
- **FR-006**: A right-button drag MUST end as soon as the right button is released, and no later than the next pointer event that shows it is no longer held, including when the release happens outside the canvas.
- **FR-007**: The canvas offset MUST always stay within its valid range (no scrolling past the first or last content).
- **FR-008**: The Ctrl+arrow canvas scrolling MUST be removed (code and Help text) and replaced by the mouse and keyboard navigation defined above.
- **FR-009**: The left sidebar scroll and the five graphical layout rules MUST remain unchanged.
- **FR-010**: Dragging the scrollbar thumb, mouse-wheel/Shift+wheel changes, and any keyboard shortcut that uses modifier keys are NOT part of this change; the only new keyboard shortcuts are those defined in FR-013.
- **FR-011**: The Help text (Portuguese) and `README.md` MUST describe the new navigation (arrow buttons, right-button drag, and the paging shortcuts) and MUST NOT mention Ctrl+arrows.
- **FR-012**: Canvas navigation MUST NOT depend on operating-system-specific shortcuts; the arrow buttons MUST work in any terminal that reports basic mouse clicks, on any operating system.
- **FR-013**: PageUp/PageDown MUST scroll the canvas vertically by one page. While the command input is empty, Left/Right MUST scroll the canvas horizontally by one step (3 columns). With a non-empty input, Left/Right, Home, End, Up, and Down MUST keep their current meaning. No shortcut may rely on modifier keys (Ctrl/Alt/Shift).
- **FR-014**: A scrollbar (arrows, track, and thumb) MUST be shown only while the content overflows on its axis, and hidden otherwise.

### Key Entities

- **Canvas offset**: the current vertical and horizontal scroll position of the graph; changed by arrow clicks and right-button drag.
- **Scrollbar**: a visual control per axis with two arrow buttons, a track, and a thumb.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On a schema that overflows in both axes, a user can bring any table into view using only the mouse in under 15 seconds, without using the keyboard.
- **SC-002**: Each arrow click moves the canvas exactly one step (3 lines or columns) until an edge is reached, and never beyond it.
- **SC-003**: After releasing the right button (inside or outside the canvas), 100% of subsequent pointer movements leave the canvas still.
- **SC-004**: Sidebar scrolling behaves identically to the previous version in a side-by-side manual check, and Help no longer mentions Ctrl+arrows.
- **SC-005**: A manual run on the maintainer's real terminal confirms the arrow buttons and the right-button drag, or records which terminals do not forward right-button drag.
- **SC-006**: A user can reach any table using only the keyboard shortcuts, on macOS, Linux, and Windows terminals.

## Assumptions

- Terminals deliver plain PageUp/PageDown and Left/Right to the application. Modifier combinations (Alt+PageUp, Shift+PageUp, Ctrl+PageUp) are deliberately avoided: the input layer does not recognise modified PageUp/PageDown, and terminals or the OS often intercept them.
- Mouse reporting is enabled by the terminal (already required for existing mouse-wheel support).
- Some terminals (for example macOS Terminal.app) may not forward right-button drag events; this is a known risk, and the arrow buttons are the guaranteed, terminal-independent fallback.
- One step equals 3 lines or columns.
- Clicking and holding an arrow does not repeat the scroll; one click equals one step.
- No new dependencies are required.
- Manual validation runs in `../dbs_schema_lazyforges`, never from the repository clone.

## How to Validate Manually

1. From `../dbs_schema_lazyforges`, open a project with a graph larger than the window (for example `schema_relacoes`).
2. Click each scrollbar arrow and check one-step movement and edge behavior.
3. Click on the track and confirm nothing happens.
4. Hold the right button and drag in all directions; release inside and outside the canvas.
5. Press PageUp/PageDown (one page vertically) and, with an empty input, Left/Right (3 columns horizontally); type some text and confirm Left/Right move the cursor instead. Press Ctrl+arrows to confirm they no longer scroll the canvas, check that Help no longer lists them, and scroll the sidebar to confirm no regression.

## Out of Scope

- Dragging the scrollbar thumb.
- Mouse-wheel or Shift+wheel changes.
- Other new keyboard shortcuts (Alt+arrows, Home/End for the canvas, any Shift/Ctrl/Alt combination). This change removes the unreliable Ctrl+arrows and adds only the paging shortcuts above.
- Changes to the left sidebar scroll.
- Any change to the five graphical layout rules.

## Constraints

- TUI uses `nocterm` only; no new dependencies.
- In-app messages and Help text in Portuguese; specs, docs, and code comments in English.
- Command parsing stays in providers; this change is UI-only.
- Do not change `pubspec.yaml` or `CHANGELOG.md` without the maintainer's approval.
