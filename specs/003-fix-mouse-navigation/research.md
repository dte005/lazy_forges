# Research: Fix navigation of the editor canvas

## Decision 1: Arrow buttons via `GestureDetector.onTapDown`/`onTap`

- **Decision**: Wrap each arrow glyph in a `GestureDetector` that calls `scrollUp(3)` / `scrollDown(3)` on the matching `ScrollController`.
- **Rationale**: nocterm 0.8.0 `GestureDetector` handles left-button press/release reliably and needs no motion events. `ScrollController.scrollBy` already clamps to the valid range (FR-007).
- **Alternatives considered**: Track click-to-jump (rejected by the maintainer: clicking the track does nothing); thumb dragging (out of scope).

## Decision 2: Custom vertical indicator replacing nocterm `Scrollbar`

- **Decision**: Build `_VerticalScrollIndicator` mirroring `_HorizontalScrollIndicator`: `Column[▲, Expanded track/thumb, ▼]`, sized from `controller.viewportDimension` and `maxScrollExtent`. Place it in a `Row` to the right of the canvas, in the space currently used by the `Scrollbar` (the existing `right: 1` padding).
- **Rationale**: The built-in `Scrollbar` paints only and has no mouse handling, so arrows cannot be added to it.
- **Alternatives considered**: Overlay arrows on top of `Scrollbar` (fragile alignment); keep both bars (redundant, violates principle I).

## Decision 3: Right-button drag via `MouseRegion.onHover`

- **Decision**: Wrap the canvas in a `MouseRegion` whose `onHover` reads `MouseEvent.buttons`. When `right` is in `buttons`, compute `(dx, dy)` from the previous pointer position and call `jumpTo(offset - delta)` on both controllers (content follows the pointer). When `right` is absent, clear the drag state.
- **Rationale**: nocterm enables all-motion tracking (`?1003h`) and SGR mode (`?1006h`); `MouseTracker` enriches events with held buttons. `GestureDetector` handles only the left button, so `MouseRegion` is required. Clearing state on the first event without `right` satisfies FR-006 even when the release is not received.
- **Risk**: Some terminals (Terminal.app) may not forward right-button drag; arrows and keyboard remain the guaranteed paths.
- **Alternatives considered**: Middle button (less common on trackpads); left-button drag (conflicts with text selection and taps).

## Decision 4: Keyboard shortcuts without modifiers

- **Decision**: In `_handleCommandInputKeyEvent`: `pageUp`/`pageDown` call `pageUp()`/`pageDown()` on the vertical controller; `arrowLeft`/`arrowRight` call `scrollUp(3)`/`scrollDown(3)` on the horizontal controller only when `_commandController.text.isEmpty`. Remove the four Ctrl+arrow branches.
- **Rationale**: `input_parser.dart` matches `ESC[5~`/`ESC[6~` exactly, so modified PageUp/PageDown (for example Alt+PageUp = `ESC[5;3~`) never reach the app. Home/End are used by the text field for cursor movement. With an empty input the cursor has nothing to move, so Left/Right are free. Unmodified keys are not claimed by macOS, Linux, or Windows terminals.
- **Alternatives considered**: Alt+PageUp/PageDown (not parsed), Shift/Ctrl+PageUp (terminal tab/scrollback conflicts), Alt+h/l (needs "Option as Meta" on macOS), Home/End (cursor conflict).

## Decision 5: Mouse wheel stays out of scope

- **Decision**: No change to wheel handling (the inner horizontal scroll still captures it).
- **Rationale**: Spec non-goal; right-drag, arrows, and keys cover the "stuck" problem.

## Decision 6: Help and README

- **Decision**: Replace the Help line `Scroll editor: Ctrl + setas` with Portuguese lines describing PageUp/PageDown, Left/Right (empty input), arrow buttons, and right-button drag. Update the README navigation section.
- **Rationale**: FR-011; Help must never advertise a removed shortcut.

## Resolved clarifications

None pending.
