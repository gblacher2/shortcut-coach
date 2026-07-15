## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2024-10-24 - [SwiftUI Button Accessibility]
**Learning:** In this SwiftUI codebase, icon-only buttons often rely on `.help()` for visual tooltips, but `.help()` alone does not adequately support screen readers (VoiceOver) depending on the context and standard VoiceOver settings.
**Action:** Always ensure both `.help()` (for mouse users) and explicit `.accessibilityLabel()` modifiers (for VoiceOver support) are present on icon-only interactive components.
