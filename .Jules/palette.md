## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2026-07-21 - [Icon Button Accessibility]
**Learning:** SwiftUI's `.help()` modifier provides visual tooltips for mouse users but is insufficient for VoiceOver. Screen readers will often fall back to reading the raw symbol name (e.g., "arrow clockwise") if an explicit accessibility label is not provided.
**Action:** Always ensure both `.help` (for mouse users) and explicit `.accessibilityLabel` modifiers (for VoiceOver support) are present on icon-only buttons.
