import AppKit
import Foundation
import ShortcutCoachCore

// ---------------------------------------------------------------------------
// Lightweight assertion runner (no XCTest dependency)
// ---------------------------------------------------------------------------

nonisolated(unsafe) var passed = 0
nonisolated(unsafe) var failed = 0

func check(_ description: String, _ condition: @autoclosure () throws -> Bool) {
    do {
        if try condition() {
            passed += 1
            print("  ✅ \(description)")
        } else {
            failed += 1
            print("  ❌ FAIL: \(description)")
        }
    } catch {
        failed += 1
        print("  ❌ ERROR: \(description) — \(error)")
    }
}

// ---------------------------------------------------------------------------
// Load catalog
// ---------------------------------------------------------------------------

print("🔍 Loading catalog…")
let loaded: LoadedCatalog
do {
    loaded = try CatalogLoader().load()
    print("   Source: \(loaded.sourceDescription)")
} catch {
    print("❌ Catalog failed to load: \(error.localizedDescription)")
    exit(1)
}

let shortcuts = loaded.catalog.shortcuts

// ---------------------------------------------------------------------------
// 1 — Catalog decodes & counts
// ---------------------------------------------------------------------------

print("\n📋 Catalog decode checks")
check("Total shortcut count == 102", shortcuts.count == 102)
check("Karabiner shortcut count == 10",
      shortcuts.filter { $0.source == "Karabiner" }.count == 10)

// ---------------------------------------------------------------------------
// 2 — Search finds Karabiner redo shortcut
// ---------------------------------------------------------------------------

print("\n🔎 Search filter checks")
let redoResults = ShortcutFilters.filter(
    shortcuts,
    query: "redo",
    context: "All",
    source: "Karabiner",
    priority: "All"
)
check("Searching 'redo' with source Karabiner includes Command + Y",
      redoResults.contains { $0.shortcut == "Command + Y" })

// ---------------------------------------------------------------------------
// 3 — Context + priority filters
// ---------------------------------------------------------------------------

print("\n🏷️  Context & priority filter checks")
let windowDaily = ShortcutFilters.filter(
    shortcuts,
    query: "",
    context: "Window Control",
    source: "All",
    priority: "Daily"
)
check("Window Control + Daily filter is non-empty", !windowDaily.isEmpty)
check("All results are Window Control context",
      windowDaily.allSatisfy { $0.context == "Window Control" })
check("All results are priority 1 (Daily)",
      windowDaily.allSatisfy { $0.priority == 1 })

// ---------------------------------------------------------------------------
// 4 — Today's 10
// ---------------------------------------------------------------------------

print("\n📅 Today's shortcuts checks")
let today = ShortcutFilters.today(shortcuts)
check("Today returns exactly 10", today.count == 10)
check("All Today items are active & priority 1",
      today.allSatisfy { $0.active && $0.priority == 1 })
check("First Today item is Karabiner", today.first?.source == "Karabiner")

// ---------------------------------------------------------------------------
// 5 — Daily practice progress
// ---------------------------------------------------------------------------

print("\n⌘ Daily progress checks")
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(secondsFromGMT: 0)!
let dayOne = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01 UTC
let dayTwo = Date(timeIntervalSince1970: 1_735_776_000) // 2025-01-02 UTC
let emptySnapshot = DailyPracticeProgress.currentSnapshot(from: nil, now: dayOne, calendar: calendar)
check("New progress snapshot starts empty", emptySnapshot.practicedIDs.isEmpty)
check("New progress snapshot uses expected day key", emptySnapshot.dayKey == "2025-01-01")

if let firstToday = today.first {
    let toggledSnapshot = DailyPracticeProgress.toggled(firstToday.id, in: emptySnapshot)
    check("Toggling a daily shortcut marks it practiced",
          toggledSnapshot.practicedIDs.contains(firstToday.id))
    check("Completed daily count becomes 1",
          DailyPracticeProgress.completedCount(todayShortcuts: today, snapshot: toggledSnapshot) == 1)

    let encoded = DailyPracticeProgress.encoded(toggledSnapshot)
    let restoredSameDay = DailyPracticeProgress.currentSnapshot(from: encoded, now: dayOne, calendar: calendar)
    check("Progress persists on the same day", restoredSameDay == toggledSnapshot)

    let restoredNextDay = DailyPracticeProgress.currentSnapshot(from: encoded, now: dayTwo, calendar: calendar)
    check("Progress resets on the next day", restoredNextDay.practicedIDs.isEmpty)
    check("Next-day snapshot uses new day key", restoredNextDay.dayKey == "2025-01-02")
} else {
    check("Today has a first shortcut for progress checks", false)
}

// ---------------------------------------------------------------------------
// 6 — Shortcut key matching
// ---------------------------------------------------------------------------

print("\n⌨️  Shortcut key matching checks")

if let firstModifiedToday = today.first(where: { $0.shortcut.contains("+") }) {
    check("A bare keystroke (no modifiers) does not match a modified Today shortcut (\(firstModifiedToday.shortcut))",
          !firstModifiedToday.matches(flags: [], charsIgnoringModifiers: "a"))
}


func makeDummyShortcut(shortcut: String) -> ShortcutCatalogEntry {
    let json = """
    {
        "id": "test-id",
        "shortcut": "\(shortcut)",
        "action": "Test Action",
        "source": "macOS default",
        "scope": "Test Scope",
        "priority": 1,
        "context": "Test Context",
        "active": true,
        "sends": "",
        "notes": "",
        "practicePrompt": ""
    }
    """
    return try! JSONDecoder().decode(ShortcutCatalogEntry.self, from: json.data(using: .utf8)!)
}

let cmdZ = makeDummyShortcut(shortcut: "Command + Z")
check("Cmd+Z matches command modifier and 'z'",
      cmdZ.matches(flags: .command, charsIgnoringModifiers: "z"))
check("Cmd+Z does not match command+shift and 'z'",
      !cmdZ.matches(flags: [.command, .shift], charsIgnoringModifiers: "z"))
check("Cmd+Z does not match command and 'x'",
      !cmdZ.matches(flags: .command, charsIgnoringModifiers: "x"))

let cmdShiftZ = makeDummyShortcut(shortcut: "Command + Shift + Z")
check("Cmd+Shift+Z matches command+shift and 'z'",
      cmdShiftZ.matches(flags: [.command, .shift], charsIgnoringModifiers: "z"))
check("Cmd+Shift+Z matches command+shift and 'Z'",
      cmdShiftZ.matches(flags: [.command, .shift], charsIgnoringModifiers: "Z"))

let fnLeft = makeDummyShortcut(shortcut: "Fn + Left Arrow")
check("Fn+Left matches fn + LeftArrow keycode",
      fnLeft.matches(flags: .function, charsIgnoringModifiers: String(UnicodeScalar(NSLeftArrowFunctionKey)!)))
check("Fn+Left matches fn + Home keycode (laptop simulation)",
      fnLeft.matches(flags: .function, charsIgnoringModifiers: String(UnicodeScalar(NSHomeFunctionKey)!)))

let ctrlSpace = makeDummyShortcut(shortcut: "Control + Space")
check("Ctrl+Space matches control and space",
      ctrlSpace.matches(flags: .control, charsIgnoringModifiers: " "))

let ctrlBackspace = makeDummyShortcut(shortcut: "Control + Backspace")
check("Ctrl+Backspace matches control and backspace (127)",
      ctrlBackspace.matches(flags: .control, charsIgnoringModifiers: "\u{7F}"))

let cmdBacktick = makeDummyShortcut(shortcut: "Command + `")
check("Cmd+Backtick matches command and backtick",
      cmdBacktick.matches(flags: .command, charsIgnoringModifiers: "`"))

// ---------------------------------------------------------------------------
// 7 — Catalog integrity tests
// ---------------------------------------------------------------------------

print("\n🔒 Catalog integrity checks")

// Check for duplicate IDs
let allIDs = shortcuts.map { $0.id }
let uniqueIDs = Set(allIDs)
check("No duplicate shortcut IDs", allIDs.count == uniqueIDs.count)

// Missing metadata & invalid key/task values
var hasMissingMetadata = false
var hasInvalidValues = false
for s in shortcuts {
    if s.id.isEmpty || s.source.isEmpty || s.context.isEmpty {
        hasMissingMetadata = true
    }
    if s.shortcut.isEmpty || s.action.isEmpty {
        hasInvalidValues = true
    }
}
check("No missing metadata (id, source, context)", !hasMissingMetadata)
check("No invalid key/task values (shortcut, action)", !hasInvalidValues)

// Dangling related IDs
var hasDanglingRelatedIDs = false
for s in shortcuts {
    if s.notes.contains("Related: [") {
        if let range = s.notes.range(of: "Related: [") {
            let rest = s.notes[range.upperBound...]
            if let endRange = rest.range(of: "]") {
                let idsString = rest[..<endRange.lowerBound]
                let relatedIDs = idsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                for relatedID in relatedIDs {
                    if !relatedID.isEmpty && !uniqueIDs.contains(relatedID) {
                        print("    Dangling ID found: \(relatedID) in \(s.id)")
                        hasDanglingRelatedIDs = true
                    }
                }
            }
        }
    }
}
check("No dangling related IDs", !hasDanglingRelatedIDs)

// Fewer than five entries per app
let appsToCheck = ["Google Chrome", "ChatGPT for macOS", "Google Antigravity", "Pages", "Finder", "Spotify", "WhatsApp", "Preview", "Apple Mail"]
var hasFewerThanFive = false
for app in appsToCheck {
    let count = shortcuts.filter { $0.context == app }.count
    if count < 5 {
        print("    App \(app) has fewer than 5 entries (\(count))")
        hasFewerThanFive = true
    }
}
check("All requested apps have at least 5 entries", !hasFewerThanFive)

// ---------------------------------------------------------------------------
// 7 — Local Library Persistence & Migration
// ---------------------------------------------------------------------------

print("\n💾 Persistence & migration checks")
let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
let managerURL = tempDir.appendingPathComponent("test-library.json")
let manager = UserLibraryManager(fileURL: managerURL)

var state = try! manager.load()
check("New manager loads empty state", state.favourites.isEmpty && state.recents.isEmpty)

state.favourites.insert("test-fav-1")
state.recents.append("test-fav-1")
try! manager.save(state)

let loadedState = try! manager.load()
check("Manager saves and loads state successfully", loadedState.favourites.contains("test-fav-1") && loadedState.recents.first == "test-fav-1")

let exportURL = tempDir.appendingPathComponent("export.json")
try! manager.export(to: exportURL, state: loadedState)
check("Export creates file", FileManager.default.fileExists(atPath: exportURL.path))

let importedState = try! manager.import(from: exportURL)
check("Import returns correct state", importedState.favourites == loadedState.favourites)

let malformedURL = tempDir.appendingPathComponent("malformed.json")
try! "not json".write(to: malformedURL, atomically: true, encoding: .utf8)
do {
    _ = try manager.import(from: malformedURL)
    check("Malformed import fails", false)
} catch {
    check("Malformed import throws error", true)
}

let unchangedState = try! manager.load()
check("Failed import does not overwrite existing state", unchangedState.favourites.contains("test-fav-1"))

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------

print("\n" + String(repeating: "─", count: 40))
print("✅ Passed: \(passed)   ❌ Failed: \(failed)")
if failed > 0 {
    print("⚠️  Some checks failed.")
    exit(1)
} else {
    print("🎉 All checks passed!")
    exit(0)
}
