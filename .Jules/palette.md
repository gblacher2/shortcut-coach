## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2024-05-18 - [VoiceOver Support for Icon Buttons]
**Learning:** While `.help()` provides visual tooltips on macOS, explicitly setting `.accessibilityLabel()` is the best practice for ensuring reliable VoiceOver announcements for icon-only buttons in SwiftUI.
**Action:** Always pair `.help()` with `.accessibilityLabel()` on icon-only buttons.
