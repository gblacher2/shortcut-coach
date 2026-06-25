# Prompt 01 - Add A Non-XCTest Check Runner

You are working in:

`/Users/gabrielblacher/Documents/Codex/shortcut-coach`

Build context:

- This is a SwiftPM macOS SwiftUI menu-bar app named `ShortcutCoach`.
- `swift build` has passed.
- `swift test` currently fails because this Command Line Tools environment has no `XCTest` module.
- Do not spend time trying to install XCTest or change Xcode selection unless you discover an obvious local fix.

Task:

Create a lightweight validation runner that performs the same assertions as `Tests/ShortcutCoachTests/ShortcutCoachTests.swift` without depending on XCTest.

Requirements:

- Add a SwiftPM executable target named `ShortcutCoachChecks`, or another simple package-local check entrypoint if SwiftPM makes that cleaner.
- Reuse production code where possible: `CatalogLoader`, `ShortcutFilters`, and the shortcut models.
- Validate:
  - catalog decodes successfully,
  - there are exactly 55 shortcuts,
  - there are exactly 10 `Karabiner` shortcuts,
  - searching `redo` with source `Karabiner` includes `Command + Y`,
  - filtering `Window Control` + `Daily` returns only matching active daily items,
  - Today’s 10 returns exactly 10 active priority-1 shortcuts and starts with a Karabiner item.
- Print a short success summary.
- Exit nonzero with a clear message if any assertion fails.

Acceptance:

- `swift build` succeeds.
- `swift run ShortcutCoachChecks` succeeds.
- Leave the existing XCTest file either removed or clearly superseded so future agents do not rerun a known-broken `swift test` path in this CLT-only environment.
- Do not change Karabiner, macOS settings, or the guide generator.
