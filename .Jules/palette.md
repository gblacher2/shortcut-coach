## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2024-05-18 - Missing Accessibility Labels on Icon-only Buttons with Help Modifiers
**Learning:** Sighted users benefit from `.help` tooltips on icon-only buttons, but without explicit `.accessibilityLabel` modifiers, VoiceOver may only announce "Button" or the SF Symbol name, making the UI inaccessible for screen reader users. SwiftUI does not automatically map `.help` strings to VoiceOver labels in all contexts.
**Action:** Always ensure both `.help` and `.accessibilityLabel` modifiers are present on custom icon-only buttons for comprehensive accessibility on macOS.
