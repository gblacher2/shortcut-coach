## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2024-10-25 - [Icon-Only Button Accessibility]
**Learning:** Icon-only buttons in SwiftUI using `.help` for visual tooltips are not automatically read by VoiceOver. Both are needed for complete accessibility.
**Action:** Always ensure both `.help` and explicit `.accessibilityLabel` modifiers are present on icon-only buttons for VoiceOver support.
