## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2024-07-18 - [Icon-only Button Accessibility]
**Learning:** Icon-only buttons in this app often use `.help` for visual tooltips but miss `.accessibilityLabel` for screen readers (VoiceOver).
**Action:** Whenever adding or modifying icon-only buttons, ensure both `.help` (for mouse hover) and `.accessibilityLabel` (for VoiceOver) modifiers are present to provide a complete and accessible experience.
