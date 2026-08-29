## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2024-05-18 - [Icon Button Accessibility]
**Learning:** In SwiftUI, relying solely on `.help()` for icon-only buttons provides tooltips for mouse users but can lack explicit, dynamic support for VoiceOver.
**Action:** Always pair `.help()` with an explicit `.accessibilityLabel()` on icon-only buttons to guarantee screen reader support.
