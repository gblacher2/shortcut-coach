## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2024-05-18 - [Icon-Only Button Accessibility Pattern]
**Learning:** Some icon-only buttons in this app rely solely on `.help` for tooltips but lack explicit `.accessibilityLabel` modifiers, leading to inconsistent VoiceOver support (e.g., Search clear button has it, but Refresh and Mark as Practiced buttons do not).
**Action:** Always ensure both `.help` (for mouse users) and explicit `.accessibilityLabel` modifiers (for VoiceOver support) are present on icon-only components in this codebase.
