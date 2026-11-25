# Research: Fix editor chrome

All technical unknowns resolved against `nocterm-0.8.0` sources and released code.

## R1 — Visible scroll affordance
- **Decision**: Wrap each scroll view with nocterm `Scrollbar(controller:, child:)`. Verify in `nocterm-0.8.0/lib/src/components/scrollbar.dart` whether the thumb renders only when content overflows; if `thumbVisibility: false` shows it only while scrolling, use `thumbVisibility: true` driven by the controller's max extent > 0 so it is visible whenever content overflows and absent otherwise.
- **Rationale**: Built-in, no dependency. Controllers already exist (`_editorVerticalController`, `_editorHorizontalController`, `_sidebarVerticalController`).
- **Alternatives**: Hand-drawn position marker (more code, violates simplicity).

## R2 — Graph clipping / reliable scroll
- **Decision**: Keep nested `SingleChildScrollView` (vertical outer, horizontal inner); add scrollbars; keyboard scroll stays Ctrl+arrows. Verify content size equals layout size on `schema_relacoes`; adjust only if extent is short of content (spec allows minimal layout-extent fix).
- **Rationale**: Existing behavior is source of truth (principle VIII).
- **Alternatives**: Custom viewport (rejected: complexity).

## R3 — Sidebar soft-wrap
- **Decision**: Rows stay `Text` (default `softWrap: true`, `overflow: clip`); ensure the sidebar column is width-constrained inside the scroll view so wrapping applies; vertical-only scroll with scrollbar.
- **Alternatives**: Truncate with ellipsis (rejected by clarification).

## R4 — "Flush auto-save" on sair
- **Decision**: No extra write. `EditorProvider.submitCommand` calls `saveProject` synchronously whenever a result persists, so disk already matches editor state at any exit point.
- **Rationale**: Avoids duplicate persistence path. If a future command mutates state without saving, add an explicit save in the exit handler.

## R5 — Opaque panels
- **Decision**: Shared `_buildOpaquePanel(width, title, onClose, children)` using `BoxDecoration(color: <solid>, border: double)`; Container paints background so nothing shows through. Pick one solid color (e.g. `Colors.black`) legible with cyan/yellow text.
- **Alternatives**: Separate styling per panel (inconsistent, FR-006).

## R6 — Concurrent overlays and Esc order
- **Decision**: Track overlay order with a small ordered list of enum values (`help`, `dbTypes`) in `_EditorComponent`; painting order = list order (last on top); Esc pops last. Help and BD types do not overlap on screen (different corners), so the list only determines which one Esc closes first (most recently opened); paint positions stay as today.
- **Rationale**: Minimal state satisfying the most-recently-opened-focus rule; reopening an open panel moves it to the end of the list.

## R7 — Leaving the editor without exiting
- **Decision**: Add `onExit` (`VoidCallback`) to `EditorComponent`; `_LazyForgeApp` sets `_screen = Screen.init` and clears `_activeProject`. Editor Esc handler (command input `onKeyEvent`) calls it when no overlay is open. `dispose()` already releases controllers; overlay state is local so it cannot leak.
- **Alternatives**: Navigator routes (not used in project; rejected).

## R8 — Init quit control
- **Decision**: Add a visible clickable/labelled `sair` entry (with key hint `Esc/q`) to `InitComponent` browse footer calling `shutdownApp()`; keep Esc-on-browse; add `q` as quit key in browse mode only (never during create-name input or database picker, where `q` is typed text). In the editor, `q` (and Esc) return to init, but `q` acts only when the command input is empty so commands containing `q` are not intercepted; with an overlay open it closes the topmost like Esc. This satisfies the project rule "new screen: q to quit" without breaking typing.

## R9 — `q` on an empty input
- **Decision**: Verified in `nocterm-0.8.0/lib/src/components/text_field.dart` (`_handleKeyEvent`): `onKeyEvent` runs before text insertion and returning `true` consumes the key. So the editor handler can intercept `q` when `_commandController.text.isEmpty` and let it through otherwise.
- **Alternatives**: Global key handler (rejected: would also fire while typing).
