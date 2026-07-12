# Shortcut Coach

Private, native macOS shortcut library for Google Chrome, ChatGPT, Antigravity, Pages, Finder, Spotify, WhatsApp, Preview, and Apple Mail. A separate “My Mac” layer documents this Mac's verified macOS, Karabiner-Elements, Hammerspoon, and BetterStage shortcuts without changing the immutable nine-app catalog. The app combines a three-column library window with a fast MenuBarExtra, shared search, and local-only personal state.

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

The immutable, versioned app catalog lives in `Sources/ShortcutCoachCore/Resources/mac-shortcuts.json`. The separately versioned, local-only environment snapshot lives in `Sources/ShortcutCoachCore/Resources/my-mac-environment.json`. Verification evidence and intentional omissions live in `CATALOG-SOURCES.md`.

---

## Architecture Notes

- `ShortcutStore` (`@Observable @MainActor`) is the single source of truth.
- `ShortcutSearchService` powers both the full window and MenuBarExtra.
- `CatalogLoader` validates the optional My Mac overlay independently; missing or rejected environment data never makes the nine-app library unavailable.
- Personal state is stored atomically in `~/Library/Application Support/ShortcutCoach/UserLibraryState.json` with a recovery copy.
- One-time legacy migration backs up the exact old blobs first, maps only 27 exact shortcut-ID equivalents, and retains unmatched retired IDs verbatim for recovery rather than guessing or deleting them.
- The app requests no Accessibility permission and performs no foreground-app or key-use detection.
- Non-XCTest check runner (`ShortcutCoachChecks`) avoids the XCTest CLT limitation; add new assertions there.
- Bundle ID: `com.gabrielblacher.ShortcutCoach`
