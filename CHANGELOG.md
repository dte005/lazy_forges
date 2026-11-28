## 1.0.3

- Fix: navigating large schemas on the editor canvas (regression from 1.0.2,
  where the scrollbars were visual only and Ctrl+arrows were intercepted by
  some systems).
- Editor: clickable arrow buttons (▲ ▼ ◄ ►) on both scrollbars scroll the graph
  3 lines/columns per click; a scrollbar is hidden when the graph fits.
- Editor: hold the right mouse button and drag to pan the graph (depends on
  the terminal forwarding right-button drag events).
- Editor: PageUp/PageDown scroll vertically; Left/Right scroll horizontally
  while the command input is empty.
- Editor: Ctrl+arrows scrolling was removed; Help and README updated.

## 1.0.2

- Editor: vertical scrollbars on the sidebar and the graph canvas, plus a
  horizontal scroll indicator, so large schemas are easier to navigate.
- Editor: long sidebar entries now wrap instead of being cut off.
- Editor: Help and database-types panels are opaque, no longer show the graph
  through them, and can be open at the same time (Esc closes the latest one).
- Navigation: leaving the editor (`sair`, Esc or `q` on an empty input) returns
  to the main menu instead of closing the app.
- Main menu: visible quit control; `sair`, Esc and `q` close the app from there.
- Automated publishing to pub.dev via GitHub Actions on version tags.
- Added automated tests for the new editor and menu behavior.

## 1.0.1

- Fixes terminal corruption on exit (Ctrl+C, ESC, quit button):
  replaces `exit(0)` with nocterm's `shutdownApp()`.

## 1.0.0

- Initial version.
