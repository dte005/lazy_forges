# Data Model: Fix navigation of the editor canvas

No persisted data changes. JSON projects in `lazyforge_projects/` are untouched.

## In-memory state (inside `editor_component.dart`)

| Name | Type | Purpose |
|------|------|---------|
| `_editorVerticalController` | `ScrollController` (existing) | Canvas vertical offset |
| `_editorHorizontalController` | `ScrollController` (existing) | Canvas horizontal offset |
| Pan anchor | nullable pointer position (x, y) | Last pointer position while the right button is held; `null` when no drag is active |

## Rules

- Offsets are always clamped to `0..maxScrollExtent` (done by the controller).
- Arrow step: 3 lines or columns. Page step: `viewportDimension` (vertical only).
- Pan anchor lifecycle: set on the first hover event with `right` in `buttons`; updated on each such event; cleared on the first event without `right` or when the component is disposed.
- Indicators render nothing while `maxScrollExtent <= 0` on that axis (clarified 2026-11-28).
