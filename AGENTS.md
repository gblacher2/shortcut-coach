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
  `ShortcutCoachCore`. The build script stages both `*.bundle` directories in
  `Contents/Resources` so `Bundle.module` resolves correctly at runtime.
- **No permissions or monitoring.** Do not add Accessibility permission, global key
  monitors, foreground-app detection, or automatic shortcut-use tracking.
- **Personal state.** `UserLibraryManager` owns the atomic local JSON, one-time legacy
  migration, recovery copy, and personal-state-only import/export contract.
- **Bundle ID:** `com.gabrielblacher.ShortcutCoach` · **Min macOS:** 15.0
- **Unified runtime models.** `ShortcutCatalogEntry` decodes the immutable app catalog and also represents entries mapped from the separately decoded My Mac environment. Presentation fields that are absent from `mac-shortcuts.json` must remain backward-decodable (normally optional, or handled explicitly in a custom decoder) so existing catalog data continues to load.

## GitHub workflow and agent guardrails

- GitHub is the canonical system of record. Record durable decisions, acceptance
  criteria, implementation state, review findings, and validation in the repository,
  Issues, or pull requests rather than only in an AI conversation.
- Meaningful work uses an Issue or equivalent complete PR context, a scoped branch,
  an early draft PR, review comments, verification, and a final `READY FOR HUMAN` state.
- Use `feat/`, `fix/`, `refactor/`, or `chore/` branch prefixes. Do not implement normal
  feature work directly on `main` and do not merge without human authorization.
- Inspect the existing architecture and `git status` before changing files. Preserve
  unrelated local work and prefer minimal, scoped modifications.
- Do not suppress type or lint failures, replace working implementations unnecessarily,
  introduce dependencies without justification, or alter unrelated code.
- Never commit secrets, credentials, `.env` values, personal data, local databases,
  logs, or machine-specific state. Commit reconstruction-safe examples and setup docs.
- Push meaningful checkpoints and keep the PR accurate so a fresh agent can continue
  from GitHub alone.
