## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2024-05-18 - [Icon-Only Button Accessibility]
**Learning:** Icon-only buttons in this app frequently use `.help` for mouse tooltips but omit `.accessibilityLabel`, breaking the experience for screen reader users.
**Action:** Always ensure both `.help` (for mouse users) and `.accessibilityLabel` (for VoiceOver support) are present on icon-only buttons.
