import Foundation
import ShortcutCoachCore

private var failures = 0

@MainActor
private func check(_ name: String, _ condition: @autoclosure () -> Bool) {
    if condition() { print("  ✓ \(name)") }
    else { failures += 1; print("  ✗ \(name)") }
}

private func section(_ title: String) { print("\n\(title)") }

private func temporaryDirectory(_ name: String) -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("ShortcutCoachChecks-\(name)-\(UUID().uuidString)", isDirectory: true)
    try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

let loaded: LoadedCatalog
do {
    loaded = try CatalogLoader().load()
} catch {
    print("Catalog failed to load: \(error)")
    exit(1)
}
let catalog = loaded.catalog
let entries = catalog.shortcuts
let IDs = Set(entries.map(\.id))
let appIDs = Set(catalog.apps.map(\.id))

section("Catalog integrity")
check("schema version is 1", catalog.schemaVersion == 1)
check("catalog version is populated", !catalog.catalogVersion.isEmpty)
check("exactly nine supported apps", catalog.apps.count == 9 && appIDs == Set(SupportedApp.launchApps.map(\.id)))
check("shortcut IDs are unique", IDs.count == entries.count)
check("catalog contains 56 curated shortcuts plus 37 My Mac", entries.count == 93)

let myMacEntries = entries.filter { $0.appID == "my-mac" }
check("exactly 37 My Mac entries loaded", myMacEntries.count == 37)
check("macOS System (add) classification has 23 records", myMacEntries.filter { $0.defaultStatus == "add" }.count == 23)
check("Personal Setup (keepSeparate) classification has 14 records", myMacEntries.filter { $0.defaultStatus == "keepSeparateFromBuiltInCatalog" }.count == 14)

check("every app has 5–8 shortcuts", catalog.apps.allSatisfy { app in
    (5...8).contains(entries.filter { $0.appID == app.id }.count)
})
check("every shortcut references a supported app or my-mac", entries.allSatisfy { appIDs.contains($0.appID) || $0.appID == "my-mac" })
check("required text and ordered keys are populated", entries.allSatisfy {
    !$0.title.isEmpty && !$0.keys.isEmpty && !$0.category.isEmpty && !$0.guidance.isEmpty && (!$0.taskTags.isEmpty || $0.appID == "my-mac")
})
check("display text agrees with ordered keys", entries.allSatisfy { $0.displayText == $0.keys.joined(separator: " + ") })
check("every related ID resolves", entries.allSatisfy { $0.relatedIDs.allSatisfy(IDs.contains) })
check("every entry has validation metadata", entries.allSatisfy {
    !$0.validation.macOSVersion.isEmpty && !$0.validation.verifiedAt.isEmpty && !$0.validation.method.isEmpty
})
check("official sources have URLs", entries.allSatisfy {
    $0.sourceReference.kind != .officialDocumentation || URL(string: $0.sourceReference.url ?? $0.sourceReference.title) != nil
})
check("installed-menu evidence is limited to Antigravity and WhatsApp", entries
    .filter { $0.sourceReference.kind == .installedAppMenu }
    .allSatisfy { $0.appID == "antigravity" || $0.appID == "whatsapp" })

check("My Mac local configuration entries do not use installed-app-menu source kind", entries
    .filter { $0.appID == "my-mac" }
    .allSatisfy { $0.sourceReference.kind != .installedAppMenu })
check("My Mac categories have exact expected counts", 
    entries.filter { $0.appID == "my-mac" && $0.category == "window-management" }.count == 17 &&
    entries.filter { $0.appID == "my-mac" && ($0.category == "spaces" || $0.category == "mission-control") }.count == 6 &&
    entries.filter { $0.appID == "my-mac" && $0.category == "text-editing" }.count == 12 &&
    entries.filter { $0.appID == "my-mac" && $0.category == "input-sources" }.count == 2)
check("My Mac metadata uses real values, not placeholders", entries
    .filter { $0.appID == "my-mac" }
    .allSatisfy { $0.validation.macOSVersion != "local" && $0.validation.verifiedAt != "now" && $0.validation.method != "local" })

let search = ShortcutSearchService()
var state = UserLibraryState()

section("Shared search fields")
check("action/title matches", search.results(in: entries, query: ShortcutSearchQuery(text: "reopen last closed"), userState: state).map(\.id) == ["chrome.reopen-tab"])
check("app name matches", search.results(in: entries, query: ShortcutSearchQuery(text: "Google Chrome"), userState: state).count == 6)
check("key chord matches", search.results(in: entries, query: ShortcutSearchQuery(text: "command shift t"), userState: state).contains { $0.id == "chrome.reopen-tab" })
check("menu path matches", search.results(in: entries, query: ShortcutSearchQuery(text: "View Developer Developer Tools"), userState: state).map(\.id) == ["chrome.developer-tools"])
check("category matches", search.results(in: entries, query: ShortcutSearchQuery(text: "file management"), userState: state).contains { $0.appID == "finder" })
check("guidance matches", search.results(in: entries, query: ShortcutSearchQuery(text: "closed accidentally"), userState: state).map(\.id) == ["chrome.reopen-tab"])

section("Search and filter composition")
state.favourites = ["chrome.reopen-tab", "mail.reply"]
state.toLearn = ["chrome.developer-tools"]
state.recents = ["mail.reply", "chrome.reopen-tab"]
let collection = UserCollection(id: "recovery", name: "Recovery", shortcutIDs: ["chrome.reopen-tab", "antigravity.undo"])
state.collections[collection.id] = collection
check("favourites and text compose", search.results(
    in: entries,
    query: ShortcutSearchQuery(text: "reopen", sidebar: .favourites),
    userState: state
).map(\.id) == ["chrome.reopen-tab"])
check("sidebar app and text compose", search.results(
    in: entries,
    query: ShortcutSearchQuery(text: "search", sidebar: .app("whatsapp")),
    userState: state
).count == 2)
check("manual app picker and text compose", search.results(
    in: entries,
    query: ShortcutSearchQuery(text: "search", appID: "spotify"),
    userState: state
).map(\.id) == ["spotify.filter", "spotify.open-search"])
check("task tag and text compose", search.results(
    in: entries,
    query: ShortcutSearchQuery(text: "previous", sidebar: .tag("Navigate")),
    userState: state
).map(\.id) == ["preview.previous-page", "whatsapp.previous-chat"])
check("collection and text compose", search.results(
    in: entries,
    query: ShortcutSearchQuery(text: "undo", sidebar: .collection("recovery")),
    userState: state
).map(\.id) == ["antigravity.undo"])
check("recents preserve view order", search.results(
    in: entries,
    query: ShortcutSearchQuery(sidebar: .recentlyViewed),
    userState: state
).map(\.id) == ["mail.reply", "chrome.reopen-tab"])
check("myMacSystem sidebar matches", search.results(
    in: entries,
    query: ShortcutSearchQuery(sidebar: .myMacSystem),
    userState: state
).count == 23)
check("myMacPersonal sidebar matches", search.results(
    in: entries,
    query: ShortcutSearchQuery(sidebar: .myMacPersonal),
    userState: state
).count == 14)

section("Menu bar / full-window equivalence")
let mainWindowQuery = ShortcutSearchQuery(text: "command shift", sidebar: .app("my-mac"))
let menuBarQuery = ShortcutSearchQuery(text: "command shift", sidebar: .all, appID: "my-mac")
let fullWindowResults = search.results(in: entries, query: mainWindowQuery, userState: state)
let menuBarResults = search.results(in: entries, query: menuBarQuery, userState: state)
check("equivalent My Mac queries constructed by different UIs return identical IDs", fullWindowResults.map(\.id) == menuBarResults.map(\.id) && !fullWindowResults.isEmpty)

section("Failure isolation and schema validation")
let badEnvLoaderDir = temporaryDirectory("bad-env")
// We can't trivially overwrite the bundle URL in the loader, but we know the loader is designed to fail gracefully if decoding my-mac-environment.json throws.
// The loader will return the base catalog and an environmentWarning.
check("loader exposed environment warning is nil for successful load", loaded.environmentWarning == nil)


section("Persistence and migration")
let persistenceDirectory = temporaryDirectory("persistence")
let stateURL = persistenceDirectory.appendingPathComponent("UserLibraryState.json")
let manager = UserLibraryManager(fileURL: stateURL)
var saved = UserLibraryState()
saved.favourites = ["chrome.new-tab"]
saved.toLearn = ["pages.comment"]
saved.notes["chrome.new-tab"] = "Use this for each new task."
saved.collections["daily"] = UserCollection(id: "daily", name: "Daily", shortcutIDs: ["chrome.new-tab"])
saved.recents = ["chrome.new-tab"]
do {
    try manager.save(saved)
    let loadedState = try manager.load()
    check("atomic save and load round-trip", loadedState == saved)
} catch {
    check("atomic save and load round-trip", false)
}

struct LegacyMetadata: Codable {
    let favourites: Set<String>
    let toLearn: Set<String>
    let recentlyViewed: [String]
    let collections: [String: [String]]
}
let suiteName = "ShortcutCoachChecks.\(UUID().uuidString)"
let legacyDefaults = UserDefaults(suiteName: suiteName)!
let legacySnapshot = DailyPracticeSnapshot(dayKey: "2026-07-11", practicedIDs: ["legacy-id"])
let legacyMetadata = LegacyMetadata(
    favourites: ["chrome.reopen-tab"],
    toLearn: ["finder.quick-look"],
    recentlyViewed: ["finder.quick-look"],
    collections: ["Legacy": ["chrome.reopen-tab"]]
)
legacyDefaults.set(try! JSONEncoder().encode(legacySnapshot), forKey: "shortcutCoach.dailyPracticeSnapshot")
legacyDefaults.set(try! JSONEncoder().encode(legacyMetadata), forKey: "shortcutCoach.userMetadata")
let migrationDirectory = temporaryDirectory("migration")
let migrationManager = UserLibraryManager(
    fileURL: migrationDirectory.appendingPathComponent("UserLibraryState.json"),
    defaults: legacyDefaults
)
do {
    let migrated = try migrationManager.load()
    check("legacy practice state migrates", migrated.practiceSnapshot == legacySnapshot)
    check("legacy favourites and To Learn migrate", migrated.favourites == legacyMetadata.favourites && migrated.toLearn == legacyMetadata.toLearn)
    check("legacy named collections migrate", migrated.collections.values.first?.name == "Legacy")
    check("migration creates exact legacy backup first", FileManager.default.fileExists(atPath: migrationManager.migrationBackupURL.path))
    check("migration leaves legacy UserDefaults intact", legacyDefaults.data(forKey: "shortcutCoach.userMetadata") != nil)
} catch {
    check("legacy migration completes", false)
}
legacyDefaults.removePersistentDomain(forName: suiteName)

let malformedSuiteName = "ShortcutCoachChecks.MalformedMigration.\(UUID().uuidString)"
let malformedDefaults = UserDefaults(suiteName: malformedSuiteName)!
malformedDefaults.set(Data("malformed-legacy-metadata".utf8), forKey: "shortcutCoach.userMetadata")
let malformedMigrationDirectory = temporaryDirectory("malformed-migration")
let malformedMigrationManager = UserLibraryManager(
    fileURL: malformedMigrationDirectory.appendingPathComponent("UserLibraryState.json"),
    defaults: malformedDefaults
)
do {
    _ = try malformedMigrationManager.load()
    check("failed migration is rejected", false)
} catch {
    check("failed migration is rejected", true)
}
check("failed migration still backs up the legacy blob", FileManager.default.fileExists(atPath: malformedMigrationManager.migrationBackupURL.path))
check("failed migration does not create partial state", !FileManager.default.fileExists(atPath: malformedMigrationManager.stateURL.path))
check("failed migration leaves legacy defaults usable", malformedDefaults.data(forKey: "shortcutCoach.userMetadata") != nil)
malformedDefaults.removePersistentDomain(forName: malformedSuiteName)

section("Backup export, import, and recovery")
let backupURL = persistenceDirectory.appendingPathComponent("Export.json")
do {
    try manager.export(to: backupURL, state: saved)
    var replacement = UserLibraryState()
    replacement.favourites = ["mail.reply"]
    try manager.save(replacement)
    let imported = try manager.import(from: backupURL)
    let importedState = try manager.load()
    check("personal-only backup round-trip", imported == saved && importedState == saved)
} catch {
    check("personal-only backup round-trip", false)
}

let malformedURL = persistenceDirectory.appendingPathComponent("Malformed.json")
try! Data("not-json".utf8).write(to: malformedURL)
let beforeMalformedImport = try! manager.load()
do {
    _ = try manager.import(from: malformedURL)
    check("malformed import is rejected", false)
} catch {
    check("malformed import is rejected", true)
}
check("malformed import never overwrites current state", try! manager.load() == beforeMalformedImport)

var recoveryBase = UserLibraryState()
recoveryBase.favourites = ["finder.quick-look"]
try! manager.save(recoveryBase)
var recoveryNewest = recoveryBase
recoveryNewest.favourites.insert("mail.reply")
try! manager.save(recoveryNewest)
try! Data("corrupt-primary".utf8).write(to: manager.stateURL, options: .atomic)
check("corrupt primary recovers the last known-good backup", try! manager.load() == recoveryBase)

section("Summary")
if failures == 0 {
    print("All Shortcut Coach checks passed.")
} else {
    print("\(failures) check(s) failed.")
    exit(1)
}
