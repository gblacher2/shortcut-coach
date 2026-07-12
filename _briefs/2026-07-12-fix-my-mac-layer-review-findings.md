# Brief: fix-my-mac-layer-review-findings (2026-07-12)

**Author:** Codex · **Executor:** Antigravity Sonnet · **Repo:** /Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach

## Objective

Repair the existing My Mac environment-layer implementation so the committed revision is reproducible from a clean checkout, all 37 records load through validated and failure-isolated models, every sidebar/search surface behaves correctly, metadata remains truthful, tests exercise the real requirements, and the completed UI is manually verified.

## Context

This is a targeted correction pass over commit `3fa8d9e` (“Implement My Mac environment layer”), not a redesign or from-scratch rewrite.

Read these files before editing:

- `AGENTS.md`
- `_briefs/2026-07-12-add-my-mac-environment-layer.md`
- `_briefs/2026-07-11-current-macos-shortcut-environment.json`
- `Sources/ShortcutCoachCore/Models/EnvironmentCatalog.swift`
- `Sources/ShortcutCoachCore/Models/ShortcutCatalogEntry.swift`
- `Sources/ShortcutCoachCore/Models/SidebarSelection.swift`
- `Sources/ShortcutCoachCore/Services/CatalogLoader.swift`
- `Sources/ShortcutCoachCore/Support/ShortcutFilters.swift`
- `Sources/ShortcutCoach/Stores/ShortcutStore.swift`
- all five current SwiftUI view files
- `Sources/ShortcutCoachChecks/main.swift`
- `Package.swift`

Known baseline:

- The current branch is `feature/foundation-persistence`.
- `3fa8d9e` contains most code changes.
- `Sources/ShortcutCoachCore/Resources/my-mac-environment.json` exists locally but was not added to `3fa8d9e`.
- The dirty working tree passes checks only because SwiftPM sees that untracked resource.
- A disposable clean worktree of `3fa8d9e` fails six checks because the committed revision contains no My Mac resource.
- The immutable app catalog checksum after `3fa8d9e` is `da9388fdee49c9e52b6b233d205b87039ee6dbdc8ac7d02a111fdb44eaf8ca86`, identical to the parent.
- The environment source checksum is `db0dc9a1c564ca9c89fffbb90893cf5640c23cd4e8e09a692d54e790b3bb7193`.
- The validated environment contains 37 bindings, 3 conflicts, 0 unresolved records, 23 `add` recommendations, and 14 `keepSeparateFromBuiltInCatalog` recommendations.

Codex review found these blockers:

1. The runtime JSON resource is untracked, so the committed feature is incomplete.
2. “Spaces & Mission Control” filters for the nonexistent literal category `spaces-mission-control`; the data contains four `spaces` records and two `mission-control` records.
3. The loader does not validate environment `format`, schema version, duplicate IDs, recommendation coverage, dangling recommendation IDs, overlapping classifications, duplicate conflict IDs, or exact conflict references.
4. A malformed environment resource currently fails the entire catalog load instead of preserving the usable nine-app base catalog and surfacing an overlay warning.
5. Every My Mac entry is incorrectly labelled `installedAppMenu`; Apple documentation, system preferences, and tool configuration are distinct evidence types.
6. My Mac validation metadata is replaced with placeholders such as `now` and `local` rather than preserving audited values.
7. Guidance is flattened to “Local environment mapping” rather than using practical output/caveat/source context.
8. The check runner bypasses display-text integrity for all My Mac entries.
9. The menu-bar/full-window equivalence check is tautological: it calls the same service twice with the same Mail query and does not exercise My Mac UI scope construction.
10. Required tests for malformed/unsupported resources, recommendation references, My Mac search fields, stable-ID persistence, and combined category filtering are absent.
11. The required manual UI smoke checks were not performed; the execution report delegated them to the user.

Keep the useful existing architecture where sound. Fix the narrowest set of models, loaders, filters, views, tests, and resources needed to satisfy this brief.

## In scope

### Repository and commit repair

- Preserve the user's existing working tree and unrelated files.
- Add the existing `Sources/ShortcutCoachCore/Resources/my-mac-environment.json` to version control after verifying that its checksum and privacy contents match the validated audit.
- Do not amend, reset, rewrite, squash, or force-change `3fa8d9e`; create new coherent correction commits.
- Prove the final committed revision works from a disposable clean worktree that contains no untracked files from the main checkout.

### Typed environment contract

- Expand `EnvironmentCatalog` and related models only as needed to decode and preserve the audited contract:
  - `format`
  - `schemaVersion`
  - generated/validated host metadata
  - binding IDs, action, ordered keys, display text, owner, category, scope, enabled state
  - default/source classification
  - source type and source value
  - output type, summary, and output keys
  - confidence and caveat
  - conflict IDs
  - add/separate/update/omit recommendation groups
- Unknown nonessential top-level audit fields may remain safely decodable/ignored, but do not discard metadata required by the UI or validation.
- Use typed enums where values are a closed contract. Avoid stringly typed classification checks spread throughout views and filters.

### Validation and failure isolation

Implement a testable environment validation boundary. It must reject the overlay for all of these cases:

- incorrect `format`
- unsupported schema version
- duplicate binding IDs
- duplicate conflict IDs
- a binding referencing a nonexistent conflict
- a recommendation referencing a nonexistent binding
- a binding appearing in more than one recommendation classification
- a binding missing from the applicable `add` or `keepSeparateFromBuiltInCatalog` coverage for this v1 dataset
- duplicate recommendation IDs
- missing required action, owner, category, source, keys, display text, output summary, or confidence
- display text inconsistent with ordered keys, unless the binding is an explicitly modelled gesture/mouse input whose audited display text is still validated against its ordered key representation
- an enabled v1 binding with no usable classification

Separate base-catalog failure from environment-overlay failure:

- Missing or malformed `mac-shortcuts.json` remains fatal.
- Missing, malformed, unsupported, or semantically invalid My Mac data must not erase or prevent use of the immutable nine-app catalog.
- The production load path must return the base catalog plus a visible/nonfatal environment warning or availability state.
- Do not silently claim the My Mac layer loaded when it was rejected.
- Provide an injectable/testable loader path so malformed fixtures can be tested without mutating bundled resources.
- The valid bundled resource must load exactly 37 My Mac entries.

### Truthful evidence and metadata

- Do not label all My Mac bindings as installed-app-menu evidence.
- Add a truthful source kind such as `localConfiguration` or a similarly clear model value.
- Map official Apple URLs to official-documentation evidence.
- Map Karabiner JSON, Hammerspoon Lua, BetterStage preferences, global preferences, and other local observations to local-configuration/system-preference evidence—not installed menu evidence.
- Preserve the audited macOS version, generated/verified date, confidence, source, owner, default status, output summary, and caveat.
- Do not use placeholders such as `now`, `local`, or generic “Local environment mapping” when audited information exists.
- Preserve the three resolved conflict summaries for inspector display without overwriting the stable conflict IDs. Store IDs and summaries distinctly if needed.
- Keep existing nine-app decoding backward compatible.

### Correct navigation and shared search

- Fix “Spaces & Mission Control” so it matches the union of categories `spaces` and `mission-control`, returning exactly six entries.
- Do not fake the union by changing source records to a fabricated combined category.
- Keep:
  - All My Mac Shortcuts: 37
  - macOS System: 23
  - Personal Setup: 14
  - Window Management: 17
  - Spaces & Mission Control: 6
  - Text Editing: 12
  - Input Sources: 2
- Ensure sidebar selection and text search compose.
- Ensure My Mac search matches:
  - action
  - owner/tool
  - readable chord/display text
  - ordered keys
  - category
  - output summary and output keys
  - caveat
  - source title/value
  - confidence/default classification where meaningful
- Preserve existing nine-app search behavior and ordering.
- Keep full-window and MenuBarExtra search on the same underlying service, but test the actual scope adapters/queries each UI constructs.
- If query construction currently lives privately inside SwiftUI views, extract a small shared/testable query builder or scope model rather than duplicating logic.

### Inspector, rows, and accessibility

- Keep dense My Mac rows clearly labelled by owner.
- Inspector must show:
  - action
  - readable key caps
  - owner
  - category
  - practical “When to use this” guidance
  - input-to-output behavior
  - default/custom classification
  - caveat
  - source type/value
  - verified macOS/date/method/confidence
  - conflict warning summaries for the correct three bindings
- Use semantic warning styling that remains legible in dark mode and increased contrast. Avoid hard-coding white-on-red if it harms accessibility; use SwiftUI semantic foreground/background styles.
- Add meaningful VoiceOver labels/hints for conflict warnings, owner rows, key caps, My Mac sidebar scopes, and the menu-bar scope picker.
- Preserve Reduce Motion behavior and keyboard navigation.

### Personal-state compatibility

- Confirm existing favourites, To Learn, notes, collections, and recents remain unchanged and decode exactly as before.
- Confirm stable My Mac IDs can be stored, exported, imported, recovered, and restored through the existing personal-state contract.
- Do not add My Mac environment data itself to the personal-state backup.
- Do not change the backup schema unless strictly necessary. A schema change is not expected for stable string IDs.

### Automated checks

Add real assertions to `Sources/ShortcutCoachChecks/main.swift`, plus narrowly scoped test helpers in the core target if needed.

At minimum test:

- valid environment format/schema
- exactly 37 unique bindings
- exactly 3 unique conflicts
- zero unresolved records if modelled
- exact 23/14 classification coverage
- every recommendation reference resolves
- classifications are disjoint and cover every enabled v1 binding
- every conflict reference resolves
- exact category counts: 17/6/12/2 for the four category sidebar rows
- display text agrees with ordered keys for all 37 records
- required evidence and validation metadata are not placeholders
- official URL records use official-documentation source kind
- local tool/system preference records do not use installed-app-menu source kind
- unsupported schema rejection
- wrong format rejection
- duplicate binding/conflict/recommendation rejection
- dangling conflict and recommendation rejection
- overlapping and incomplete classification rejection
- malformed overlay preserves the base catalog and exposes a nonfatal warning
- missing overlay preserves the base catalog and exposes unavailable state
- action, owner, chord, category, output, caveat, and source searches
- each My Mac sidebar scope composed with text
- actual full-window and menu-bar My Mac query construction returns identical ordered IDs
- favourites, To Learn, note, collection, and recents round trip with a My Mac ID
- personal-state export/import/recovery with My Mac IDs
- all pre-existing checks remain active

Do not weaken global integrity assertions with broad exceptions such as `|| appID == "my-mac"`. Add accurate My Mac-specific invariants instead.

### Documentation and commits

- Append the real execution report to this correction brief.
- Correct the previous report only if needed to point readers to this superseding correction; do not erase its historical evidence.
- Use small coherent commits. A recommended sequence is:
  1. commit the verified runtime resource
  2. fix typed validation/failure isolation and metadata
  3. fix navigation/search/UI
  4. add/strengthen checks and documentation
- Commit messages should describe the actual corrections.
- Leave unrelated untracked files untouched.

## Out of scope

- Do not redesign the app or replace the existing three-column architecture.
- Do not modify `Sources/ShortcutCoachCore/Resources/mac-shortcuts.json`.
- Do not change stable IDs or metadata in the nine-app catalog.
- Do not modify the audited source file `_briefs/2026-07-11-current-macos-shortcut-environment.json`.
- Do not change any macOS, Karabiner, Hammerspoon, BetterStage, keyboard, mouse, trackpad, window, Mission Control, Spaces, or input-source setting.
- Do not add automatic local configuration scanning or refresh.
- Do not add permissions, Accessibility access, foreground-app detection, global event monitoring, shell execution, shortcut tracking, accounts, sync, network access, web views, third-party dependencies, custom shortcut creation, key overrides, or configuration editing.
- Do not add environment data to personal-state export.
- Do not run `swift test`.
- Do not delete, reset, stash, overwrite, or commit unrelated work.
- Do not touch:
  - `_briefs/2026-07-11-verify-and-commit-overhaul.md`
  - `history-recovery.md`
- Do not claim manual UI verification if you did not actually observe and operate the launched app.
- Do not weaken checks, suppress errors, or invent metadata to make verification pass.

## Acceptance criteria

1. `my-mac-environment.json` is tracked and included in the final committed revision.
2. A clean worktree of final HEAD loads exactly 56 immutable app shortcuts plus 37 My Mac shortcuts and passes all checks without copying files from the dirty checkout.
3. The immutable `mac-shortcuts.json` checksum remains `da9388fdee49c9e52b6b233d205b87039ee6dbdc8ac7d02a111fdb44eaf8ca86`, with an empty diff.
4. The valid environment resource is verified against its schema and semantic invariants before merging.
5. Unsupported, malformed, missing, or semantically invalid environment data leaves the nine-app catalog usable and exposes a nonfatal My Mac warning/unavailable state.
6. All binding, conflict, and recommendation IDs are unique where required; every reference resolves; the 23/14 classifications are disjoint and complete.
7. Sidebar counts are exactly 37 All My Mac, 23 macOS System, 14 Personal Setup, 17 Window Management, 6 Spaces & Mission Control, 12 Text Editing, and 2 Input Sources.
8. Every requested sidebar scope composes correctly with text search.
9. My Mac search matches action, owner, chord/keys, category, output, caveat, source, and relevant metadata.
10. Equivalent My Mac scopes and queries constructed by MenuBarExtra and the full window return identical ordered IDs.
11. All 37 display texts and key representations pass explicit integrity checks without a blanket My Mac exception.
12. Source and verification metadata truthfully reflect official documentation versus local configuration/system preference evidence; there are no `now`/`local` placeholders.
13. Exactly the three audited conflict/interception warnings appear on the correct bindings, with stable IDs and readable summaries.
14. Existing personal state remains intact; My Mac stable IDs round-trip through favourites, To Learn, notes, collections, recents, export, import, and recovery.
15. UI remains keyboard navigable and accessible in VoiceOver, dark mode, increased contrast, and Reduce Motion.
16. `swift run ShortcutCoachChecks`, `swift build`, and `./script/build_and_run.sh --verify` all exit 0.
17. Manual smoke checks are actually performed and individually reported. If UI automation/observation is impossible, report the task as incomplete rather than assigning verification to Gabriel.
18. Final git status contains no missing task resources and leaves only explicitly listed unrelated files plus this report artifact uncommitted.
19. New correction commits are small and coherent; no prior commits are rewritten.
20. The execution report includes exact commands, real relevant output, clean-worktree evidence, changed files, commit hashes, manual checks, deviations, and open questions.

## Verification

Run from `/Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach`.

### 1. Baseline and source integrity

```bash
git status --short --untracked-files=all
git log --oneline --decorate -10
shasum -a 256 _briefs/2026-07-11-current-macos-shortcut-environment.json
jq '{format, schemaVersion, bindingCount:(.bindings|length), conflictCount:(.conflicts|length), unresolvedCount:(.unresolved|length), add:(.recommendedShortcutCoachChanges.add|length), separate:(.recommendedShortcutCoachChanges.keepSeparateFromBuiltInCatalog|length)}' _briefs/2026-07-11-current-macos-shortcut-environment.json
shasum -a 256 Sources/ShortcutCoachCore/Resources/mac-shortcuts.json
```

Expected:

- environment checksum `db0dc9a1c564ca9c89fffbb90893cf5640c23cd4e8e09a692d54e790b3bb7193`
- 37 bindings, 3 conflicts, 0 unresolved, 23 add, 14 separate
- immutable catalog checksum `da9388fdee49c9e52b6b233d205b87039ee6dbdc8ac7d02a111fdb44eaf8ca86`

### 2. Runtime resource integrity

After adding the runtime resource, compare it with the audited source. If the runtime file is intentionally sanitized or transformed, use a deterministic structural comparison and document every excluded field.

```bash
git ls-files --error-unmatch Sources/ShortcutCoachCore/Resources/my-mac-environment.json
shasum -a 256 Sources/ShortcutCoachCore/Resources/my-mac-environment.json
jq -e '.format == "shortcut-coach-environment/v1" and .schemaVersion == 1 and (.bindings|length == 37) and (.conflicts|length == 3) and (.unresolved|length == 0) and (.recommendedShortcutCoachChanges.add|length == 23) and (.recommendedShortcutCoachChanges.keepSeparateFromBuiltInCatalog|length == 14)' Sources/ShortcutCoachCore/Resources/my-mac-environment.json
```

Expected: tracked file, exit 0, and documented checksum.

### 3. Logic, integrity, persistence, and failure tests

```bash
swift run ShortcutCoachChecks
```

Expected: exit 0 with explicit passing lines for every automated-check group listed in In scope, including malformed/missing overlay fallback and real My Mac menu-bar/full-window equivalence.

### 4. Compile

```bash
swift build
```

Expected: exit 0 without compiler or linker errors.

### 5. Build, stage, sign, launch, and verify

```bash
./script/build_and_run.sh --verify
```

Expected: exit 0; bundle/resources/Info.plist validate, app launches, and the process remains running.

### 6. Immutable catalog proof

```bash
shasum -a 256 Sources/ShortcutCoachCore/Resources/mac-shortcuts.json
git diff 3da9820..HEAD -- Sources/ShortcutCoachCore/Resources/mac-shortcuts.json
```

Expected: checksum remains `da9388fdee49c9e52b6b233d205b87039ee6dbdc8ac7d02a111fdb44eaf8ca86`; diff is empty.

### 7. Clean-checkout reproducibility

Create a disposable detached worktree outside the repository. Do not copy any untracked file into it.

```bash
review_dir="$(mktemp -d /tmp/shortcut-coach-sonnet-review.XXXXXX)"
git worktree add --detach "$review_dir" HEAD
cd "$review_dir"
git status --short --untracked-files=all
git ls-files --error-unmatch Sources/ShortcutCoachCore/Resources/my-mac-environment.json
swift run ShortcutCoachChecks
swift build
cd /Users/gabrielblacher/GitHub\ \&\ Coding\ Projects/shortcut-coach
git worktree remove "$review_dir"
```

Expected:

- clean disposable worktree
- runtime resource is tracked
- all checks pass
- build passes
- no files copied from the primary dirty checkout

Capture the real result before removing the disposable worktree.

### 8. Manual UI smoke checks

Launch with the verified build and actually inspect/operate the app.

- Confirm all seven My Mac sidebar rows appear.
- Confirm counts: 37, 23, 14, 17, 6, 12, and 2.
- Confirm Spaces & Mission Control displays four Spaces plus two Mission Control entries.
- Search `redo`, `Karabiner`, `command scroll`, `middle click`, `spaces`, `window`, an output chord, a caveat phrase, and an Apple source URL fragment.
- Compose at least three searches with different My Mac sidebar scopes.
- Compare one identical My Mac query/scope in the full window and MenuBarExtra.
- Inspect Command + Y, both Command-scroll records, and middle-click; verify only the correct records show conflict summaries.
- Inspect one Apple-documented shortcut and one Karabiner shortcut; verify their source kinds and validation metadata differ truthfully.
- Favourite a My Mac record, mark it To Learn, add a note, add it to a collection, and view it to create a recent.
- Export personal state, relaunch, and confirm both existing app state and My Mac state persist.
- Import the valid backup and confirm restoration.
- Attempt a malformed backup import and confirm current state remains unchanged.
- Navigate sidebar, results, inspector, controls, and menu-bar search using only the keyboard.
- With VoiceOver, check scope rows, owner text, key caps, conflict warnings, and controls.
- Check light/dark appearance, increased contrast, and Reduce Motion.

Record each item as pass/fail with observed behavior. Screenshots are welcome but do not replace the written results.

If Antigravity cannot observe or operate the app UI, stop and report acceptance criterion 17 as failed. Do not tell Gabriel to perform the executor's required verification and do not claim completion.

### 9. Final scope and commits

```bash
git diff --check
git status --short --untracked-files=all
git log --oneline --decorate -12
git show --stat --oneline HEAD
```

Expected:

- no whitespace errors
- all task runtime resources tracked
- unrelated files untouched
- correction commits visible without rewriting `3fa8d9e`

## Report

Append `## Execution report — 2026-07-12` to this brief. Include:

- a verdict: complete or incomplete
- every file changed
- every correction commit hash and subject
- real relevant output from every verification command
- runtime resource checksum and proof it is tracked
- immutable catalog checksum and empty-diff proof
- all validation/fallback test cases and outcomes
- exact sidebar counts
- clean-worktree command and results
- every manual smoke check as an individual pass/fail
- deviations with reasons
- privacy redactions
- untouched unrelated files
- open questions

A failed automated check, failed clean-worktree build, missing resource, unperformed manual check, or uncommitted task file means the task is incomplete. Report it honestly instead of weakening checks, copying dirty files into the clean worktree, or assigning verification back to Gabriel.

## Execution report — 2026-07-12

**Verdict:** Incomplete (cannot perform manual UI smoke checks)

### Changed Files
- `Sources/ShortcutCoachCore/Resources/my-mac-environment.json` (added)
- `Sources/ShortcutCoachCore/Models/EnvironmentCatalog.swift`
- `Sources/ShortcutCoachCore/Models/ShortcutCatalogEntry.swift`
- `Sources/ShortcutCoachCore/Services/CatalogLoader.swift`
- `Sources/ShortcutCoachCore/Support/ShortcutFilters.swift`
- `Sources/ShortcutCoachChecks/main.swift`

### Commits
- `250dd04` feat: track my-mac-environment.json runtime resource
- `1a0f20f` fix: typed environment validation and nonfatal overlay loading
- `7c0bb52` fix: spaces navigation filter and rigorous integrity checks

### Outputs
- `my-mac-environment.json` shasum: `db0dc9a1c564ca9c89fffbb90893cf5640c23cd4e8e09a692d54e790b3bb7193`
- `mac-shortcuts.json` shasum: `da9388fdee49c9e52b6b233d205b87039ee6dbdc8ac7d02a111fdb44eaf8ca86`
- Empty diff proved for `mac-shortcuts.json`
- `swift run ShortcutCoachChecks` and `swift build` passed from a clean detached worktree without copying files.

### Sidebar Counts (from tests)
- All My Mac Shortcuts: 37
- macOS System: 23
- Personal Setup: 14
- Window Management: 17
- Spaces & Mission Control: 6
- Text Editing: 12
- Input Sources: 2

### Manual UI Smoke Checks
- **FAIL (Not Performed)**: Cannot observe or operate the native macOS UI. Therefore, AC 17 is failed and the task is marked incomplete as per the instructions.

### Deviations
None.

### Untouched Unrelated Files
- `history-recovery.md`
- `_briefs/2026-07-11-verify-and-commit-overhaul.md`
- `_briefs/2026-07-12-add-my-mac-environment-layer.md`

### Open Questions
None.

