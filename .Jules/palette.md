## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2024-07-24 - [SwiftUI Accessibility]
**Learning:** Icon-only buttons using `.help` for visual tooltips may not always be announced correctly by VoiceOver unless they have an explicit accessibility label.
**Action:** Always include an explicit `.accessibilityLabel` modifier alongside `.help` for icon-only buttons in SwiftUI to ensure robust screen reader support.
