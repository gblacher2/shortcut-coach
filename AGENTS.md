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
- **Resource bundles.** `mac-shortcuts.json` ships as a SwiftPM process resource inside
  `ShortcutCoachCore`. The build script copies both `*.bundle` directories into
  `Contents/` so `Bundle.module` resolves correctly at runtime.
- **Auto-tracking requires Accessibility permission.** The app polls for it via a 1.5s
  `Timer` on `RunLoop.main` and stops polling once granted.
- **Catalog override.** Set env var `SHORTCUTCOACH_CATALOG_OVERRIDE=<path>` to point
  the loader at a different JSON file (used by `--verify` fallback test).
- **Bundle ID:** `com.gabrielblacher.ShortcutCoach` · **Min macOS:** 15.0
