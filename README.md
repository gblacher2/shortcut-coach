# Shortcut Coach

Native macOS SwiftUI menu-bar app that coaches you through learning keyboard shortcuts. Shows a daily set of priority-1 shortcuts, lets you mark them practiced, optionally auto-detects usage via Accessibility API, and provides a searchable catalog filtered by context/source/priority.

**Requirements:** macOS 15+ (Sequoia) · Swift 6.1 · SwiftPM · Command Line Tools (no full Xcode needed)

---

## Build & Run

```bash
# Build, assemble .app bundle (with ad-hoc codesign), and launch
./script/build_and_run.sh

# Full post-change verification (build + bundle checks + launch + process check)
./script/build_and_run.sh --verify

# Run the non-XCTest check suite (validates catalog loading, filters, daily set)
swift run ShortcutCoachChecks

# Other modes
./script/build_and_run.sh --debug    # launch under lldb
./script/build_and_run.sh --logs     # stream os_log output
```

> **IMPORTANT:** `swift test` silently no-ops on this machine (Command Line Tools only — no XCTest runner). Use `swift run ShortcutCoachChecks` for logic checks and `./script/build_and_run.sh --verify` for full end-to-end verification.

---

## Project Structure

```
Sources/
  ShortcutCoachCore/        # library — models, catalog loader, filters, JSON resource
  ShortcutCoach/            # app executable — SwiftUI menu-bar app
  ShortcutCoachChecks/      # lightweight non-XCTest check runner
script/build_and_run.sh
script/install_local_app.sh
```

Shortcut data lives in `Sources/ShortcutCoachCore/Resources/mac-shortcuts.json`. Swap or extend it to change the catalog.

---

## Architecture Notes

- `ShortcutStore` (`@Observable @MainActor`) is the single source of truth.
- Auto-tracking uses `NSEvent.addGlobalMonitorForEvents` — requires Accessibility permission.
- Non-XCTest check runner (`ShortcutCoachChecks`) avoids the XCTest CLT limitation; add new assertions there.
- Bundle ID: `com.gabrielblacher.ShortcutCoach`
