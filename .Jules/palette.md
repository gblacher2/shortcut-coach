## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2026-08-05 - [SwiftUI Icon-only Button Accessibility]
**Learning:** Icon-only buttons in this codebase frequently use `.help` for visual tooltips but omit `.accessibilityLabel`, leaving VoiceOver users without proper context.
**Action:** Always ensure both `.help` (for mouse users) and explicit `.accessibilityLabel` modifiers (for VoiceOver support) are present on these components.
