## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2024-10-24 - [SwiftUI Icon Buttons Accessibility]
**Learning:** Icon-only buttons using `.help` for visual tooltips are a common pattern in this SwiftUI codebase, but they lack VoiceOver support by default, appearing just as "button" to screen readers.
**Action:** When adding `.help` modifiers to icon-only buttons, always ensure an equivalent `.accessibilityLabel` is added immediately alongside it to provide equivalent context for VoiceOver users.
