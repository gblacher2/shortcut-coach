## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2024-09-02 - [Icon-Only Button Accessibility]
**Learning:** In macOS native SwiftUI apps, developers often rely on the `.help()` modifier to provide visual tooltips for icon-only buttons. While this helps mouse users, VoiceOver users require explicit `.accessibilityLabel` modifiers to understand the context and action.
**Action:** Always ensure that icon-only buttons using `.help()` also include a corresponding `.accessibilityLabel` to guarantee full accessibility coverage for screen readers.
