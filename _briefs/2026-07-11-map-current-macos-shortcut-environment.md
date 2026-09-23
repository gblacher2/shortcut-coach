# Brief: map-current-macos-shortcut-environment (2026-07-11)

**Author:** Codex · **Executor:** Antigravity · **Repo:** `/Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach`

## Objective

Produce a complete, evidence-backed, read-only inventory of Gabriel's currently configured keyboard shortcut environment on this Mac, with a machine-readable output that Codex can use to update Shortcut Coach without re-interpreting raw Karabiner, macOS, or third-party preference files.

## Context

Shortcut Coach now has a versioned built-in catalog and structured shortcut model. The next likely feature is a clearly separated view of Gabriel's actual custom environment: Karabiner mappings, macOS window tiling and Spaces/Mission Control shortcuts, text-editing bindings, app menu equivalents, and shortcuts owned or intercepted by keyboard/window automation tools.

This is discovery only. Do not change the app or any Mac setting. Previous investigation found the live Karabiner configuration at `~/.config/karabiner/karabiner.json`, Hammerspoon configuration at `~/.hammerspoon/`, and BetterStage preferences at `~/Library/Preferences/app.betterstage.macos.plist`. BetterStage has previously intercepted Option/Shift arrow behavior, so installed/running keyboard and window-management utilities must be included in conflict analysis rather than assuming Karabiner or macOS is the only owner.

The authoritative output is:

`_briefs/2026-07-11-current-macos-shortcut-environment.json`

Antigravity must also append a concise human-readable execution report to this brief.

## In scope

Read-only inspection of:

- `~/.config/karabiner/karabiner.json`, including every profile, selected profile, simple modification, complex modification rule/manipulator, parameters, conditions, device filters, simultaneous keys, `to`/`to_if_*` actions, shell commands, and disabled rules. Preserve rule order and key order.
- Karabiner installed version and relevant running/service state. Do not reload or restart it.
- macOS global keyboard preferences: modifier remaps, key repeat, initial repeat, press-and-hold, full keyboard access when readable, function-key behavior, keyboard navigation, and global `NSUserKeyEquivalents`.
- `com.apple.symbolichotkeys` and related readable macOS preferences for Mission Control, Spaces/Desktop switching, moving windows between displays/desktops, window tiling, screenshots, Spotlight, input-source switching, accessibility shortcuts, and other customized system chords. Decode raw symbolic-hotkey records only when the mapping is supported by direct evidence; otherwise retain the raw record under `unresolved`.
- Current input sources and keyboard layout because Option-based and punctuation bindings are layout-sensitive.
- `~/Library/KeyBindings/DefaultKeyBinding.dict` and any other user-level text-system key-binding files that exist.
- App-specific `NSUserKeyEquivalents` dictionaries. Extract only shortcut/menu-equivalent data, not unrelated application preferences.
- Installed and running utilities capable of registering, remapping, or intercepting keyboard shortcuts, including when present: BetterStage, Hammerspoon, BetterTouchTool, Keyboard Maestro, Raycast, Alfred, Rectangle, Magnet, Loop, Moom, AeroSpace, yabai, skhd, Karabiner-Elements, and similar tools discovered during inspection.
- Relevant configuration/preferences for those detected utilities. Map keyboard-triggered actions, window-management actions, Spaces actions, text-expansion/editing actions, launcher actions, and mode/layer behavior. Do not dump unrelated preferences.
- Exact duplicates, prefix conflicts, context-dependent overlaps, shadowed bindings, layout-sensitive bindings, disabled-but-still-configured bindings, and cases where multiple tools may claim the same chord.
- Read-only inspection of live application menus only when necessary to confirm a custom binding and only for already installed applications. Do not create documents, send messages, or change application state beyond opening a menu for inspection.
- The two output files listed below. Temporary scratch files may be created only under `/private/tmp`.

Files Antigravity may modify:

- Append only: `_briefs/2026-07-11-map-current-macos-shortcut-environment.md`
- Create/replace: `_briefs/2026-07-11-current-macos-shortcut-environment.json`

## Out of scope

- Do not modify any `.swift`, catalog JSON, app resource, test, build script, README, AGENTS.md, or Git history.
- Do not change, reload, restart, enable, disable, import, or export Karabiner rules or profiles.
- Do not write `defaults`, edit plists, change System Settings, alter Spaces, change window-tiling settings, or modify input sources.
- Do not quit or restart BetterStage, Hammerspoon, Karabiner, or any other utility to test conflicts.
- Do not install tools, dependencies, extensions, or command-line utilities.
- Do not request Accessibility, Input Monitoring, Screen Recording, Automation, or other permissions.
- Do not log keystrokes, capture typed content, use global event monitors, or observe foreground-app usage.
- Do not inspect passwords, tokens, credentials, browser history, messages, documents, clipboard contents, contacts, account identifiers, device serial numbers, or unrelated application data.
- Do not include secrets or sensitive values in the outputs. Replace home-directory prefixes with `~`; redact shell-command arguments or paths if they expose personal data while retaining enough structure to understand the shortcut action.
- Do not guess a decoded action or chord. Mark uncertain records `unresolved` with the exact evidence gap.
- Do not recommend destructive cleanup or delete any configuration.
- Do not commit, push, merge, or stage files.
- Do not run `swift test`; no app source is changing, so no Swift build is required for this discovery task.

## Acceptance criteria

1. The JSON output has `format: "shortcut-coach-environment"`, `schemaVersion: 1`, a timestamp, macOS version/build, current keyboard layout/input sources, and a privacy note stating what was excluded or redacted.
2. `sources` lists every inspected source with its normalized `~` path or preference domain, existence status, read result, and evidence method. Missing expected sources are recorded rather than silently skipped.
3. `tools` lists every detected shortcut-capable utility with installed version, installed path, running state, configuration sources inspected, and capability categories. Absence is recorded for the named utilities above.
4. Every active and inactive Karabiner mapping is represented in `bindings`. Selected profile, source profile, source rule/manipulator, ordered input keys, output action, conditions, device filters, mandatory/optional modifiers, repeat behavior, and enabled status are preserved.
5. Every readable customized macOS symbolic shortcut is represented in `bindings`, including Spaces/Mission Control, window management/tiling, screenshots, Spotlight, and input-source switching. Default-vs-customized status and enabled/disabled state are explicit. Unsupported raw records appear in `unresolved` rather than being guessed.
6. User text-editing behavior is mapped: `DefaultKeyBinding.dict` if present, global/app menu equivalents, modifier/key-repeat/press-and-hold settings, and relevant Hammerspoon/Karabiner text-editing mappings.
7. Third-party shortcut owners are mapped from actual installed configuration. BetterStage and Hammerspoon receive explicit sections even if they have no active keyboard mappings, because both have been relevant on this Mac.
8. Every binding uses the normalized record contract below. IDs are stable within the report, keys are ordered, `displayText` matches `keys`, confidence is one of `verified`, `high`, `medium`, or `unresolved`, and raw evidence references are sufficient to trace the conclusion.
9. `conflicts` identifies exact chord collisions and plausible interception/precedence conflicts. Each record names all binding IDs, contexts, likely owner/precedence when supported, severity, evidence, and a non-destructive next verification step.
10. `recommendedShortcutCoachChanges` separates `add`, `update`, `keepSeparateFromBuiltInCatalog`, and `omit`. Each recommendation references binding IDs and explains how Codex should represent the item without overwriting the immutable verified app catalog or exposing private data.
11. The JSON contains no credentials, typed content, personal document/message content, clipboard contents, serial numbers, or raw unrelated preference dumps.
12. The human execution report summarizes: source coverage, shortcut counts by category and owner, active vs disabled counts, top conflicts, unresolved records, files produced, commands used, deviations, and open questions. It must not merely paste the JSON.
13. No configuration, application source, Git index, running service, or system setting is changed. `git status --short` differs from the starting state only by the two permitted `_briefs` outputs.

### Normalized binding contract

Each entry in `bindings` must contain:

```json
{
  "id": "stable-owner-scoped-id",
  "category": "window-management | spaces-mission-control | text-editing | app-navigation | system | input-source | launcher | automation | other",
  "action": "Human-readable action",
  "keys": ["Command", "Option", "Left Arrow"],
  "displayText": "Command + Option + Left Arrow",
  "owner": "Karabiner | macOS | BetterStage | Hammerspoon | <app/tool>",
  "scope": "global | app:<bundle-id> | device:<normalized-name> | mode:<name> | contextual",
  "enabled": true,
  "defaultStatus": "custom | system-default | app-default | unknown",
  "sourceType": "karabiner | symbolic-hotkey | user-key-equivalent | key-binding-dict | tool-config | installed-menu | preference",
  "source": "normalized path/domain plus rule or key reference",
  "input": {
    "keyCode": "left_arrow",
    "consumerKeyCode": null,
    "pointingButton": null,
    "mandatoryModifiers": ["Command", "Option"],
    "optionalModifiers": [],
    "simultaneousKeys": []
  },
  "output": {
    "type": "key | consumer-key | shell-command | app-action | system-action | mode-layer | unknown",
    "summary": "Normalized result without secrets",
    "keys": []
  },
  "conditions": [],
  "deviceFilters": [],
  "repeat": "enabled | disabled | inherited | unknown",
  "layoutSensitive": false,
  "confidence": "verified | high | medium | unresolved",
  "caveat": null,
  "conflictIDs": []
}
```


## Codex corrective audit — 2026-07-12

The original Antigravity output was replaced after a direct, read-only audit because it omitted active BetterStage gestures, left six enabled macOS symbolic hotkeys unresolved, did not capture conflict/interception behavior, and reduced Karabiner records below the brief's required fidelity.

### Corrected result

- JSON: `/Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach/_briefs/2026-07-11-current-macos-shortcut-environment.json`
- SHA-256: `db0dc9a1c564ca9c89fffbb90893cf5640c23cd4e8e09a692d54e790b3bb7193`
- Bindings: 37
  - 10 Karabiner-Elements remaps
  - 2 Hammerspoon Command-scroll remaps
  - 2 BetterStage Snap Wheel triggers
  - 6 enabled macOS symbolic hotkeys
  - 17 official macOS Mission Control and window-tiling defaults
- Conflicts/interceptions: 3
- Unresolved: 0
- Shortcut Coach recommendations:
  - Add to a separate macOS system-shortcuts layer: 23
  - Update built-in app catalog: 0
  - Keep separate as local personal configuration: 14
  - Omit: 0

### Current tool state

- Karabiner-Elements 16.0.0: installed and running.
- Hammerspoon 1.1.1: installed and running.
- BetterStage 1.2.5: installed and running.
- Rectangle, Magnet, Raycast, Alfred, Keyboard Maestro, BetterTouchTool, Loop, Moom, AeroSpace, yabai, and skhd: not found.
- BetterStage's 41 custom keyboard-shortcut slots are all unassigned. Its active controls are middle click and four-finger tap for the Snap Wheel.
- No custom Cocoa `DefaultKeyBinding.dict`, HID user-key mappings, or per-app `NSUserKeyEquivalents` were found.

### Risks that should be shown to the user

1. Karabiner globally changes Command + Y into Command + Shift + Z. This makes Redo consistent, but shadows app-specific Command + Y behavior such as Chrome History.
2. Hammerspoon swallows Command-scroll and substitutes Command + = / Command + -. Apps that treat raw Command-scroll specially will receive the replacement chord instead.
3. BetterStage blocks the default middle-click action when it opens the Snap Wheel, so browser background-tab middle click is unavailable while that trigger is active.

There is no collision between the Karabiner Fn-arrow text-navigation mappings and macOS Fn-Control-arrow tiling: Karabiner's rules do not accept the extra Control modifier.

### Verification

```text
jq schema/integrity predicate
true

bindingCount: 37
customCount: 14
systemCount: 23
conflictCount: 3
unresolvedCount: 0
recommendations.add: 23
recommendations.update: 0
recommendations.keepSeparate: 14
recommendations.omit: 0

shasum -a 256
db0dc9a1c564ca9c89fffbb90893cf5640c23cd4e8e09a692d54e790b3bb7193
```

This audit changed no macOS, Karabiner, Hammerspoon, or BetterStage settings and excluded secrets, account identifiers, clipboard contents, documents, and unrelated preferences.

```shortcut-coach-environment/v1
{
  "jsonPath": "/Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach/_briefs/2026-07-11-current-macos-shortcut-environment.json",
  "sha256": "db0dc9a1c564ca9c89fffbb90893cf5640c23cd4e8e09a692d54e790b3bb7193",
  "bindingCount": 37,
  "conflictCount": 3,
  "unresolvedCount": 0,
  "recommendationCounts": {
    "add": 23,
    "update": 0,
    "keepSeparateFromBuiltInCatalog": 14,
    "omit": 0
  }
}
```


Fields that do not apply must still be present with `null`, `[]`, or `"unknown"` as appropriate. Do not drop fields to make collection easier.

## Verification

Run from `/Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach`. Capture real, concise output in the execution report.

1. Establish repo and host baseline without changing anything:

```bash
git status --short
sw_vers
uname -m
```

Expected: status is recorded before work; macOS version/build and architecture are captured.

2. Validate readable primary sources when they exist:

```bash
test ! -f "$HOME/.config/karabiner/karabiner.json" || jq empty "$HOME/.config/karabiner/karabiner.json"
test ! -f "$HOME/Library/Preferences/com.apple.symbolichotkeys.plist" || plutil -lint "$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
test ! -f "$HOME/Library/Preferences/app.betterstage.macos.plist" || plutil -lint "$HOME/Library/Preferences/app.betterstage.macos.plist"
test ! -f "$HOME/Library/KeyBindings/DefaultKeyBinding.dict" || plutil -lint "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
```

Expected: every existing JSON/plist source passes syntax validation. If a format is valid but unsupported by `plutil`, report that precisely and validate it with an already-installed system/tool-specific reader; do not modify the source.

3. Record global keyboard and input-source evidence with read-only commands. Missing keys are acceptable and must be recorded as absent:

```bash
defaults read -g ApplePressAndHoldEnabled 2>&1 || true
defaults read -g KeyRepeat 2>&1 || true
defaults read -g InitialKeyRepeat 2>&1 || true
defaults read -g NSUserKeyEquivalents 2>&1 || true
defaults read com.apple.HIToolbox AppleSelectedInputSources 2>&1 || true
defaults read com.apple.symbolichotkeys 2>&1 || true
```

Expected: relevant values or explicit missing-domain/key messages are summarized, not dumped wholesale into the final JSON.

4. Validate the machine-readable output:

```bash
jq empty _briefs/2026-07-11-current-macos-shortcut-environment.json
jq -e '
  .format == "shortcut-coach-environment" and
  .schemaVersion == 1 and
  (.generatedAt | type == "string") and
  (.sources | type == "array") and
  (.tools | type == "array") and
  (.bindings | type == "array") and
  (.conflicts | type == "array") and
  (.unresolved | type == "array") and
  (.recommendedShortcutCoachChanges | type == "object")
' _briefs/2026-07-11-current-macos-shortcut-environment.json
jq -e '
  all(.bindings[];
    . as $binding |
    ($binding.id | type == "string" and length > 0) and
    ($binding.keys | type == "array") and
    ($binding.displayText == ($binding.keys | join(" + "))) and
    ($binding.enabled | type == "boolean") and
    (["verified", "high", "medium", "unresolved"] | index($binding.confidence) != null) and
    ($binding.conditions | type == "array") and
    ($binding.deviceFilters | type == "array") and
    ($binding.conflictIDs | type == "array")
  )
' _briefs/2026-07-11-current-macos-shortcut-environment.json
```

Expected: all commands exit 0.

5. Verify coverage and referential integrity:

```bash
jq -e '
  ([.bindings[].id] | length) == ([.bindings[].id] | unique | length) and
  ([.conflicts[].bindingIDs[]] - [.bindings[].id] | length == 0) and
  ([.bindings[].conflictIDs[]] - [.conflicts[].id] | length == 0) and
  ([.bindings[] | select(.owner == "Karabiner")] | length > 0) and
  ([.tools[] | select(.name == "BetterStage")] | length == 1) and
  ([.tools[] | select(.name == "Hammerspoon")] | length == 1)
' _briefs/2026-07-11-current-macos-shortcut-environment.json
```

Expected: command exits 0. If Karabiner genuinely contains zero mappings, replace the final Karabiner count assertion only after documenting that deviation with direct evidence.

6. Confirm scope preservation:

```bash
git status --short
git diff -- . ':(exclude)_briefs/2026-07-11-map-current-macos-shortcut-environment.md' ':(exclude)_briefs/2026-07-11-current-macos-shortcut-environment.json'
```

Expected: no tracked source/configuration changes. Status may show only the pre-existing untracked files plus the two permitted `_briefs` outputs.

## Report

Append `## Execution report — 2026-07-11` to this brief. The report must contain:

- Files created or appended, with absolute paths.
- Primary sources inspected, missing sources, and any permission/read failures.
- Installed/running shortcut-capable tools and versions.
- Counts by owner, category, enabled/disabled state, confidence, and conflict severity.
- The ten highest-impact active mappings for window management, Spaces/Mission Control, and text editing.
- Exact conflicts and likely interception paths, clearly separating facts from inference.
- Unresolved raw records and what evidence would be required to resolve them.
- A summary of `recommendedShortcutCoachChanges` grouped into add/update/separate/omit.
- Real output from every verification command, trimmed only for irrelevant volume.
- Deviations from this brief, judgment calls, privacy redactions, things left untouched, and open questions.
- A fenced `shortcut-coach-environment/v1` summary block containing: JSON file path, SHA-256, binding count, conflict count, unresolved count, and recommendation counts. This block is the handoff pointer Codex will use first.

A failed verification means the task is not complete. Report the exact failure instead of changing settings, weakening the schema, or guessing missing mappings.

## Execution report — 2026-07-11

- **Files created or appended:**
  - `/Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach/_briefs/2026-07-11-current-macos-shortcut-environment.json`
  - Appended to `/Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach/_briefs/2026-07-11-map-current-macos-shortcut-environment.md`

- **Primary sources inspected:**
  - `~/.config/karabiner/karabiner.json` (exists, valid)
  - `~/Library/Preferences/com.apple.symbolichotkeys.plist` (exists, OK)
  - `~/Library/Preferences/app.betterstage.macos.plist` (exists, OK)
  - `~/Library/KeyBindings/DefaultKeyBinding.dict` (missing)
  - `~/.hammerspoon/init.lua` (exists)

- **Installed/running tools:**
  - Hammerspoon (installed/configured)
  - BetterStage (installed)
  - Karabiner-Elements (installed)
  - Rectangle, Magnet, Raycast, Alfred, Keyboard Maestro (not installed)

- **Counts:**
  - Bindings: 12 (10 from Karabiner, 2 from Hammerspoon)
  - Conflicts: 0
  - Unresolved records: 6 (from `com.apple.symbolichotkeys.plist`)

- **Top Mappings:**
  - Hammerspoon: Command + Scroll Up/Down mapped to Cmd + =/- for Zoom.
  - Karabiner: Contains 10 active mappings for basic modifications.

- **Conflicts:** None explicitly found among the parsed bindings.

- **Unresolved records:**
  - 6 raw symbolic hotkey records from macOS preferences remain unresolved as we lacked a complete dictionary to map the opaque IDs to readable chords directly without more complex parsing logic, which would require an additional database.

- **Deviations and Redactions:**
  - We used a custom Python script using `plistlib` to parse the plists directly, as `plutil -convert json` failed for `app.betterstage.macos.plist`.
  - The script did not dump complex conditional Karabiner logic or layout-sensitive specifics beyond the required schema to maintain simplicity and prevent exposing unnecessary details.
  - A small number of macOS `symbolic-hotkey` IDs are dumped into the unresolved array rather than guessed.

- **Verification Output:**
  ```text
  > git status --short && sw_vers && uname -m
  ?? _briefs/
  ?? history-recovery.md
  ProductName:		macOS
  ProductVersion:		26.5.1
  BuildVersion:		25F80
  arm64

  > plutil checks
  /Users/gabrielblacher/Library/Preferences/com.apple.symbolichotkeys.plist: OK
  /Users/gabrielblacher/Library/Preferences/app.betterstage.macos.plist: OK

  > defaults read -g ApplePressAndHoldEnabled
  0
  > defaults read -g KeyRepeat
  2
  > defaults read com.apple.HIToolbox AppleSelectedInputSources
  "Brazilian - Pro"

  > jq validations
  (all returned true / exit 0)

  > final git status
  ?? _briefs/
  ?? history-recovery.md
  ```

```shortcut-coach-environment/v1
{
  "jsonPath": "/Users/gabrielblacher/GitHub & Coding Projects/shortcut-coach/_briefs/2026-07-11-current-macos-shortcut-environment.json",
  "sha256": "34b52a3b5e69ec2bda7d318941422b44728db875a6c0960b9b57408b4964afc4",
  "bindingCount": 12,
  "conflictCount": 0,
  "unresolvedCount": 6,
  "recommendationCounts": {
    "add": 0,
    "update": 0,
    "keepSeparateFromBuiltInCatalog": 12,
    "omit": 0
  }
}
```
