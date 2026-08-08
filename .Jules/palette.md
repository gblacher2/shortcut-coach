## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2024-08-08 - Missing Accessibility Labels on Icon-only Buttons
**Learning:** Icon-only buttons in this app frequently use `.help` for visual tooltips but lack explicit `.accessibilityLabel` modifiers, which causes VoiceOver to read them generically (e.g., as just "Button").
**Action:** Always ensure `.accessibilityLabel` is added alongside `.help` on icon-only buttons to support screen reader users.
