## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2024-05-18 - [Accessibility for SwiftUI Icon-Only Buttons]
**Learning:** Icon-only buttons in SwiftUI need explicit `.accessibilityLabel` modifiers for VoiceOver support, separate from their visual `.help` tooltips. This is similar to adding `aria-label` in web development.
**Action:** Always ensure both `.help` (for mouse users) and explicit `.accessibilityLabel` modifiers (for VoiceOver support) are present on icon-only buttons to improve screen reader accessibility.
