## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2026-07-22 - [SwiftUI A11y Pattern]\n**Learning:** Icon-only buttons often only use `.help` for tooltips, which misses VoiceOver support. Both modifiers are needed.\n**Action:** Audit icon buttons for both `.help` and `.accessibilityLabel`.
