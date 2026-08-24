## 2024-05-18 - [Search Input UX]
**Learning:** Explicit clear buttons in search fields significantly improve navigation for both mouse and screen reader users on macOS.
**Action:** Always include a clear button with an appropriate accessibility label in custom search fields.
## 2026-08-24 - Add accessibility labels to icon-only buttons
**Learning:** In SwiftUI, .help modifiers on icon-only buttons provide tooltips for mouse users but do not automatically act as accessible labels for VoiceOver users.
**Action:** Always explicitly add .accessibilityLabel alongside .help on icon-only buttons to ensure both mouse and screen-reader accessibility.
