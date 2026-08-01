## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2026-08-01 - [Icon-Only Button Accessibility]
**Learning:** Icon-only buttons in this app often have `.help` modifiers for visual tooltips but lack explicit `.accessibilityLabel` modifiers for VoiceOver users. Both must be present to ensure full accessibility for screen readers and mouse users alike.
**Action:** Always ensure any button using an icon image instead of text has an `.accessibilityLabel` that mirrors its intended action or `.help` tooltip.
