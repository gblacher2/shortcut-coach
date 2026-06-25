# Prompt 02 - Fix Bundle, Fallback Resources, And Launch Verification

You are working in:

`/Users/gabrielblacher/Documents/Codex/shortcut-coach`

Build context:

- `script/build_and_run.sh` stages `dist/ShortcutCoach.app` and launches with `/usr/bin/open -n`.
- The app prefers the live JSON file at `/Users/gabrielblacher/Documents/Codex/mac-shortcuts-guide/mac-shortcuts.json`.
- It also has `Sources/ShortcutCoach/Resources/mac-shortcuts.json` as a bundled fallback.
- Current script copies the compiled binary into the `.app`, but may not copy SwiftPM resource bundles into a location where `Bundle.module` can find them from the staged app.

Task:

Make the staged app bundle robust and verify launch.

Requirements:

- Inspect SwiftPM’s built output for resource bundle placement.
- Update `script/build_and_run.sh` so `dist/ShortcutCoach.app` includes any required SwiftPM resource bundle(s) for `Bundle.module`.
- Keep the app accessory/menu-bar style with `LSUIElement=true`.
- Keep modes: `run`, `--debug`, `--logs`, `--telemetry`, `--verify`.
- `--verify` should:
  - build,
  - stage the app,
  - launch it,
  - confirm the `ShortcutCoach` process exists,
  - print a short confirmation.
- If possible, temporarily simulate the live JSON being unavailable without renaming or deleting the real guide file, and confirm the bundled fallback still loads.

Acceptance:

- `./script/build_and_run.sh --verify` succeeds.
- `dist/ShortcutCoach.app` exists and has a valid `Contents/Info.plist`.
- The app can launch as a menu-bar-only app.
- No Karabiner or macOS keyboard settings are changed.
