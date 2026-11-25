# Implementation Plan: Fix editor chrome for dense schemas and exit navigation

**Branch**: `002-fix-editor-chrome` | **Date**: 2026-11-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/002-fix-editor-chrome/spec.md`

## Summary

Chrome/navigation fix in the editor and app shell, with no change to graph
routing, commands, DDL, or storage:

1. **Graph canvas**: wrap the existing nested `SingleChildScrollView`s in
   nocterm `Scrollbar`s (one per axis) so overflow is visible and reachable.
2. **Sidebar**: soft-wrap long lines (nocterm `Text` already defaults to
   `softWrap: true`; ensure rows are width-constrained) and add a vertical
   `Scrollbar` on `_sidebarVerticalController`.
3. **Help / BD types**: give both panels a solid `BoxDecoration(color: ...)`
   through one shared `_buildOpaquePanel` helper; allow both open at once; they do not overlap
   (Help bottom-right of the editor pane, BD types bottom-left), so positions
   stay as today and "topmost" only means most recently opened (Esc order); on narrow terminals they may overlap and BD types paints above Help (accepted).
4. **Esc / q / sair**: editor `sair`, Esc and `q` (`q` only on an empty input) call a new
   `onExit` callback instead of `shutdownApp()` when no overlay is open. `_LazyForgeApp` switches
   `_screen` back to `Screen.init`. Esc/`q` with overlays closes the most recently opened only.
5. **Init**: add a visible **sair** control that calls `shutdownApp()`; keep
   Esc-on-browse quit and add `q` (browse mode only) as a quit key.

## Technical Context

**Language/Version**: Dart (SDK ^3.11.4)

**Primary Dependencies**: `nocterm ^0.8.0` only; no new dependency.

**Storage**: N/A changes. `EditorProvider.submitCommand` already calls
`ProjectStorage.saveProject` synchronously after each persisting command, so
"flush on sair" holds with no extra write (see research.md R4).

**Testing**: Not an acceptance gate (constitution). Manual validation per
`quickstart.md`; tests only if the maintainer asks (`test-manager-executer`).

**Target Platform**: Cross-platform terminal (Linux, WSL, macOS, Windows).

**Project Type**: Terminal TUI application (Dart package, pub.dev).

**Performance Goals**: Scroll/overlay toggles feel instant on 13-table schema.

**Constraints**: Keyboard-first; PT-BR user strings; English comments; no new
barrels; do not touch `pubspec.yaml`/`CHANGELOG.md`; graph rules 1–5 preserved.

**Scale/Scope**: ~4 files: `editor_component.dart`, `sidebar_component.dart`,
`main.dart`, `init_component.dart`.

## Constitution Check

*GATE: passed before research; re-checked after design — still PASS.*

| Principle | Status | Note |
|---|---|---|
| I Interface serves decisions | PASS | Scrollbars show position only when overflowing; opaque panels improve readability. |
| II Commands speak SQL | PASS | No command changes. |
| III Portable output | PASS | No format/DDL change. |
| IV Terminal end to end | PASS | Esc, `q` and existing keys work; **sair** also reachable by Esc/`q` (keyboard). |
| V Perceived speed | PASS | No layout recomputation added. |
| VI Trust / auto-save | PASS | Saves already synchronous per command; sair loses nothing. |
| VII Simplicity | PASS | One shared panel helper, one callback; no new abstractions. |
| VIII Stability | PASS with declared change | Editor **sair** no longer quits process (explicit in spec, FR-007); Esc in editor previously did nothing outside overlays. Entry Esc quit kept. |

Graph rules (copilot-instructions) 1–5: preserved/strengthened (1, 2, 4);
3 and 5 untouched.

## Project Structure

### Documentation (this feature)

```text
specs/002-fix-editor-chrome/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/ui-contract.md
└── tasks.md             # created by /speckit-tasks
```

### Source Code (repository root)

```text
lib/src/
├── main.dart                                   # pass onExit; Screen.init on exit
└── components/
    ├── init/components/init_component.dart     # visible "sair" -> shutdownApp()
    └── editor/
        ├── editor_component.dart               # scrollbars, opaque panels,
        │                                       # overlay stack, Esc/sair onExit
        └── components/sidebar/sidebar_component.dart  # soft-wrap rows
```

**Structure Decision**: Edit existing files in place; no moves, no new
barrels. Graph layout/routing files are not modified.

## Complexity Tracking

No constitution violations; table not needed.
