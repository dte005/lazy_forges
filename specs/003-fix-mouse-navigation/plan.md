# Implementation Plan: Fix navigation of the editor canvas (mouse and keyboard)

**Branch**: `003-fix-mouse-navigation` | **Date**: 2026-11-28 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/003-fix-mouse-navigation/spec.md`

## Summary

The editor canvas cannot be navigated reliably on large schemas: Ctrl+arrows
are intercepted on some systems, the wheel is consumed by the inner
horizontal scroll, and the scrollbars are visual only. The change replaces
Ctrl+arrows with controls that work on any terminal: clickable arrow buttons
on both scrollbars (the vertical bar becomes a custom component), right-button
drag panning (content follows the pointer), and unmodified keyboard keys
(PageUp/PageDown vertical; Left/Right horizontal while the input is empty).
All changes are UI-only inside `editor_component.dart` using nocterm
primitives already available in 0.8.0.

## Technical Context

**Language/Version**: Dart (SDK ^3.11.4)

**Primary Dependencies**: `nocterm` 0.8.0 only (no new dependencies)

**Storage**: N/A (scroll offsets are in-memory controllers)

**Testing**: `dart test tests` (only if the maintainer asks); manual validation in `../dbs_schema_lazyforges`

**Target Platform**: Any terminal with basic mouse reporting (macOS, Linux, Windows)

**Project Type**: CLI/TUI application

**Performance Goals**: Scroll updates render on the next frame; no extra layout passes beyond the existing indicator rebuild

**Constraints**: nocterm-only; do not change the five graphical layout rules; Portuguese UI strings; English comments; modified PageUp/PageDown are not parsed by nocterm 0.8.0, so no modifier-key shortcuts

**Scale/Scope**: One source file (`lib/src/components/editor/editor_component.dart`) plus `README.md`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Interface in service of decisions | PASS | Arrows and thumb communicate scroll position and affordance; no decoration |
| II. Commands that speak SQL | PASS (N/A) | No command grammar change |
| III. Portable output | PASS (N/A) | No file or DDL change |
| IV. Terminal end to end (keyboard primary) | PASS | Keyboard path kept: PageUp/PageDown and Left/Right (empty input); mouse is additional |
| V. Perceived speed | PASS | Only `jumpTo`/`scrollBy` on existing controllers |
| VI. Trust from the first command | PASS | Help text updated to match real behavior |
| VII. Deliberate simplicity | PASS | One new vertical indicator mirroring the existing horizontal one; no new abstractions |
| VIII. Stability of what ships | PASS (declared change) | Ctrl+arrows removal is declared and justified in spec FR-008; sidebar and layout rules untouched; commands and files unchanged |

**Post-design re-check**: PASS (see Phase 1 artifacts). No violations.

## Project Structure

### Documentation (this feature)

```text
specs/003-fix-mouse-navigation/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── ui-contract.md
└── tasks.md             # created by /speckit-tasks
```

### Source Code (repository root)

```text
lib/src/components/editor/
└── editor_component.dart   # key handler, Help text, canvas build,
                            # _HorizontalScrollIndicator, new vertical indicator,
                            # right-button pan region
README.md                   # navigation section update
tests/                      # only if the maintainer asks (test-manager-executer)
```

**Structure Decision**: Keep everything in `editor_component.dart`, next to the existing `_HorizontalScrollIndicator`. No new files and no barrels.

## Complexity Tracking

No constitution violations to justify.
