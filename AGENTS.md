# Shortcut Coach — Build / Run / Test

## Build / Run / Test

```bash
# Compile check only
swift build

# Build, assemble .app bundle (ad-hoc codesign), and launch
./script/build_and_run.sh

# Full post-change verification (bundle integrity + launch + process check)
./script/build_and_run.sh --verify

# Logic / unit checks (non-XCTest runner — run this for any logic change)
swift run ShortcutCoachChecks

# Stream os_log output while running
./script/build_and_run.sh --logs
```

**Do NOT run `swift test`.** On this machine (Command Line Tools only, no full Xcode),
`swift test` silently exits 0 without running any tests. The XCTest target was removed
for exactly this reason. Add new assertions to `Sources/ShortcutCoachChecks/main.swift`
instead, then run `swift run ShortcutCoachChecks`.

---

## Conventions / Gotchas

- **CLT-only build environment.** No Xcode.app. SwiftPM only. XCTest runner unavailable.
- **Swift 6.1 strict concurrency.** All shared state on `@MainActor`. `nonisolated(unsafe)`
  vars must have an isolation comment explaining why there is no race.
- **No XCTest target.** Tests live in `Sources/ShortcutCoachChecks/main.swift` as plain
  assertions that exit non-zero on failure. Keep that file updated with every behavioral change.
- **Codesign is ad-hoc** (`--sign -`). The build script codesigns before staging the bundle
  so macOS gatekeeper does not block launch.
- **Resource bundles.** The immutable `mac-shortcuts.json` catalog ships inside
  `ShortcutCoachCore`. The build script copies both `*.bundle` directories into
  `Contents/` so `Bundle.module` resolves correctly at runtime.
- **No permissions or monitoring.** Do not add Accessibility permission, global key
  monitors, foreground-app detection, or automatic shortcut-use tracking.
- **Personal state.** `UserLibraryManager` owns the atomic local JSON, one-time legacy
  migration, recovery copy, and personal-state-only import/export contract.
- **Bundle ID:** `com.gabrielblacher.ShortcutCoach` · **Min macOS:** 15.0
