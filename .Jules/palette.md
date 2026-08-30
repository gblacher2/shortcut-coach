## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2024-05-18 - [Icon Button Accessibility]
**Learning:** In SwiftUI, while `.help()` provides tooltips for mouse users, explicit `.accessibilityLabel()` modifiers are crucial for screen readers on icon-only buttons to announce the intended action accurately.
**Action:** Always pair `.help()` with `.accessibilityLabel()` on icon-only interactive elements in SwiftUI.
