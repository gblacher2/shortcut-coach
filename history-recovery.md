# mac-shortcuts-guide — history recovery

## 1. Sessions found
- **2026-06-24T02:38:52Z**: Prompt 01 - Add A Non-XCTest Check Runner (shortcut-coach session mentioning Karabiner shortcut rules and source)
- **2026-06-24T02:39:37Z**: Prompt 02 - Fix Bundle, Fallback Resources, And Launch Verification (shortcut-coach session mentioning the live JSON and bundled fallback)
- **2026-06-24T02:40:03Z**: Prompt 03 - Menu-Bar UI QA And Polish (shortcut-coach session mentioning the full HTML guide path)
- **2026-06-24T15:01:51Z**: Shortcut Coach issue: Menu-bar progress label (shortcut-coach session mentioning the catalog source path and constraints)
- **2026-06-25T02:19:50Z**: Shortcut Coach issue: keys not registering, accessibility prompt, margins (shortcut-coach session mentioning Karabiner settings and the "full guide")

## 2. My original requests (verbatim)
none found (The original sessions that created `mac-shortcuts-guide` and its Python generator scripts are not present in the accessible log history.)

*Note: Below are the verbatim requests from the `shortcut-coach` sessions where the guide/generator files were mentioned as a dependency:*
- **2026-06-24T02:38:52Z**: "...there are exactly 10 `Karabiner` shortcuts, searching `redo` with source `Karabiner` includes `Command + Y`... Do not change Karabiner, macOS settings, or the guide generator."
- **2026-06-24T02:39:37Z**: "The app prefers the live JSON file at `/Users/gabrielblacher/Documents/Codex/mac-shortcuts-guide/mac-shortcuts.json`... If possible, temporarily simulate the live JSON being unavailable without renaming or deleting the real guide file, and confirm the bundled fallback still loads."
- **2026-06-24T02:40:03Z**: "`Full Guide` opens `/Users/gabrielblacher/Documents/Codex/mac-shortcuts-guide/mac-shortcuts.html`."
- **2026-06-24T15:01:51Z**: "Catalog source: `/Users/gabrielblacher/Documents/Codex/mac-shortcuts-guide/mac-shortcuts.json`... Preserve the existing JSON catalog and fallback behavior."
- **2026-06-25T02:33:34Z**: "also, only show in the menu bar shortcuts that are confirmed in my settings (mac + karabiner) - native mac ones should only appear on the \"full guide\""

## 3. Design decisions & rationale
none found

## 4. Requested but never implemented
none found

## 5. Known issues / TODOs mentioned
- **JSON File Path Dependency:** The `shortcut-coach` app hardcodes the `mac-shortcuts-guide` paths to `/Users/gabrielblacher/Documents/Codex/mac-shortcuts-guide/`. Since the project was recently moved to `~/Projects/mac-shortcuts-guide`, the app will fail to find the live JSON file and the HTML guide.
- **Fallback Limitations:** If the live JSON file (`mac-shortcuts.json`) is not found, `shortcut-coach` gracefully falls back to a static catalog bundled in the app binary. Any local updates made to the live JSON catalog afterwards will not reflect unless the live file is restored to the expected path or manually refreshed when accessible.

## 6. Build environment
none found

## 7. Anything else load-bearing
- **Read-Only Constraint:** The downstream `shortcut-coach` app treats the guide generator and its output files as strictly read-only. Multiple sessions emphasized: *"Do not change Karabiner, macOS settings, or the guide generator"* and *"Preserve the existing JSON catalog and fallback behavior"*.
- **Location Hardcoding:** The location of the output files (`mac-shortcuts.json` and `mac-shortcuts.html`) is load-bearing for the `shortcut-coach` app to function in live mode. A future maintainer should update `ShortcutCoach` to reflect the new directory path (`~/Projects/mac-shortcuts-guide`).
