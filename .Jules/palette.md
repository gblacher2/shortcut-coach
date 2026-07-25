## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2024-07-25 - [Accessibility Labels for Icon Buttons]
**Learning:** Icon-only buttons in SwiftUI apps frequently use `.help()` for tooltips but often omit `.accessibilityLabel()`, which is crucial for screen reader users on macOS (VoiceOver).
**Action:** Always ensure both `.help` (for mouse users) and explicit `.accessibilityLabel` modifiers (for VoiceOver support) are present on icon-only components.
