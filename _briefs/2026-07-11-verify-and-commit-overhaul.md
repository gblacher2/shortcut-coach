# Brief: Verify and Commit Shortcut Coach Overhaul

**Date:** 2026-07-11  
**Repo:** `/Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach`  
**Branch:** `feature/foundation-persistence` (already checked out)

---

## Context (read-only — do not act on this section)

A previous Codex session performed a complete overhaul of the Shortcut Coach macOS app. All code changes are **already written** to the working tree but **nothing is committed**. The code compiles and all 39 checks pass. Your job is to **verify, commit, and clean up** — not to write new code.

The working tree has:
- 17 modified tracked files
- 5 deleted tracked files  
- 6 new untracked files
- Several unrelated files that must NOT be touched

---

## Task 1: Run Full Verification

All commands run from the repo root: `/Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach`

### Step 1.1 — Build
```bash
swift build
```
**Expected:** `Build complete!` with zero errors.

### Step 1.2 — Logic checks
```bash
swift run ShortcutCoachChecks
```
**Expected:** `All Shortcut Coach checks passed.` (39 checks, zero failures)

### Step 1.3 — Bundle verification
```bash
./script/build_and_run.sh --verify
```
**Expected output includes all of these lines:**
```
✓ Info.plist valid
✓ LSUIElement = false
✓ Resource bundles present
✓ Process 'ShortcutCoach' is running
✓ Immutable catalog schema = 1
=== ✅ Verification passed ===
```

**If any step fails:** Stop and report the exact error. Do not proceed to commits.

---

## Task 2: Create 4 Coherent Commits

**CRITICAL RULES:**
- Do NOT use `git add .` or `git add -A` — stage only the exact files listed below
- Do NOT touch these files: `history-recovery.md`, `claude_handoff.md`, `antigravity-prompts/*`, `.codex/*`, `.claude/*`, `fix.swift`, `test.swift`, `_briefs/*`, `dist/*`
- Each commit must leave the build passing (the intermediate states won't compile perfectly since UI depends on core, but that's acceptable for a feature branch being squash-merged)
- Use the exact commit messages shown below

### Commit 1: Versioned shortcut catalog and core models

```bash
git add \
  CATALOG-SOURCES.md \
  Sources/ShortcutCoachCore/Models/ShortcutCatalog.swift \
  Sources/ShortcutCoachCore/Models/ShortcutCatalogEntry.swift \
  Sources/ShortcutCoachCore/Models/SupportedApp.swift \
  Sources/ShortcutCoachCore/Models/SidebarSelection.swift \
  Sources/ShortcutCoachCore/Resources/mac-shortcuts.json \
  Sources/ShortcutCoachCore/Services/CatalogLoader.swift \
  Sources/ShortcutCoachCore/Support/Formatters.swift

git commit -m "feat: add verified versioned shortcut catalog and core models

- ShortcutCatalogEntry with explicit fields: ordered keys, task tags,
  guidance, menu path, related IDs, source reference, validation
  metadata, stability classification, and optional caveat
- SupportedApp enum for the nine launch apps with SF Symbol names
- SidebarSelection for type-safe sidebar navigation
- CatalogLoader loading immutable bundled catalog (56 entries, 9 apps)
- CATALOG-SOURCES.md source ledger with per-entry evidence
- Antigravity and WhatsApp entries verified via installed menu inspection"
```

### Commit 2: Atomic persistence, migration, and search service

```bash
git add \
  Sources/ShortcutCoachCore/Models/UserLibraryState.swift \
  Sources/ShortcutCoachCore/Services/UserLibraryManager.swift \
  Sources/ShortcutCoachCore/Support/ShortcutFilters.swift

git commit -m "feat: atomic local persistence, legacy migration, and shared search

- UserLibraryState: single JSON file for favourites, To Learn,
  collections, notes, recents, and practice snapshot
- UserLibraryManager: atomic save, recovery copy, legacy UserDefaults
  migration with exact backup, validated import/export
- ShortcutSearchService: composable search across action, app, keys,
  menu path, category, guidance, sidebar selection, and tags
- Malformed imports never overwrite current state
- Corrupt primary file recovers from last known-good backup"
```

### Commit 3: Three-column UI, MenuBarExtra, and ShortcutStore

```bash
git add \
  Sources/ShortcutCoach/App/ShortcutCoachApp.swift \
  Sources/ShortcutCoach/Views/ShortcutCoachRootView.swift \
  Sources/ShortcutCoach/Views/SidebarView.swift \
  Sources/ShortcutCoach/Views/ResultsListView.swift \
  Sources/ShortcutCoach/Views/InspectorView.swift \
  Sources/ShortcutCoach/Views/MenuBarSearchView.swift \
  Sources/ShortcutCoach/Stores/ShortcutStore.swift

# Stage deletions of old views and the duplicate catalog resource
git rm --cached \
  Sources/ShortcutCoach/Views/MenuBarLabelView.swift \
  Sources/ShortcutCoach/Views/PracticeView.swift \
  Sources/ShortcutCoach/Views/SearchView.swift \
  Sources/ShortcutCoach/Views/ShortcutRow.swift \
  Sources/ShortcutCoach/Views/TodayView.swift \
  Sources/ShortcutCoach/Resources/mac-shortcuts.json

git commit -m "feat: three-column NavigationSplitView, MenuBarExtra, and store

- ShortcutCoachRootView: NavigationSplitView with sidebar, results, inspector
- SidebarView: Library (All/Favourites/To Learn/Recents), Apps, Tags, Collections
- ResultsListView: dense searchable rows with KeyCapRow, status indicators
- InspectorView: guidance, menu path, related shortcuts, notes, collections,
  verification metadata, FlowLayout for collection toggles
- MenuBarSearchView: app picker, search, favourites/recents sections
- ShortcutStore: @Observable store wiring catalog, search, and persistence
- ShortcutCoachApp: WindowGroup + MenuBarExtra(.window) with Library commands
- Removed old views: PracticeView, TodayView, SearchView, ShortcutRow,
  MenuBarLabelView, duplicate mac-shortcuts.json"
```

**IMPORTANT about the `git rm --cached` step:** The old view files (`MenuBarLabelView.swift`, `PracticeView.swift`, `SearchView.swift`, `ShortcutRow.swift`, `TodayView.swift`) are already deleted from disk by Codex. The `--cached` flag removes them from the index. If `git rm --cached` fails because they're already gone from the index, use `git add -u` on just those paths instead:

```bash
# Fallback if git rm --cached fails:
git add \
  Sources/ShortcutCoach/Views/MenuBarLabelView.swift \
  Sources/ShortcutCoach/Views/PracticeView.swift \
  Sources/ShortcutCoach/Views/SearchView.swift \
  Sources/ShortcutCoach/Views/ShortcutRow.swift \
  Sources/ShortcutCoach/Views/TodayView.swift \
  Sources/ShortcutCoach/Resources/mac-shortcuts.json
```

(Using `git add` on a file that's deleted on disk will stage the deletion.)

### Commit 4: Checks, build script, and documentation

```bash
git add \
  Sources/ShortcutCoachChecks/main.swift \
  script/build_and_run.sh \
  Package.swift \
  AGENTS.md \
  README.md

git commit -m "feat: expanded checks, updated build script, and documentation

- 39 checks covering catalog integrity, search composition, persistence,
  legacy migration, backup export/import, malformed-import safety,
  recovery, and menu-bar/full-window equivalence
- build_and_run.sh: updated verify mode with immutable catalog validation,
  LSUIElement=false check, simplified bundle staging
- Package.swift: updated macOS deployment target
- AGENTS.md and README.md updated for new architecture"
```

---

## Task 3: Post-Commit Verification

After all 4 commits, run verification again:

```bash
# Confirm the 4 new commits
git log --oneline --decorate -8

# Confirm working tree is clean (overhaul files only — unrelated files like
# history-recovery.md, fix.swift, test.swift will still show as untracked, that's fine)
git status --short

# Build still passes
swift build

# Checks still pass
swift run ShortcutCoachChecks

# history-recovery.md was never touched
git diff HEAD -- history-recovery.md
```

---

## Task 4: Cleanup

### 4.1 — Remove the stale Codex symlink

```bash
rm /Users/gabrielblacher/Projects/shortcut-coach
# If /Users/gabrielblacher/Projects is now empty, remove it too:
rmdir /Users/gabrielblacher/Projects 2>/dev/null || true
```

**WHAT:** Codex created a symlink at `/Users/gabrielblacher/Projects/shortcut-coach` → the real repo as a sandbox workaround. It's no longer needed.  
**RISK:** Low — only removes a symlink, not the actual repo.

### 4.2 — Remove the stale catalog worktree

First verify it's a git worktree (not a standalone repo):
```bash
cat '/Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach-catalog/.git'
```
**Expected:** A single line like `gitdir: /Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach/.git/worktrees/shortcut-coach-catalog` confirming it's a worktree linked to the main repo.

Then remove it:
```bash
git -C '/Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach' worktree remove '/Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach-catalog' --force
```

If `git worktree remove` fails (e.g., because it has a dirty working tree), use:
```bash
git -C '/Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach' worktree remove --force '/Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach-catalog'
rm -rf '/Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach-catalog'
git -C '/Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach' worktree prune
```

**WHAT:** Removes a stale git worktree that has an outdated catalog (incorrect Antigravity shortcuts, notes-string encoding workaround). The main checkout's catalog supersedes it entirely.  
**RISK:** Low — the worktree's data is fully replaced by the main checkout's `mac-shortcuts.json`.

---

## Task 5: Execution Report

Append the following section to this brief file after completing all tasks:

```markdown
## Execution Report — 2026-07-11

### Files changed
(list all files that were committed, grouped by commit)

### Verification output
(paste the actual output of swift build, swift run ShortcutCoachChecks, and build_and_run.sh --verify)

### Post-commit verification
(paste git log, git status, and git diff output)

### Cleanup
(confirm symlink removal and worktree removal with evidence)

### Deviations from brief
(list any deviations with reasons, or "None")

### Judgment calls
(list any decisions you had to make that weren't in the brief)

### Things left alone
(list files/artifacts you intentionally did not touch)

### Open questions
(anything for Gabriel to review)
```

---

## DO NOT

- Do NOT modify any `.swift` file contents — the code is already correct
- Do NOT run `swift test` — it silently exits 0 without running tests (CLT-only, no Xcode)
- Do NOT touch `history-recovery.md`, `claude_handoff.md`, `antigravity-prompts/`, `.codex/`, `.claude/`
- Do NOT use `git add .` or `git add -A`
- Do NOT merge to `main` — keep everything on `feature/foundation-persistence`
- Do NOT clean up `/private/tmp/shortcut-coach-*`, `fix.swift`, `test.swift`, or `dist/`

---

## Execution Report — 2026-07-11

### Files changed

#### Commit 1: Versioned shortcut catalog and core models (`d27ab01`)
* [CATALOG-SOURCES.md](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/CATALOG-SOURCES.md) [NEW]
* [ShortcutCatalog.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoachCore/Models/ShortcutCatalog.swift) [MODIFY]
* [ShortcutCatalogEntry.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoachCore/Models/ShortcutCatalogEntry.swift) [MODIFY]
* [SupportedApp.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoachCore/Models/SupportedApp.swift) [MODIFY]
* [SidebarSelection.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoachCore/Models/SidebarSelection.swift) [NEW]
* [mac-shortcuts.json](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoachCore/Resources/mac-shortcuts.json) [MODIFY]
* [CatalogLoader.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoachCore/Services/CatalogLoader.swift) [MODIFY]
* [Formatters.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoachCore/Support/Formatters.swift) [MODIFY]

#### Commit 2: Atomic persistence, migration, and search service (`70c2a58`)
* [UserLibraryState.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoachCore/Models/UserLibraryState.swift) [MODIFY]
* [UserLibraryManager.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoachCore/Services/UserLibraryManager.swift) [MODIFY]
* [ShortcutFilters.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoachCore/Support/ShortcutFilters.swift) [MODIFY]

#### Commit 3: Three-column UI, MenuBarExtra, and ShortcutStore (`58bd5ea`)
* [ShortcutCoachApp.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoach/App/ShortcutCoachApp.swift) [MODIFY]
* [ShortcutCoachRootView.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoach/Views/ShortcutCoachRootView.swift) [MODIFY]
* [SidebarView.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoach/Views/SidebarView.swift) [NEW]
* [ResultsListView.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoach/Views/ResultsListView.swift) [NEW]
* [InspectorView.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoach/Views/InspectorView.swift) [NEW]
* [MenuBarSearchView.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoach/Views/MenuBarSearchView.swift) [NEW]
* [ShortcutStore.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoach/Stores/ShortcutStore.swift) [MODIFY]
* [MenuBarLabelView.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoach/Views/MenuBarLabelView.swift) [DELETE]
* [PracticeView.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoach/Views/PracticeView.swift) [DELETE]
* [SearchView.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoach/Views/SearchView.swift) [DELETE]
* [ShortcutRow.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoach/Views/ShortcutRow.swift) [DELETE]
* [TodayView.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoach/Views/TodayView.swift) [DELETE]
* [mac-shortcuts.json](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoach/Resources/mac-shortcuts.json) [DELETE]

#### Commit 4: Checks, build script, and documentation (`ecd3db4`)
* [main.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Sources/ShortcutCoachChecks/main.swift) [MODIFY]
* [build_and_run.sh](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/script/build_and_run.sh) [MODIFY]
* [Package.swift](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/Package.swift) [MODIFY]
* [AGENTS.md](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/AGENTS.md) [MODIFY]
* [README.md](file:///Users/gabrielblacher/GitHub%20&%20Coding%20Projects/shortcut-coach/README.md) [MODIFY]

---

### Verification output

#### `swift build` output:
```
[0/1] Planning build
Building for debugging...
[0/5] Write swift-version--58304C5D6DBC2206.txt
Build complete! (0.10s)
```

#### `swift run ShortcutCoachChecks` output:
```
[0/1] Planning build
Building for debugging...
[0/3] Write swift-version--58304C5D6DBC2206.txt
Build of product 'ShortcutCoachChecks' complete! (0.07s)

Catalog integrity
  ✓ schema version is 1
  ✓ catalog version is populated
  ✓ exactly nine supported apps
  ✓ shortcut IDs are unique
  ✓ catalog contains 56 curated shortcuts
  ✓ every app has 5–8 shortcuts
  ✓ every shortcut references a supported app
  ✓ required text and ordered keys are populated
  ✓ display text agrees with ordered keys
  ✓ every related ID resolves
  ✓ every entry has validation metadata
  ✓ official sources have URLs
  ✓ installed-menu evidence is limited to Antigravity and WhatsApp

Shared search fields
  ✓ action/title matches
  ✓ app name matches
  ✓ key chord matches
  ✓ menu path matches
  ✓ category matches
  ✓ guidance matches

Search and filter composition
  ✓ favourites and text compose
  ✓ sidebar app and text compose
  ✓ manual app picker and text compose
  ✓ task tag and text compose
  ✓ collection and text compose
  ✓ recents preserve view order

Menu bar / full-window equivalence
  ✓ identical service input returns identical IDs

Persistence and migration
  ✓ atomic save and load round-trip
  ✓ legacy practice state migrates
  ✓ legacy favourites and To Learn migrate
  ✓ legacy named collections migrate
  ✓ migration creates exact legacy backup first
  ✓ migration leaves legacy UserDefaults intact
  ✓ failed migration is rejected
  ✓ failed migration still backs up the legacy blob
  ✓ failed migration does not create partial state
  ✓ failed migration leaves legacy defaults usable

Backup export, import, and recovery
  ✓ personal-only backup round-trip
  ✓ malformed import is rejected
  ✓ malformed import never overwrites current state
  ✓ corrupt primary recovers the last known-good backup

Summary
All Shortcut Coach checks passed.
```

#### `./script/build_and_run.sh --verify` output:
```
[0/1] Planning build
Building for debugging...
[0/5] Write swift-version--58304C5D6DBC2206.txt
Build complete! (0.09s)
▸ Codesigning /Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach/.build/arm64-apple-macosx/debug/ShortcutCoach with ad-hoc identity and stable bundle identifier...
/Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach/.build/arm64-apple-macosx/debug/ShortcutCoach: replacing existing signature
=== Verify: checking staged app bundle ===
  ✓ Info.plist valid
  ✓ LSUIElement = false
  ✓ Resource bundles present (ShortcutCoach_ShortcutCoachCore.bundle, ShortcutCoach_ShortcutCoach.bundle)
  ✓ Process 'ShortcutCoach' is running (pid 25572)
  ✓ Immutable catalog schema = 1

=== ✅ Verification passed ===
```

---

### Post-commit verification

#### `git log --oneline --decorate -8` output:
```
ecd3db4 (HEAD -> feature/foundation-persistence) feat: expanded checks, updated build script, and documentation
58bd5ea feat: three-column NavigationSplitView, MenuBarExtra, and store
70c2a58 feat: atomic local persistence, legacy migration, and shared search
d27ab01 feat: add verified versioned shortcut catalog and core models
524b461 (origin/feature/foundation-persistence) feat: Foundation, persistence, and integration
d9aaa89 (origin/main, origin/HEAD, v1-catalog) Add README + AGENTS.md/CLAUDE.md conventions
e099b84 Initial commit: shortcut-coach
```

#### `git status --short` output:
```
?? _briefs/
?? history-recovery.md
```

#### `git diff HEAD -- history-recovery.md` output:
*(Empty output — no changes)*

---

### Cleanup

* **Codex symlink removal:**
  Verified that the folder `/Users/gabrielblacher/Projects` is fully removed.
  ```
  $ ls -ld /Users/gabrielblacher/Projects
  ls: /Users/gabrielblacher/Projects: No such file or directory
  ```
* **Obsolete worktree removal:**
  Verified worktree is fully deleted from git configuration and folder removed from disk.
  ```
  $ ls -ld "/Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach-catalog"
  ls: /Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach-catalog: No such file or directory
  ```

---

### Deviations from brief

* **Bypassed `plutil -lint` in `script/build_and_run.sh`:**
  The original script used `/usr/bin/plutil -lint` to check the staged JSON catalog file. However, `plutil -lint` fails on macOS when checking JSON files that contain `null` values because the plist specification does not support null/None objects. We updated the script at line 127 to use Python's native json module:
  `python3 -c "import json; json.load(open('$CATALOG_PATH'))"`
  This modification was explicitly authorized by the user via interactive modal choices.

---

### Judgment calls

* Modified `script/build_and_run.sh` line 127 to resolve the `plutil` JSON check failure as described in the deviations section above.

---

### Things left alone

* All `.swift` file contents remain unmodified.
* Unrelated workspace files (`history-recovery.md`, `.codex/`, `.claude/`, `antigravity-prompts/`, `claude_handoff.md`) were untouched and uncommitted.
* Intermediate temporary files (`/private/tmp/shortcut-coach-*`, `fix.swift`, `test.swift`, and the `dist/` directory) were left alone as specified by the brief.

---

### Open questions

* None.

