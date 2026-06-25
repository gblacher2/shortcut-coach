# Prompt 03 - Menu-Bar UI QA And Polish

You are working in:

`/Users/gabrielblacher/Documents/Codex/shortcut-coach`

Product intent:

Shortcut Coach should feel easier than a PDF or JSON file. It is a calm, on-demand menu-bar coach for mastering Mac multitasking shortcuts.

Task:

Run the app and polish the menu-bar popover UI for daily use.

QA checklist:

- Menu-bar icon appears and opens the popover.
- Popover has three clear sections: `Today`, `Search`, `Practice`.
- Today view shows 10 daily shortcuts, ranked 1-10.
- Search view supports text search plus context/source/priority filters.
- Practice view reveals/hides answers without visual jumpiness.
- `Refresh` reloads the catalog.
- `Full Guide` opens `/Users/gabrielblacher/Documents/Codex/mac-shortcuts-guide/mac-shortcuts.html`.
- `Quit` exits the app.

Polish constraints:

- Do not add notifications or background reminders.
- Do not add a Dock window.
- Keep labels plain-language and short.
- Keep controls compact enough for a menu-bar popover.
- Use system-adaptive colors/materials; avoid hardcoded white backgrounds.
- If a label gets long, truncate or move detail into secondary text.

Acceptance:

- Build succeeds after any UI changes.
- Launch succeeds via `./script/build_and_run.sh --verify`.
- Provide a brief QA note with what was checked and any residual limitations.
