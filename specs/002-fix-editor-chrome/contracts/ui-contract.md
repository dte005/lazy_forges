# UI Contract: Editor chrome and navigation

| Surface | Input | Result |
|---|---|---|
| Editor header | click/tap **sair** | `onExit()` → init screen; process alive |
| Editor | Esc, or `q` with empty input, no overlay open | same as **sair** |
| Editor | Esc, or `q` with empty input, overlays open | close most recently opened overlay only |
| Editor | Ctrl+arrows | scroll graph (unchanged) |
| Help / BD types | open | opaque solid background; both may be open; last opened on top |
| Graph / sidebar | content overflows | scrollbar visible on overflowing axis |
| Sidebar | long line | soft-wraps; vertical scroll only |
| Init (browse) | **sair** control, Esc, `q` | `shutdownApp()` |
| Init (create/pick DB) | `q` | typed as text / ignored (never quits) |
| Init (create/pick DB) | Esc | existing cancel behavior (unchanged) |

User strings stay Portuguese; no stack traces.
