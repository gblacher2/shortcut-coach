## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2024-05-18 - [SwiftUI Accessibility]
**Learning:** In SwiftUI, `.help` modifiers on icon-only buttons provide tooltips for mouse users but do not automatically serve as accessibility labels for VoiceOver. Both `.help` and explicit `.accessibilityLabel` must be provided for complete a11y support on these components.
**Action:** Always append `.accessibilityLabel` alongside `.help` on icon-only buttons in SwiftUI views to ensure proper VoiceOver navigation.
