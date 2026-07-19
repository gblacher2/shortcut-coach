## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2026-07-19 - [SwiftUI Button Accessibility]
**Learning:** Icon-only buttons using only `.help` for tooltips are insufficient for robust VoiceOver support in SwiftUI; an explicit `.accessibilityLabel` is required for consistent screen reader experiences.
**Action:** Always pair `.help` modifiers with `.accessibilityLabel` modifiers on icon-only interactive elements in SwiftUI views.
