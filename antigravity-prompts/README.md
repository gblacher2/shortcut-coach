# Antigravity Prompt Pack - Shortcut Coach

Use these prompts in separate Antigravity tasks to finish Shortcut Coach in parallel without burning Codex time on serial debugging.

## Project Context

Workspace: `/Users/gabrielblacher/Documents/Codex/shortcut-coach`

Goal: finish a small native macOS menu-bar app named **Shortcut Coach**. It should be on-demand only, live in the menu bar, and read shortcuts from:

`/Users/gabrielblacher/Documents/Codex/mac-shortcuts-guide/mac-shortcuts.json`

Important constraints:

- Do not edit Karabiner or macOS keyboard settings.
- Do not add notifications, background monitoring, or context-aware permission-heavy behavior.
- Keep the app menu-bar/accessory style.
- Preserve the existing folder split: `App`, `Views`, `Models`, `Stores`, `Services`, `Support`.
- Prefer the live JSON path, but keep a bundled fallback JSON working.

Current status:

- SwiftPM package exists.
- `swift build` passed after `ShortcutStore` was marked `@MainActor`.
- `swift test` failed because this Command Line Tools environment cannot import `XCTest`.
- The shortcut catalog currently has 55 shortcuts, including 10 Karabiner remaps.

## Recommended Parallel Split

1. `01-check-runner.md`: replace XCTest dependency with a lightweight local check runner.
2. `02-bundle-and-launch.md`: make the staged `.app` bundle robust, especially resource fallback.
3. `03-ui-qa-polish.md`: inspect and polish the menu-bar popover experience.
4. `04-install-convenience.md`: propose or implement a low-friction local install path, without auto-start unless explicitly approved.

Run task 1 and task 2 first. Task 3 can run after task 2 launches the app. Task 4 can run independently as a proposal or utility pass.
