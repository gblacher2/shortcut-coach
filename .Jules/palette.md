## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2026-08-13 - SwiftUI Icon-Only Button Accessibility
**Learning:** In SwiftUI macOS apps, `.help()` modifiers provide visual tooltips for icon-only buttons, but do not automatically act as accessibility labels for screen readers like VoiceOver.
**Action:** Always pair `.help()` with `.accessibilityLabel()` on icon-only buttons to ensure both mouse and screen reader users have context.
