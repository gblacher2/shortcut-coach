## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.

## 2024-09-08 - [SwiftUI Accessibility]
**Learning:** Icon-only buttons in SwiftUI using `.help` tooltips do not automatically provide VoiceOver support; they explicitly require an `.accessibilityLabel` to be read by screen readers.
**Action:** Always verify that icon-only buttons include both `.help` (for visual tooltips) and `.accessibilityLabel` (for screen readers), dynamically mirroring text when necessary.
