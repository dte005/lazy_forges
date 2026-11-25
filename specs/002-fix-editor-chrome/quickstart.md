# Quickstart: Validate editor chrome fix

**Spec**: [spec.md](./spec.md) | **Contract**: [contracts/ui-contract.md](./contracts/ui-contract.md)

## Prerequisites
- `dart pub get`, `dart analyze` clean in the repo.
- Run the app ONLY from the workspace (never from the clone):

```bash
cd ../dbs_schema_lazyforges
dart --enable-vm-service ../lazy_forges/bin/lazy_forge.dart
```

## Scenarios
1. Open `schema_relacoes` (13 tables): Ctrl+arrows reach every table/line; scrollbars visible on overflowing axes (US1, SC-001).
2. Scroll sidebar top→bottom; long lines wrap, no horizontal scroll (US2, SC-002).
3. Open Help over graph, then BD types (also on a narrow terminal): both opaque, no bleed-through; Esc closes the most recently opened first (US3, SC-003/004/009).
4. Click **sair** in editor, then press Esc in editor: lands on init, process alive; reopen project shows last state (US4, SC-005/010).
5. In the editor with empty input, `q` also returns to init; typing `q` inside a command does not. On init, **sair**, Esc and `q` (browse) exit cleanly; `q` in the create-name input just types (SC-006).
6. Open a 2–3 table project: no regression (SC-007); lines still avoid table boxes (SC-008).
