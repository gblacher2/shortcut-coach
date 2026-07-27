## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2026-07-27 - [SwiftUI Button Accessibility]
**Learning:** Icon-only buttons with `.help` modifiers in SwiftUI provide visual tooltips but do not automatically announce their purpose to VoiceOver users.
**Action:** Always pair `.help` modifiers with an explicit `.accessibilityLabel` modifier on icon-only buttons to ensure they are accessible to both mouse and screen reader users.
