# Shortcut Coach

Private, native macOS shortcut library for Google Chrome, ChatGPT, Antigravity, Pages, Finder, Spotify, WhatsApp, Preview, and Apple Mail. It combines a three-column library window with a fast MenuBarExtra, shared search, and local-only personal state.

**Requirements:** macOS 15+ (Sequoia) · Swift 6.1 · SwiftPM · Command Line Tools (no full Xcode needed)

---

## Build & Run

```bash
# Build, assemble .app bundle (with ad-hoc codesign), and launch
./script/build_and_run.sh

# Full post-change verification (build + bundle checks + launch + process check)
./script/build_and_run.sh --verify

# Run the non-XCTest check suite (catalog, search, persistence, migration, backup)
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

The immutable, versioned catalog lives in `Sources/ShortcutCoachCore/Resources/mac-shortcuts.json`. Verification evidence and intentional omissions live in `CATALOG-SOURCES.md`.

---

## Architecture Notes

- `ShortcutStore` (`@Observable @MainActor`) is the single source of truth.
- `ShortcutSearchService` powers both the full window and MenuBarExtra.
- Personal state is stored atomically in `~/Library/Application Support/ShortcutCoach/UserLibraryState.json` with a recovery copy.
- The app requests no Accessibility permission and performs no foreground-app or key-use detection.
- Non-XCTest check runner (`ShortcutCoachChecks`) avoids the XCTest CLT limitation; add new assertions there.
- Bundle ID: `com.gabrielblacher.ShortcutCoach`
