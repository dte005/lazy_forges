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
