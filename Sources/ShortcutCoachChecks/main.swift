import Foundation
import ShortcutCoachCore

private var failures = 0

@MainActor
private func check(_ name: String, _ condition: @autoclosure () -> Bool) {
    if condition() {
        print("  ✓ \(name)")
    } else {
        failures += 1
        print("  ✗ \(name)")
    }
}

private func section(_ title: String) {
    print("\n\(title)")
}

private func temporaryDirectory(_ name: String) -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("ShortcutCoachChecks-\(name)-\(UUID().uuidString)", isDirectory: true)
    try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func JSONDictionary(from data: Data) -> [String: Any] {
    try! JSONSerialization.jsonObject(with: data) as! [String: Any]
}

private func JSONData(from dictionary: [String: Any]) -> Data {
    try! JSONSerialization.data(withJSONObject: dictionary, options: [.sortedKeys])
}

private func mutatedJSON(
    from original: Data,
    _ mutation: (inout [String: Any]) -> Void
) -> Data {
    var dictionary = JSONDictionary(from: original)
    mutation(&dictionary)
    return JSONData(from: dictionary)
}

@MainActor
private func checkRejectedEnvironment(
    _ name: String,
    data: Data,
    loader: CatalogLoader
) {
    do {
        let loaded = try loader.load(environment: .data(data))
        let isRejected: Bool
        if case .rejected = loaded.environmentState {
            isRejected = true
        } else {
            isRejected = false
        }
        check("\(name) is rejected", isRejected)
        check("\(name) preserves 56 base shortcuts", loaded.catalog.shortcuts.count == 56)
        check("\(name) merges no My Mac shortcuts", loaded.catalog.shortcuts.allSatisfy { $0.appID != "my-mac" })
        check("\(name) exposes no rejected conflict metadata", loaded.environmentConflictsByID.isEmpty)
    } catch {
        check("\(name) is nonfatal to the base catalog", false)
    }
}

@MainActor
private func checkFatalBaseCatalog(
    _ name: String,
    data: Data,
    loader: CatalogLoader
) {
    do {
        _ = try loader.load(base: .data(data), environment: .missing)
        check(name, false)
    } catch {
        check(name, true)
    }
}

private func recommendationMutation(
    _ root: inout [String: Any],
    group: String,
    mutate: (inout [[String: Any]]) -> Void
) {
    var changes = root["recommendedShortcutCoachChanges"] as! [String: Any]
    var recommendations = changes[group] as! [[String: Any]]
    mutate(&recommendations)
    changes[group] = recommendations
    root["recommendedShortcutCoachChanges"] = changes
}

private func bindingMutation(
    _ root: inout [String: Any],
    index: Int = 0,
    mutate: (inout [String: Any]) -> Void
) {
    var bindings = root["bindings"] as! [[String: Any]]
    var binding = bindings[index]
    mutate(&binding)
    bindings[index] = binding
    root["bindings"] = bindings
}

let loader = CatalogLoader()
let validEnvironmentData: Data
let loaded: LoadedCatalog

do {
    validEnvironmentData = try loader.bundledEnvironmentData()
    loaded = try loader.load()
} catch {
    print("Catalog failed to load: \(error)")
    exit(1)
}

let catalog = loaded.catalog
let entries = catalog.shortcuts
let entryIDs = Set(entries.map(\.id))
let appIDs = Set(catalog.apps.map(\.id))
let myMacEntries = entries.filter { $0.appID == "my-mac" }
let baseOnly = try! loader.load(environment: .missing)
let baseData = try! JSONEncoder().encode(baseOnly.catalog)

section("Immutable app catalog integrity")
check("base catalog schema version is 1", catalog.schemaVersion == 1)
check("catalog version is populated", !catalog.catalogVersion.isEmpty)
check("exactly nine supported apps", catalog.apps.count == 9 && appIDs == Set(SupportedApp.launchApps.map(\.id)))
check("immutable catalog contains exactly 56 curated shortcuts", baseOnly.catalog.shortcuts.count == 56)
check("every app has 5–8 shortcuts", catalog.apps.allSatisfy { app in
    (5...8).contains(baseOnly.catalog.shortcuts.filter { $0.appID == app.id }.count)
})
check("all combined shortcut IDs are unique", entryIDs.count == entries.count)
check("all immutable entries reference supported apps", baseOnly.catalog.shortcuts.allSatisfy { appIDs.contains($0.appID) })
check("all immutable ordered keys match display text", baseOnly.catalog.shortcuts.allSatisfy {
    !$0.keys.isEmpty && $0.displayText == $0.keys.joined(separator: " + ")
})
check("all immutable related IDs resolve", baseOnly.catalog.shortcuts.allSatisfy { entry in
    entry.relatedIDs.allSatisfy { relatedID in
        baseOnly.catalog.shortcuts.contains { $0.id == relatedID }
    }
})
check("official immutable sources are HTTPS URLs", baseOnly.catalog.shortcuts.allSatisfy { entry in
    guard entry.sourceReference.kind == .officialDocumentation else { return true }
    guard
        let rawURL = entry.sourceReference.url,
        let URL = URL(string: rawURL)
    else { return false }
    return URL.scheme == "https" && URL.host != nil
})
check("installed-menu evidence is limited to Antigravity and WhatsApp", baseOnly.catalog.shortcuts
    .filter { $0.sourceReference.kind == .installedAppMenu }
    .allSatisfy { $0.appID == "antigravity" || $0.appID == "whatsapp" })

section("Fatal base-catalog validation")
checkFatalBaseCatalog("malformed base catalog is fatal", data: Data("{".utf8), loader: loader)
checkFatalBaseCatalog(
    "unsupported base schema is fatal",
    data: mutatedJSON(from: baseData) { $0["schemaVersion"] = 99 },
    loader: loader
)
checkFatalBaseCatalog(
    "duplicate base shortcut ID is fatal",
    data: mutatedJSON(from: baseData) { root in
        var shortcuts = root["shortcuts"] as! [[String: Any]]
        shortcuts.append(shortcuts[0])
        root["shortcuts"] = shortcuts
    },
    loader: loader
)
checkFatalBaseCatalog(
    "dangling base related ID is fatal",
    data: mutatedJSON(from: baseData) { root in
        var shortcuts = root["shortcuts"] as! [[String: Any]]
        shortcuts[0]["relatedIDs"] = ["missing.shortcut"]
        root["shortcuts"] = shortcuts
    },
    loader: loader
)
checkFatalBaseCatalog(
    "base display-text mismatch is fatal",
    data: mutatedJSON(from: baseData) { root in
        var shortcuts = root["shortcuts"] as! [[String: Any]]
        shortcuts[0]["displayText"] = "Wrong"
        root["shortcuts"] = shortcuts
    },
    loader: loader
)
checkFatalBaseCatalog(
    "invalid official source URL is fatal",
    data: mutatedJSON(from: baseData) { root in
        var shortcuts = root["shortcuts"] as! [[String: Any]]
        let officialIndex = shortcuts.firstIndex { shortcut in
            guard let source = shortcut["source"] as? [String: Any] else { return false }
            return source["kind"] as? String == "official-documentation"
        }!
        var source = shortcuts[officialIndex]["source"] as! [String: Any]
        source["url"] = "http://not-secure.invalid"
        shortcuts[officialIndex]["source"] = source
        root["shortcuts"] = shortcuts
    },
    loader: loader
)

section("Valid My Mac environment contract")
check("environment state is loaded", loaded.environmentState == .loaded)
check("combined catalog contains 56 app plus 37 My Mac shortcuts", entries.count == 93)
check("exactly 37 My Mac entries load", myMacEntries.count == 37)
check("environment catalog retains zero unresolved records", loaded.environmentCatalog?.unresolved.isEmpty == true)
check("macOS System classification has 23 records", myMacEntries.filter { $0.environmentClassification == .add }.count == 23)
check("Personal Setup classification has 14 records", myMacEntries.filter {
    $0.environmentClassification == .keepSeparateFromBuiltInCatalog
}.count == 14)
check("audited default statuses remain separate from classifications", myMacEntries.allSatisfy { entry in
    guard let classification = entry.environmentClassification else { return false }
    switch classification {
    case .add: return entry.defaultStatus == "system-configured" || entry.defaultStatus == "system-default"
    case .keepSeparateFromBuiltInCatalog: return entry.defaultStatus == "custom"
    case .update, .omit: return false
    }
})
check("environment entries preserve scope, confidence, and output metadata", myMacEntries.allSatisfy {
    $0.environmentScope == "global"
        && $0.environmentConfidence != nil
        && $0.outputType != nil
        && $0.outputSummary?.isEmpty == false
        && $0.outputKeys != nil
})
check("all 37 My Mac display texts match ordered keys", myMacEntries.allSatisfy {
    $0.displayText == $0.keys.joined(separator: " + ")
})
check("official My Mac sources are clickable HTTPS links", myMacEntries
    .filter { $0.sourceReference.kind == .officialDocumentation }
    .allSatisfy { entry in
        guard let rawURL = entry.sourceReference.url, let URL = URL(string: rawURL) else { return false }
        return URL.scheme == "https" && URL.host != nil
    })
check("local My Mac sources are not installed-menu evidence", myMacEntries
    .filter { $0.sourceReference.kind != .officialDocumentation }
    .allSatisfy { $0.sourceReference.kind == .systemPreference || $0.sourceReference.kind == .toolConfiguration })
check("When-to-use guidance is distinct from output", myMacEntries.allSatisfy {
    $0.guidance != $0.outputSummary && $0.guidance.hasPrefix("Use this")
})
check("three stable conflicts are retained", loaded.environmentConflictsByID.count == 3)
check("conflict metadata resolves on exactly four affected bindings", loaded.environmentConflictsByBindingID
    .filter { !$0.value.isEmpty }.count == 4)
check("entry conflict IDs remain stable IDs", myMacEntries
    .flatMap { $0.conflictIDs ?? [] }
    .allSatisfy { loaded.environmentConflictsByID[$0] != nil })
check("category counts are 17 window, 6 spaces/mission, 12 text, 2 input", 
    myMacEntries.filter { $0.category == "window-management" }.count == 17
        && myMacEntries.filter { $0.category == "spaces" || $0.category == "mission-control" }.count == 6
        && myMacEntries.filter { $0.category == "text-editing" }.count == 12
        && myMacEntries.filter { $0.category == "input-sources" }.count == 2)

section("Missing and unreadable environment isolation")
do {
    let missing = try loader.load(environment: .missing)
    check("explicit missing state is reported", missing.environmentState == .missing)
    check("missing environment preserves exactly 56 base shortcuts", missing.catalog.shortcuts.count == 56)
    check("missing environment merges no My Mac shortcuts", missing.catalog.shortcuts.allSatisfy { $0.appID != "my-mac" })
} catch {
    check("missing environment remains nonfatal", false)
}
do {
    let missingURL = temporaryDirectory("missing-environment").appendingPathComponent("Absent.json")
    let unreadable = try loader.load(environment: .url(missingURL))
    let rejected: Bool
    if case .rejected = unreadable.environmentState { rejected = true } else { rejected = false }
    check("unreadable environment URL is rejected", rejected)
    check("unreadable environment URL preserves base catalog", unreadable.catalog.shortcuts.count == 56)
} catch {
    check("unreadable environment URL remains nonfatal", false)
}

section("Environment mutation and fallback matrix")
checkRejectedEnvironment("malformed JSON", data: Data("{".utf8), loader: loader)
checkRejectedEnvironment(
    "wrong environment format",
    data: mutatedJSON(from: validEnvironmentData) { $0["format"] = "shortcut-coach-environment/v999" },
    loader: loader
)
checkRejectedEnvironment(
    "unsupported environment schema",
    data: mutatedJSON(from: validEnvironmentData) { $0["schemaVersion"] = 99 },
    loader: loader
)
checkRejectedEnvironment(
    "unresolved environment record",
    data: mutatedJSON(from: validEnvironmentData) { $0["unresolved"] = [["id": "opaque-record"]] },
    loader: loader
)
checkRejectedEnvironment(
    "duplicate binding ID",
    data: mutatedJSON(from: validEnvironmentData) { root in
        var bindings = root["bindings"] as! [[String: Any]]
        bindings.append(bindings[0])
        root["bindings"] = bindings
    },
    loader: loader
)
checkRejectedEnvironment(
    "duplicate conflict ID",
    data: mutatedJSON(from: validEnvironmentData) { root in
        var conflicts = root["conflicts"] as! [[String: Any]]
        conflicts.append(conflicts[0])
        root["conflicts"] = conflicts
    },
    loader: loader
)
for group in ["add", "update", "keepSeparateFromBuiltInCatalog", "omit"] {
    let duplicated = mutatedJSON(from: validEnvironmentData) { root in
        recommendationMutation(&root, group: group) { recommendations in
            let seed = recommendations.first
                ?? ["bindingID": "karabiner.fn-left", "reason": "Mutation fixture"]
            recommendations.append(seed)
            recommendations.append(seed)
        }
    }
    checkRejectedEnvironment("duplicate \(group) recommendation", data: duplicated, loader: loader)

    let dangling = mutatedJSON(from: validEnvironmentData) { root in
        recommendationMutation(&root, group: group) { recommendations in
            recommendations.append(["bindingID": "missing.binding", "reason": "Mutation fixture"])
        }
    }
    checkRejectedEnvironment("dangling \(group) recommendation", data: dangling, loader: loader)
}
checkRejectedEnvironment(
    "dangling conflict reference",
    data: mutatedJSON(from: validEnvironmentData) { root in
        bindingMutation(&root) { $0["conflictIDs"] = ["conflict.missing"] }
    },
    loader: loader
)
checkRejectedEnvironment(
    "nonreciprocal conflict mapping",
    data: mutatedJSON(from: validEnvironmentData) { root in
        var conflicts = root["conflicts"] as! [[String: Any]]
        conflicts[0]["bindingIDs"] = []
        root["conflicts"] = conflicts
    },
    loader: loader
)
checkRejectedEnvironment(
    "overlapping classifications",
    data: mutatedJSON(from: validEnvironmentData) { root in
        let changes = root["recommendedShortcutCoachChanges"] as! [String: Any]
        let addition = (changes["add"] as! [[String: Any]])[0]
        recommendationMutation(&root, group: "keepSeparateFromBuiltInCatalog") { $0.append(addition) }
    },
    loader: loader
)
checkRejectedEnvironment(
    "incomplete enabled classification",
    data: mutatedJSON(from: validEnvironmentData) { root in
        recommendationMutation(&root, group: "add") { _ = $0.removeFirst() }
    },
    loader: loader
)
checkRejectedEnvironment(
    "classified disabled binding",
    data: mutatedJSON(from: validEnvironmentData) { root in
        bindingMutation(&root) { $0["enabled"] = false }
    },
    loader: loader
)
for field in ["action", "owner", "category", "scope", "source", "sourceType", "confidence"] {
    let blank = mutatedJSON(from: validEnvironmentData) { root in
        bindingMutation(&root) { $0[field] = " " }
    }
    checkRejectedEnvironment("blank binding \(field)", data: blank, loader: loader)
}
checkRejectedEnvironment(
    "blank binding ID",
    data: mutatedJSON(from: validEnvironmentData) { root in
        let oldID = (root["bindings"] as! [[String: Any]])[0]["id"] as! String
        bindingMutation(&root) { $0["id"] = " " }
        var changes = root["recommendedShortcutCoachChanges"] as! [String: Any]
        for group in ["add", "update", "keepSeparateFromBuiltInCatalog", "omit"] {
            var recommendations = changes[group] as! [[String: Any]]
            for index in recommendations.indices where recommendations[index]["bindingID"] as? String == oldID {
                recommendations[index]["bindingID"] = " "
            }
            changes[group] = recommendations
        }
        root["recommendedShortcutCoachChanges"] = changes
    },
    loader: loader
)
checkRejectedEnvironment(
    "blank output summary",
    data: mutatedJSON(from: validEnvironmentData) { root in
        bindingMutation(&root) { binding in
            var output = binding["output"] as! [String: Any]
            output["summary"] = " "
            binding["output"] = output
        }
    },
    loader: loader
)
checkRejectedEnvironment(
    "invalid output type",
    data: mutatedJSON(from: validEnvironmentData) { root in
        bindingMutation(&root) { binding in
            var output = binding["output"] as! [String: Any]
            output["type"] = "unknown"
            binding["output"] = output
        }
    },
    loader: loader
)
checkRejectedEnvironment(
    "key-chord output without keys",
    data: mutatedJSON(from: validEnvironmentData) { root in
        bindingMutation(&root) { binding in
            var output = binding["output"] as! [String: Any]
            output["keys"] = []
            binding["output"] = output
        }
    },
    loader: loader
)
checkRejectedEnvironment(
    "display text mismatch",
    data: mutatedJSON(from: validEnvironmentData) { root in
        bindingMutation(&root) { $0["displayText"] = "Wrong" }
    },
    loader: loader
)
checkRejectedEnvironment(
    "invalid official source URL",
    data: mutatedJSON(from: validEnvironmentData) { root in
        var bindings = root["bindings"] as! [[String: Any]]
        let index = bindings.firstIndex { $0["sourceType"] as? String == "official-documentation" }!
        bindings[index]["source"] = "http://not-secure.invalid"
        root["bindings"] = bindings
    },
    loader: loader
)
for field in ["summary", "evidence", "recommendedNonDestructiveTest"] {
    let blank = mutatedJSON(from: validEnvironmentData) { root in
        var conflicts = root["conflicts"] as! [[String: Any]]
        conflicts[0][field] = " "
        root["conflicts"] = conflicts
    }
    checkRejectedEnvironment("blank conflict \(field)", data: blank, loader: loader)
}
checkRejectedEnvironment(
    "blank recommendation reason",
    data: mutatedJSON(from: validEnvironmentData) { root in
        recommendationMutation(&root, group: "add") { $0[0]["reason"] = " " }
    },
    loader: loader
)
checkRejectedEnvironment(
    "cross-catalog ID collision",
    data: mutatedJSON(from: validEnvironmentData) { root in
        var bindings = root["bindings"] as! [[String: Any]]
        let oldID = bindings[0]["id"] as! String
        bindings[0]["id"] = "chrome.new-tab"
        root["bindings"] = bindings

        var changes = root["recommendedShortcutCoachChanges"] as! [String: Any]
        for group in ["add", "update", "keepSeparateFromBuiltInCatalog", "omit"] {
            var recommendations = changes[group] as! [[String: Any]]
            for index in recommendations.indices where recommendations[index]["bindingID"] as? String == oldID {
                recommendations[index]["bindingID"] = "chrome.new-tab"
            }
            changes[group] = recommendations
        }
        root["recommendedShortcutCoachChanges"] = changes
    },
    loader: loader
)

section("Shared search fields and scope composition")
let search = ShortcutSearchService()
var searchState = UserLibraryState()

@MainActor
func myMacResults(_ text: String) -> [ShortcutCatalogEntry] {
    search.results(
        in: entries,
        query: ShortcutQueryScopeAdapter.fullWindow(text: text, sidebar: .app("my-mac")),
        userState: searchState
    )
}

check("My Mac action search matches", myMacResults("move beginning line").contains { $0.id == "karabiner.fn-left" })
check("My Mac owner search matches", myMacResults("Karabiner-Elements").count == 10)
check("My Mac readable chord search matches", myMacResults("command scroll up").contains {
    $0.id == "hammerspoon.command-scroll-up"
})
check("My Mac category search matches", myMacResults("input sources").count == 2)
check("My Mac output summary search matches", myMacResults("emit command left arrow").contains {
    $0.id == "karabiner.fn-left"
})
check("My Mac output-key search matches", myMacResults("command left arrow").contains { $0.id == "karabiner.fn-left" })
check("My Mac caveat search matches", myMacResults("receiving app controls").count == 10)
check("My Mac source search matches", myMacResults("karabiner.json").count == 10)
check("My Mac source URL search matches", myMacResults("mchl9674d0b0").count == 15)
check("My Mac confidence search matches", myMacResults("official").count == 17)
check("My Mac default-status search matches", myMacResults("system-configured").count == 6)
check("My Mac classification search matches", myMacResults("keepSeparateFromBuiltInCatalog").count == 14)
check("existing action search remains correct", search.results(
    in: entries,
    query: ShortcutSearchQuery(text: "reopen last closed"),
    userState: searchState
).map(\.id) == ["chrome.reopen-tab"])
check("existing app search remains correct", search.results(
    in: entries,
    query: ShortcutSearchQuery(text: "Google Chrome"),
    userState: searchState
).count == 6)
check("existing menu-path search remains correct", search.results(
    in: entries,
    query: ShortcutSearchQuery(text: "View Developer Developer Tools"),
    userState: searchState
).map(\.id) == ["chrome.developer-tools"])

let scopeCases: [(String, SidebarSelection, Int, String)] = [
    ("All My Mac", .app("my-mac"), 37, "command"),
    ("macOS System", .myMacSystem, 23, "window"),
    ("Personal Setup", .myMacPersonal, 14, "Karabiner"),
    ("Window Management", .category("window-management"), 17, "left"),
    ("Spaces & Mission Control", .category("spaces-mission-control"), 6, "space"),
    ("Text Editing", .category("text-editing"), 12, "select"),
    ("Input Sources", .category("input-sources"), 2, "source")
]
for (name, sidebar, expectedCount, term) in scopeCases {
    let emptyQuery = ShortcutQueryScopeAdapter.fullWindow(sidebar: sidebar)
    let scoped = search.results(in: entries, query: emptyQuery, userState: searchState)
    check("\(name) has exact count \(expectedCount)", scoped.count == expectedCount)
    check("\(name) is restricted to My Mac", scoped.allSatisfy { $0.appID == "my-mac" })

    let composedQuery = ShortcutQueryScopeAdapter.fullWindow(text: term, sidebar: sidebar)
    let composed = search.results(in: entries, query: composedQuery, userState: searchState)
    check("\(name) composes with text search", !composed.isEmpty && composed.allSatisfy { $0.appID == "my-mac" })

    let menuQuery: ShortcutSearchQuery
    if sidebar == .app("my-mac") {
        menuQuery = ShortcutQueryScopeAdapter.menuBar(text: term, appID: "my-mac")
    } else {
        menuQuery = ShortcutQueryScopeAdapter.menuBar(text: term, appID: "my-mac", section: sidebar)
    }
    check("\(name) full-window/menu queries are identical", composedQuery == menuQuery)
    let menuResults = search.results(in: entries, query: menuQuery, userState: searchState)
    check("\(name) full-window/menu ordered IDs match", composed.map(\.id) == menuResults.map(\.id))
}

for appID in SupportedApp.launchApps.map(\.id) + ["my-mac"] {
    let fullQuery = ShortcutQueryScopeAdapter.fullWindow(text: "command", sidebar: .app(appID))
    let menuQuery = ShortcutQueryScopeAdapter.menuBar(text: "command", appID: appID)
    check("\(appID) full-window/menu app query adapter matches", fullQuery == menuQuery)
    check("\(appID) full-window/menu ordered search matches", search.results(
        in: entries, query: fullQuery, userState: searchState
    ).map(\.id) == search.results(
        in: entries, query: menuQuery, userState: searchState
    ).map(\.id))
}

var duplicateRecentState = UserLibraryState()
duplicateRecentState.recents = ["mail.reply", "chrome.reopen-tab", "mail.reply"]
check("duplicate recents filtering is safe and preserves first occurrence", search.results(
    in: entries,
    query: ShortcutSearchQuery(sidebar: .recentlyViewed),
    userState: duplicateRecentState
).map(\.id) == ["mail.reply", "chrome.reopen-tab"])

section("Personal state with My Mac stable IDs")
let myMacID = "karabiner.command-y-redo"
let persistenceDirectory = temporaryDirectory("persistence")
let stateURL = persistenceDirectory.appendingPathComponent("UserLibraryState.json")
let manager = UserLibraryManager(fileURL: stateURL)
var saved = UserLibraryState()
saved.favourites = [myMacID, "chrome.new-tab"]
saved.toLearn = [myMacID, "pages.comment"]
saved.notes[myMacID] = "Remember the global Chrome History interception."
saved.collections["daily"] = UserCollection(
    id: "daily",
    name: "Daily",
    shortcutIDs: [myMacID, "chrome.new-tab"]
)
saved.recents = [myMacID, "chrome.new-tab"]
do {
    try manager.save(saved)
    let reloaded = try manager.load()
    check("My Mac favourite survives save/load", reloaded.favourites.contains(myMacID))
    check("My Mac To Learn survives save/load", reloaded.toLearn.contains(myMacID))
    check("My Mac note survives save/load", reloaded.notes[myMacID] == saved.notes[myMacID])
    check("My Mac collection membership survives save/load", reloaded.collections["daily"]?.shortcutIDs.contains(myMacID) == true)
    check("My Mac recent survives save/load", reloaded.recents.first == myMacID)
} catch {
    check("personal state save/load succeeds", false)
}

let backupURL = persistenceDirectory.appendingPathComponent("Export.json")
do {
    try manager.export(to: backupURL, state: saved)
    let backupData = try Data(contentsOf: backupURL)
    let backupText = String(decoding: backupData, as: UTF8.self)
    let backupObject = JSONDictionary(from: backupData)
    check("backup format is personal-state only", backupObject["format"] as? String == UserLibraryBackup.format)
    check("backup contains no environment catalog payload", !backupText.contains("shortcut-coach-environment/v1")
        && !backupText.contains("\"bindings\"")
        && !backupText.contains("\"conflicts\""))

    var replacement = UserLibraryState()
    replacement.favourites = ["mail.reply"]
    try manager.save(replacement)
    let imported = try manager.import(from: backupURL)
    let restored = try manager.load()
    check("valid import restores My Mac favourite", imported.favourites.contains(myMacID))
    check("valid import restores all My Mac personal fields", restored == saved)
} catch {
    check("personal-state export/import succeeds", false)
}

let malformedBackupURL = persistenceDirectory.appendingPathComponent("Malformed.json")
try! Data("not-json".utf8).write(to: malformedBackupURL)
let beforeMalformedImport = try! manager.load()
do {
    _ = try manager.import(from: malformedBackupURL)
    check("malformed import is rejected", false)
} catch {
    check("malformed import is rejected", true)
}
check("malformed import never overwrites My Mac state", try! manager.load() == beforeMalformedImport)

let duplicateRecentsBackupURL = persistenceDirectory.appendingPathComponent("DuplicateRecents.json")
var duplicateRecentsState = saved
duplicateRecentsState.recents = [myMacID, myMacID]
let duplicateRecentsBackup = UserLibraryBackup(state: duplicateRecentsState)
let duplicateRecentsEncoder = JSONEncoder()
duplicateRecentsEncoder.dateEncodingStrategy = .iso8601
try! duplicateRecentsEncoder.encode(duplicateRecentsBackup).write(to: duplicateRecentsBackupURL)
let beforeDuplicateImport = try! manager.load()
do {
    _ = try manager.import(from: duplicateRecentsBackupURL)
    check("duplicate-recents import is rejected", false)
} catch {
    check("duplicate-recents import is rejected", true)
}
check("duplicate-recents import never overwrites current state", try! manager.load() == beforeDuplicateImport)

let recoveryDirectory = temporaryDirectory("recovery")
let recoveryManager = UserLibraryManager(fileURL: recoveryDirectory.appendingPathComponent("State.json"))
var recoveryBase = saved
recoveryBase.favourites = [myMacID]
try! recoveryManager.save(recoveryBase)
var recoveryNewest = recoveryBase
recoveryNewest.favourites.insert("mail.reply")
try! recoveryManager.save(recoveryNewest)
try! Data("corrupt-primary".utf8).write(to: recoveryManager.stateURL, options: .atomic)
check("corrupt primary recovers My Mac state from last known-good backup", try! recoveryManager.load() == recoveryBase)

section("One-time legacy migration and exact ID preservation")
let oldKarabinerID = "karabiner-text-editing-fn-left-arrow-go-to-the-start-of-the-current-line"
let oldTilingID = "macos-default-window-control-fn-control-left-arrow-tile-window-to-the-left-half"
let unmatchedLegacyID = "macos-default-screenshots-command-shift-3-save-a-screenshot-of-the-whole-screen"
check("legacy exact-ID mapping contains 27 reviewed equivalents", LegacyShortcutIDMigrator.exactMappings.count == 27)

struct LegacyMetadata: Codable {
    let favourites: Set<String>
    let toLearn: Set<String>
    let recentlyViewed: [String]
    let collections: [String: [String]]
}

let suiteName = "ShortcutCoachChecks.Legacy.\(UUID().uuidString)"
let legacyDefaults = UserDefaults(suiteName: suiteName)!
let legacySnapshot = DailyPracticeSnapshot(
    dayKey: "2026-07-11",
    practicedIDs: [oldKarabinerID, unmatchedLegacyID]
)
let legacyMetadata = LegacyMetadata(
    favourites: [oldKarabinerID, "karabiner.fn-left", unmatchedLegacyID],
    toLearn: [oldTilingID],
    recentlyViewed: [oldKarabinerID, "karabiner.fn-left", unmatchedLegacyID],
    collections: ["Legacy": [oldKarabinerID, oldTilingID, unmatchedLegacyID]]
)
let legacyPracticeData = try! JSONEncoder().encode(legacySnapshot)
let legacyMetadataData = try! JSONEncoder().encode(legacyMetadata)
legacyDefaults.set(legacyPracticeData, forKey: "shortcutCoach.dailyPracticeSnapshot")
legacyDefaults.set(legacyMetadataData, forKey: "shortcutCoach.userMetadata")

let migrationDirectory = temporaryDirectory("migration")
let migrationManager = UserLibraryManager(
    fileURL: migrationDirectory.appendingPathComponent("UserLibraryState.json"),
    defaults: legacyDefaults
)
do {
    let migrated = try migrationManager.load()
    check("real legacy favourite maps to current stable ID", migrated.favourites.contains("karabiner.fn-left"))
    check("mapped/current favourite collision deduplicates", migrated.favourites.filter { $0 == "karabiner.fn-left" }.count == 1)
    check("real legacy To Learn maps to current stable ID", migrated.toLearn.contains("macos.tile-left"))
    check("mapped recents deduplicate while preserving first order", migrated.recents == ["karabiner.fn-left", unmatchedLegacyID])
    check("legacy collection IDs migrate", migrated.collections.values.first?.shortcutIDs.contains("macos.tile-left") == true)
    check("legacy practice IDs migrate", migrated.practiceSnapshot.practicedIDs.contains("karabiner.fn-left"))
    check("unmatched legacy IDs remain verbatim", migrated.favourites.contains(unmatchedLegacyID)
        && migrated.practiceSnapshot.practicedIDs.contains(unmatchedLegacyID))
    check("migration creates exact legacy backup first", FileManager.default.fileExists(atPath: migrationManager.migrationBackupURL.path))

    let backupObject = JSONDictionary(from: try Data(contentsOf: migrationManager.migrationBackupURL))
    let backedPractice = Data(base64Encoded: backupObject["practiceData"] as! String)
    let backedMetadata = Data(base64Encoded: backupObject["metadataData"] as! String)
    check("migration backup preserves exact practice blob", backedPractice == legacyPracticeData)
    check("migration backup preserves exact metadata blob", backedMetadata == legacyMetadataData)
    check("migration leaves legacy defaults untouched", legacyDefaults.data(forKey: "shortcutCoach.userMetadata") == legacyMetadataData)
} catch {
    check("real legacy migration succeeds", false)
}
legacyDefaults.removePersistentDomain(forName: suiteName)

let malformedPracticeSuite = "ShortcutCoachChecks.MalformedPractice.\(UUID().uuidString)"
let malformedPracticeDefaults = UserDefaults(suiteName: malformedPracticeSuite)!
let malformedPracticeData = Data("malformed-practice".utf8)
malformedPracticeDefaults.set(malformedPracticeData, forKey: "shortcutCoach.dailyPracticeSnapshot")
let malformedPracticeDirectory = temporaryDirectory("malformed-practice")
let malformedPracticeManager = UserLibraryManager(
    fileURL: malformedPracticeDirectory.appendingPathComponent("State.json"),
    defaults: malformedPracticeDefaults
)
do {
    _ = try malformedPracticeManager.load()
    check("malformed legacy practice is rejected", false)
} catch {
    check("malformed legacy practice is rejected", true)
}
check("malformed practice is backed up before rejection", FileManager.default.fileExists(
    atPath: malformedPracticeManager.migrationBackupURL.path
))
check("malformed practice creates no partial state", !FileManager.default.fileExists(
    atPath: malformedPracticeManager.stateURL.path
))
check("malformed practice remains usable in legacy defaults", malformedPracticeDefaults.data(
    forKey: "shortcutCoach.dailyPracticeSnapshot"
) == malformedPracticeData)
malformedPracticeDefaults.removePersistentDomain(forName: malformedPracticeSuite)

let malformedMetadataSuite = "ShortcutCoachChecks.MalformedMetadata.\(UUID().uuidString)"
let malformedMetadataDefaults = UserDefaults(suiteName: malformedMetadataSuite)!
let malformedMetadataData = Data("malformed-metadata".utf8)
malformedMetadataDefaults.set(malformedMetadataData, forKey: "shortcutCoach.userMetadata")
let malformedMetadataDirectory = temporaryDirectory("malformed-metadata")
let malformedMetadataManager = UserLibraryManager(
    fileURL: malformedMetadataDirectory.appendingPathComponent("State.json"),
    defaults: malformedMetadataDefaults
)
do {
    _ = try malformedMetadataManager.load()
    check("malformed legacy metadata is rejected", false)
} catch {
    check("malformed legacy metadata is rejected", true)
}
check("malformed metadata is backed up before rejection", FileManager.default.fileExists(
    atPath: malformedMetadataManager.migrationBackupURL.path
))
check("malformed metadata creates no partial state", !FileManager.default.fileExists(
    atPath: malformedMetadataManager.stateURL.path
))
check("malformed metadata remains usable in legacy defaults", malformedMetadataDefaults.data(
    forKey: "shortcutCoach.userMetadata"
) == malformedMetadataData)
malformedMetadataDefaults.removePersistentDomain(forName: malformedMetadataSuite)

section("Summary")
if failures == 0 {
    print("All Shortcut Coach checks passed.")
} else {
    print("\(failures) check(s) failed.")
    exit(1)
}
