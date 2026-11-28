# Quickstart: validate canvas navigation

Never run the app from the repository clone. Use the schema workspace.

## Setup

```bash
# in the repository
dart pub get
dart analyze

# run the TUI from the schema workspace
cd ../dbs_schema_lazyforges
dart --enable-vm-service ../lazy_forges/bin/lazy_forge.dart
```

Open a project larger than the window (for example `schema_relacoes`).

## Scenarios

1. **Arrows**: click `▼`, `▲`, `►`, `◄`; each click moves 3 lines/columns and stops at edges (spec US1, FR-001/002/007).
2. **Track**: click between the arrows; nothing happens (FR-004).
3. **Right-button drag**: hold the right button and drag in all directions; the content follows the pointer; release inside and outside the canvas; further movement leaves the canvas still (US2, FR-005/006). If the terminal does not forward the drag, record the terminal name.
4. **Keyboard**: with an empty input press `PageUp`/`PageDown` (one page vertically) and `Left`/`Right` (3 columns); type text and confirm `Left`/`Right` move the cursor and `Up`/`Down` still browse history (US3, FR-013).
5. **Removal**: press `Ctrl`+arrows; the canvas does not move; Help no longer mentions them (US4, FR-008).
6. **No regression**: scroll the sidebar; verify the five layout rules.

## Tests (only if the maintainer asks)

```bash
dart test tests
```

Use `testNocterm` with a temp dir and `IOOverrides.runZoned` (see test rules in `.github/copilot-instructions.md`).
