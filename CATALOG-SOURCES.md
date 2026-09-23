# Shortcut Coach catalog source ledger

Catalog version: `1.0.0` · Catalog schema: `1` · Verified: 2026-07-11 on macOS 26.5.1 (25F80)

The built-in catalog is immutable application data. Personal favourites, To Learn status, collections, notes, and recents are stored separately and are never written into the catalog.

## My Mac environment overlay

The My Mac library is a separate local environment snapshot, not part of the immutable app catalog. Its versioned resource is `Sources/ShortcutCoachCore/Resources/my-mac-environment.json` with format `shortcut-coach-environment/v1`. The audited 2026-07-12 snapshot contains 37 enabled bindings: 23 macOS system shortcuts and 14 personal Karabiner-Elements, Hammerspoon, and BetterStage controls. It records three explicit interception/conflict warnings and no unresolved bindings.

Evidence comes from Apple documentation, read-only macOS preference inspection, and the local configuration files for the three installed tools. Account identifiers, API keys, document contents, clipboard data, and unrelated preferences are excluded. The app never scans these tools or changes their settings at runtime. If this overlay is missing or rejected, the nine-app catalog remains fully usable.

| App | Entries | Evidence | Validated version | Stability notes |
| --- | ---: | --- | --- | --- |
| Google Chrome | 6 | [Chrome keyboard shortcuts — Google Chrome Help](https://support.google.com/chrome/answer/157179) | Chrome 150.0.7871.114 | Official macOS table. |
| ChatGPT | 5 | [ChatGPT macOS release notes](https://help.openai.com/en/articles/9703738-mac), [How to launch the Chat Bar](https://help.openai.com/en/articles/9295241) | Official documentation current on 2026-07-11 | Option-Space is customizable. Screenshot shortcuts can require ChatGPT screen-recording access and may vary by workspace/build. |
| Antigravity | 5 | Installed application menu read through macOS Accessibility menu attributes | Antigravity 2.2.1 | Version-sensitive. Only bindings exposed by the installed menu were included. |
| Pages | 6 | [Keyboard shortcuts for Pages on Mac — Apple Support](https://support.apple.com/guide/pages/keyboard-shortcuts-tanc0ffef022/mac) | Pages 14.4 | Apple notes that system/app shortcut customization can change bindings. |
| Finder | 6 | [Mac keyboard shortcuts — Apple Support](https://support.apple.com/102650) | macOS 26.5.1 | Command-Delete moves to Trash; it does not permanently erase. |
| Spotify | 6 | [Spotify keyboard shortcuts — Spotify Support](https://support.spotify.com/article/keyboard-shortcuts/) | Spotify 1.2.93.667 | Some unmodified keys depend on Spotify keyboard focus and the current view. |
| WhatsApp | 7 | Installed application menu read through macOS Accessibility menu attributes | WhatsApp 26.26.73 | Version-sensitive. Menu labels and modifier flags were read from the installed build. |
| Preview | 7 | [Keyboard shortcuts in Preview on Mac — Apple Support](https://support.apple.com/guide/preview/cpprvw0003/mac) | macOS 26.5.1 | The selected document type can affect availability. |
| Apple Mail | 8 | [Keyboard shortcuts in Mail on Mac — Apple Support](https://support.apple.com/guide/mail/mlhlb94f262b/mac) | macOS 26.5.1 | Apple notes that keyboard layout and app shortcut customization can change bindings. |

## Installed-menu evidence

Antigravity 2.2.1 exposed New Window (Shift-Command-N), Close Window (Command-W), Undo (Command-Z), Redo (Shift-Command-Z), and Reload (Command-R). The prior planning output proposed New Session, Quick Open, and Toggle Sidebar, but those bindings were not present in the inspected menu and were intentionally omitted.

WhatsApp 26.26.73 exposed New Chat (Command-N), New Group (Shift-Command-N), Search (Command-F), Search Chat (Option-Command-F), Previous Chat (Shift-Command-[), Next Chat (Shift-Command-]), and Settings (Command-,). Mute Chat and Mark as Unread were proposed by the planning output but were not present as shortcut-bearing menu items in the inspected build, so they were omitted.

## Catalog policy

- Each of the nine launch apps has 5–8 entries.
- IDs are stable and namespaced by app.
- Related IDs must resolve inside the same catalog.
- Ordered keys and display text must agree.
- Official documentation is preferred. Installed-menu evidence is used only where official shortcut documentation was unavailable.
- A shortcut is omitted when the binding cannot be substantiated.
