# Data Model: Fix editor chrome

No persisted data changes. `lazyforge_projects/` JSON is untouched.

## Transient UI state (`_EditorComponent`)

| Field | Type | Notes |
|---|---|---|
| `_overlayStack` | `List<_Overlay>` (`help`, `dbTypes`) | Replaces `_isHelpOpen` / `_isDbTypesOpen`; last = most recently opened; no duplicates. |
| scroll controllers | `ScrollController` ×3 | Existing; now also feed `Scrollbar`s. |

Transitions: open(x) → remove x if present, append; close(x) → remove; Esc, or `q` with empty command input → pop last if non-empty else `onExit()`.

## Component API

| Component | Change |
|---|---|
| `EditorComponent` | new `required VoidCallback onExit` |
| `_LazyForgeApp` | `_exitEditor()` → `_screen = Screen.init`, `_activeProject = null` |
| `InitComponent` | visible **sair** → `shutdownApp()` |
