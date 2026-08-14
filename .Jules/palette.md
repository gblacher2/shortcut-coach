## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2026-08-14 - [SwiftUI Accessibility Conventions]
**Learning:** In SwiftUI, icon-only buttons often rely on `.help` for visual tooltips, which might act as accessibility hints, but explicitly setting `.accessibilityLabel` is a vital best practice for screen readers like VoiceOver to ensure the control's primary identity/action is read aloud correctly.
**Action:** Always ensure both `.help` (for mouse users) and explicit `.accessibilityLabel` modifiers (for VoiceOver support) are present on icon-only button components.
