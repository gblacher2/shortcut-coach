## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2024-05-18 - [Icon-Only Button Accessibility]
**Learning:** Icon-only buttons often use `.help` for visual tooltips, but VoiceOver requires explicit `.accessibilityLabel` modifiers for screen reader support.
**Action:** Always ensure both `.help` and `.accessibilityLabel` modifiers are present on icon-only buttons.
