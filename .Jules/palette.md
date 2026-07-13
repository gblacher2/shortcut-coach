## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2024-07-13 - [SwiftUI Icon-only Button Accessibility]
**Learning:** Icon-only buttons in this codebase often use `.help` for visual tooltips but lack corresponding `.accessibilityLabel` modifiers, leading to poor VoiceOver support.
**Action:** Always ensure both `.help` (for mouse users) and explicit `.accessibilityLabel` modifiers (for VoiceOver support) are present on icon-only buttons.
