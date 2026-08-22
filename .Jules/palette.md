## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2024-05-18 - [Icon Button Accessibility]
**Learning:** Icon-only buttons using `.help()` tooltips in SwiftUI leave VoiceOver users without context. Both `.help()` and explicit `.accessibilityLabel()` modifiers are required.
**Action:** Always ensure `.accessibilityLabel` is added alongside `.help` on icon-only buttons for consistent UX across modalities.
