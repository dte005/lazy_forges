# UI Contract: canvas navigation

## Controls

| Input | Condition | Effect |
|-------|-----------|--------|
| Click `▲` / `▼` (vertical bar ends) | Always | Canvas moves up/down 3 lines, clamped |
| Click `◄` / `►` (horizontal bar ends) | Always | Canvas moves left/right 3 columns, clamped |
| Click on track or thumb | Always | No effect |
| Right button held + pointer move over canvas | Canvas overflows on the axis | Content follows the pointer on that axis |
| Right button released (anywhere) | Drag active | Drag ends no later than the next pointer event without the right button |
| `PageUp` / `PageDown` | Editor focused | Canvas moves one page vertically, clamped |
| `Left` / `Right` | Command input empty | Canvas moves 3 columns horizontally, clamped |
| `Left` / `Right` / `Home` / `End` | Command input not empty | Unchanged (text cursor) |
| `Up` / `Down` | Always | Unchanged (command history) |
| `Ctrl` + arrows | Always | No effect (removed) |

## Visual layout (geometry unchanged)

```text
┌ editor ───────────────────────────┬─┐
│ canvas                            │▲│
│                                   │▬│  vertical bar: ▲ top, ▼ bottom,
│                                   │░│  thumb between (same glyphs as horizontal)
│                                   │▼│
├───────────────────────────────────┴─┤
│ ◄▬▬▬░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░► │  horizontal bar (existing)
└─────────────────────────────────────┘
```

## Help text (Portuguese)

- `Navegar: PageUp/PageDown, setas esq/dir (input vazio)`
- `Mouse: setas nas barras, botao direito arrasta`
- The line `Scroll editor: Ctrl + setas` is removed.

## Overflow rule

Each scrollbar (arrows, track, thumb) is hidden while the content fits on its axis.

## Invariants

The five graphical layout rules stay intact; the command input still spans the full editor width; the sidebar scroll is unchanged.
