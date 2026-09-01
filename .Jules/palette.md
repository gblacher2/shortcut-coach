## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2026-09-01 - [SwiftUI Button Accessibility]
**Learning:** In macOS SwiftUI apps, icon-only buttons with `.help` modifiers provide visual tooltips but may not provide sufficient context for VoiceOver unless accompanied by `.accessibilityLabel`.
**Action:** Always ensure both `.help` and explicit `.accessibilityLabel` modifiers are applied to icon-only buttons to support both mouse and screen reader users.
