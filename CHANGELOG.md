## 1.0.1

- Fixes terminal corruption on exit (Ctrl+C, ESC, quit button):
  replaces `exit(0)` with nocterm's `shutdownApp()`.

## 1.0.0

- Initial version.
