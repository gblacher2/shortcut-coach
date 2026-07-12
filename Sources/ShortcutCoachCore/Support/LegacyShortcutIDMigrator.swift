import Foundation

/// Maps only legacy identifiers whose meaning and chord have an exact equivalent
/// in the current app or My Mac catalogs. Unmatched IDs remain untouched so a
/// migration never deletes personal information.
public enum LegacyShortcutIDMigrator {
    public static let exactMappings: [String: String] = [
        "karabiner-text-editing-fn-left-arrow-go-to-the-start-of-the-current-line": "karabiner.fn-left",
        "karabiner-text-editing-fn-right-arrow-go-to-the-end-of-the-current-line": "karabiner.fn-right",
        "karabiner-text-editing-fn-up-arrow-jump-to-the-top-of-the-document-or-page": "karabiner.fn-up",
        "karabiner-text-editing-fn-down-arrow-jump-to-the-bottom-of-the-document-or-page": "karabiner.fn-down",
        "karabiner-text-editing-fn-shift-left-arrow-select-text-back-to-the-start-of-the-line": "karabiner.fn-shift-left",
        "karabiner-text-editing-fn-shift-right-arrow-select-text-forward-to-the-end-of-the-line": "karabiner.fn-shift-right",
        "karabiner-text-editing-fn-shift-up-arrow-select-text-back-to-the-top-of-the-document": "karabiner.fn-shift-up",
        "karabiner-text-editing-fn-shift-down-arrow-select-text-forward-to-the-bottom-of-the-document": "karabiner.fn-shift-down",
        "karabiner-text-editing-command-y-redo": "karabiner.command-y-redo",
        "karabiner-text-editing-control-backspace-delete-the-previous-word": "karabiner.control-delete-word",
        "macos-setting-window-control-control-left-arrow-move-to-the-previous-space": "macos.symbolic-hotkey-79",
        "macos-setting-window-control-control-right-arrow-move-to-the-next-space": "macos.symbolic-hotkey-81",
        "macos-default-window-control-control-up-arrow-open-mission-control": "macos.mission-control",
        "macos-default-window-control-control-down-arrow-show-windows-for-the-current-app": "macos.app-expose",
        "macos-setting-input-control-space-select-the-previous-input-source": "macos.symbolic-hotkey-60",
        "macos-setting-input-control-option-space-select-the-next-input-source": "macos.symbolic-hotkey-61",
        "macos-default-window-control-fn-control-f-fill-the-current-window": "macos.tile-fill",
        "macos-default-window-control-fn-control-c-center-the-current-window": "macos.tile-center",
        "macos-default-window-control-fn-control-r-return-the-window-to-its-previous-size": "macos.tile-restore",
        "macos-default-window-control-fn-control-left-arrow-tile-window-to-the-left-half": "macos.tile-left",
        "macos-default-window-control-fn-control-right-arrow-tile-window-to-the-right-half": "macos.tile-right",
        "macos-default-window-control-fn-control-up-arrow-tile-window-to-the-top-half": "macos.tile-top",
        "macos-default-window-control-fn-control-down-arrow-tile-window-to-the-bottom-half": "macos.tile-bottom",
        "macos-default-window-control-fn-control-shift-left-arrow-arrange-windows-left-and-right": "macos.arrange-left-right",
        "macos-default-window-control-fn-control-shift-right-arrow-arrange-windows-right-and-left": "macos.arrange-right-left",
        "macos-default-window-control-fn-control-shift-up-arrow-arrange-windows-top-and-bottom": "macos.arrange-top-bottom",
        "macos-default-window-control-fn-control-shift-down-arrow-arrange-windows-bottom-and-top": "macos.arrange-bottom-top"
    ]

    public static func currentID(for id: String) -> String {
        exactMappings[id] ?? id
    }

    public static func migrate(_ state: UserLibraryState) -> UserLibraryState {
        var migrated = state
        migrated.favourites = Set(state.favourites.map(currentID))
        migrated.toLearn = Set(state.toLearn.map(currentID))
        migrated.recents = deduplicating(state.recents.map(currentID))

        var migratedNotes: [String: String] = [:]
        for (id, note) in state.notes {
            let mappedID = currentID(for: id)
            if migratedNotes[mappedID] == nil || id == mappedID {
                migratedNotes[mappedID] = note
            }
        }
        migrated.notes = migratedNotes

        migrated.collections = state.collections.mapValues { collection in
            var migratedCollection = collection
            migratedCollection.shortcutIDs = Set(collection.shortcutIDs.map(currentID))
            return migratedCollection
        }
        migrated.practiceSnapshot.practicedIDs = Set(state.practiceSnapshot.practicedIDs.map(currentID))
        return migrated
    }

    private static func deduplicating(_ IDs: [String]) -> [String] {
        var seen = Set<String>()
        return IDs.filter { seen.insert($0).inserted }
    }
}

