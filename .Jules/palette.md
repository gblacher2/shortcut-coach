## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2024-05-19 - [Icon-only Buttons Accessibility]
**Learning:** In this SwiftUI codebase, icon-only buttons frequently use `.help` for visual tooltips but lack VoiceOver support. Both are required for complete accessibility.
**Action:** Always ensure explicit `.accessibilityLabel` modifiers are added alongside `.help` modifiers on all icon-only buttons.
