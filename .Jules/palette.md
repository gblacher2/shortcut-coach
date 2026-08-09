## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2024-10-26 - [Missing Accessibility Labels on Icon Buttons]
**Learning:** Icon-only buttons in this codebase often use `.help` for visual tooltips but omit `.accessibilityLabel` modifiers, making them inaccessible to VoiceOver users.
**Action:** Always ensure both `.help` (for mouse users) and explicit `.accessibilityLabel` modifiers (for VoiceOver support) are present on icon-only buttons.
